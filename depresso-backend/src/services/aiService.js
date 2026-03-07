const axios = require('axios');

// Gemini API Configuration
let currentKeyIndex = 0;
const getApiKeys = () => {
    const rawKeys = process.env.GEMINI_API_KEY || '';
    return rawKeys.split(',').map(k => k.trim()).filter(k => k.length > 0);
};

const getNextApiKey = () => {
    const keys = getApiKeys();
    if (keys.length === 0) return null;
    const key = keys[currentKeyIndex];
    currentKeyIndex = (currentKeyIndex + 1) % keys.length;
    return key;
};

// Available Gemini models in priority order (free tier friendly)
// Using v1beta API which supports system_instruction
// Based on actual API testing - these models work!
const AVAILABLE_MODELS = [
    'gemini-1.5-flash',      // ✅ High free tier limit (15 RPM)
    'gemini-2.5-flash',      // ✅ Tested and working
    'gemini-flash-latest'    // ✅ Tested and working (fallback)
];

let currentModelIndex = 0;

// Log on first use, not module load
let hasLoggedKey = false;
function logKeyStatus() {
    if (!hasLoggedKey) {
        const keys = getApiKeys();
        console.log('AI Service - Keys loaded:', keys.length);
        if (keys.length > 0) {
            console.log('AI Service - First key starts with:', keys[0].substring(0, 15) + '...');
        }
        console.log('AI Service - Available models:', AVAILABLE_MODELS.length);
        hasLoggedKey = true;
    }
}

const SYSTEM_INSTRUCTION = process.env.AI_SYSTEM_PROMPT || 'You are a compassionate AI companion for a mental wellness app. You provide supportive, empathetic responses to users sharing their thoughts and feelings. This is a safe, therapeutic context for discussing mental health, emotions, and personal challenges. Respond with care, validation, and encouragement.';

/**
 * Try to generate a response with the current model, fallback to next model on rate limit
 */
async function tryGenerateWithModel(modelName, contents, apiKey) {
    if (!apiKey) {
        return { success: false, error: 'No API keys configured', isInvalidKey: true };
    }
    
    // Use v1beta API which supports system_instruction
    const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent`;
    
    try {
        const response = await axios.post(
            `${GEMINI_API_URL}?key=${apiKey}`,
            {
                system_instruction: {
                    parts: [{ text: SYSTEM_INSTRUCTION }]
                },
                contents: contents,
                generationConfig: {
                    temperature: 0.7,
                    topK: 40,
                    topP: 0.95,
                    maxOutputTokens: 1024,
                }
            },
            {
                headers: {
                    'Content-Type': 'application/json'
                },
                timeout: 25000 // 25 second timeout per model attempt
            }
        );

        const aiContent = response.data.candidates[0]?.content?.parts[0]?.text?.trim();
        
        if (!aiContent) {
            throw new Error('Invalid AI response format');
        }
        
        return { success: true, content: aiContent, model: modelName };
        
    } catch (error) {
        const errorData = error.response?.data?.error;
        const statusCode = error.response?.status;
        const isTimeout = error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT';
        
        // Check if it's a rate limit error (429 or 503) OR model not found (404)
        const isRateLimit = statusCode === 429 || statusCode === 503 || 
                           errorData?.message?.toLowerCase().includes('rate limit') ||
                           errorData?.message?.toLowerCase().includes('quota');
                           
        const isInvalidKey = statusCode === 400 && (errorData?.message?.toLowerCase().includes('api key') || errorData?.status === 'INVALID_ARGUMENT');
        
        const isModelNotFound = statusCode === 404 || 
                               errorData?.message?.toLowerCase().includes('not found') ||
                               errorData?.message?.toLowerCase().includes('not supported');
        
        return {
            success: false,
            isRateLimit,
            isModelNotFound,
            isTimeout,
            isInvalidKey,
            error: errorData?.message || error.message,
            code: errorData?.code || statusCode
        };
    }
}

/**
 * Generates a response from the Gemini AI model with automatic fallback.
 * @param {Array} history - Array of previous messages { sender: 'user'|'assistant', content: string }
 * @returns {Promise<string>} - The AI's response content
 */
exports.generateResponse = async (history) => {
    logKeyStatus(); // Log key status on first use
    
    // Convert history to Gemini format
    const contents = history.map(msg => ({
        role: msg.sender === 'assistant' ? 'model' : 'user',
        parts: [{ text: msg.content }]
    }));

    let lastError = null;
    let attemptedModels = [];
    const keys = getApiKeys();
    const maxAttempts = Math.max(AVAILABLE_MODELS.length * keys.length, 1);
    
    // Try combinations of keys and models
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
        const apiKey = getNextApiKey();
        const modelName = AVAILABLE_MODELS[currentModelIndex];
        attemptedModels.push(`${modelName} (Key ${currentKeyIndex})`);
        
        console.log(`Attempting with model: ${modelName} and key index: ${currentKeyIndex === 0 ? keys.length - 1 : currentKeyIndex - 1}`);
        
        const result = await tryGenerateWithModel(modelName, contents, apiKey);
        
        if (result.success) {
            console.log(`✓ Success with model: ${modelName}`);
            return result.content;
        }
        
        lastError = result;
        
        if (result.isRateLimit) {
            console.log(`⏱️  Rate limit hit on ${modelName}, trying next model/key...`);
            currentModelIndex = (currentModelIndex + 1) % AVAILABLE_MODELS.length;
            await new Promise(resolve => setTimeout(resolve, 1000));
        } else if (result.isInvalidKey) {
            console.log(`❌ API Key is invalid or expired, trying next key...`);
        } else if (result.isModelNotFound) {
            console.log(`❌ Model ${modelName} not available, trying next model...`);
            currentModelIndex = (currentModelIndex + 1) % AVAILABLE_MODELS.length;
        } else if (result.isTimeout) {
            console.log(`⏳ Timeout on ${modelName}, trying next model/key...`);
        } else {
            console.error(`Non-recoverable error with ${modelName}:`, result.error);
            break;
        }
    }
    
    // All models/keys failed
    console.error('All attempts failed. Tried combinations:', attemptedModels);
    
    const enhancedError = new Error('AI Service Error');
    enhancedError.code = lastError?.code || 500;
    enhancedError.details = lastError?.error || 'All AI models/keys unavailable';
    enhancedError.attemptedModels = attemptedModels;
    throw enhancedError;
};
