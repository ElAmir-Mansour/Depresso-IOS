const axios = require('axios');

// Gemini API Configuration
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

// Available Gemini models in priority order (free tier friendly)
// Using exact model names from Google AI Studio
const AVAILABLE_MODELS = [
    'gemini-2.0-flash-exp',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash-002',
    'gemini-1.5-flash-8b-latest',
    'gemini-pro'
];

let currentModelIndex = 0;

console.log('AI Service - Has API Key:', !!GEMINI_API_KEY);
console.log('AI Service - Key starts with:', GEMINI_API_KEY ? GEMINI_API_KEY.substring(0, 15) + '...' : 'MISSING');
console.log('AI Service - Available models:', AVAILABLE_MODELS.length);

const SYSTEM_INSTRUCTION = process.env.AI_SYSTEM_PROMPT || 'You are a compassionate AI companion for a mental wellness app. You provide supportive, empathetic responses to users sharing their thoughts and feelings. This is a safe, therapeutic context for discussing mental health, emotions, and personal challenges. Respond with care, validation, and encouragement.';

/**
 * Try to generate a response with the current model, fallback to next model on rate limit
 */
async function tryGenerateWithModel(modelName, contents) {
    // Use v1 API instead of v1beta for better model support
    const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1/models/${modelName}:generateContent`;
    
    try {
        // v1 API doesn't support system_instruction, so prepend it to first message
        const contentsWithSystem = [
            {
                role: 'user',
                parts: [{ text: SYSTEM_INSTRUCTION }]
            },
            {
                role: 'model',
                parts: [{ text: 'I understand. I will provide compassionate, supportive responses.' }]
            },
            ...contents
        ];
        
        const response = await axios.post(
            `${GEMINI_API_URL}?key=${GEMINI_API_KEY}`,
            {
                contents: contentsWithSystem,
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
        
        const isModelNotFound = statusCode === 404 || 
                               errorData?.message?.toLowerCase().includes('not found') ||
                               errorData?.message?.toLowerCase().includes('not supported');
        
        return {
            success: false,
            isRateLimit,
            isModelNotFound,
            isTimeout,
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
    // Convert history to Gemini format
    const contents = history.map(msg => ({
        role: msg.sender === 'assistant' ? 'model' : 'user',
        parts: [{ text: msg.content }]
    }));

    let lastError = null;
    let attemptedModels = [];
    
    // Try all available models
    for (let i = 0; i < AVAILABLE_MODELS.length; i++) {
        const modelIndex = (currentModelIndex + i) % AVAILABLE_MODELS.length;
        const modelName = AVAILABLE_MODELS[modelIndex];
        attemptedModels.push(modelName);
        
        console.log(`Attempting with model: ${modelName}`);
        
        const result = await tryGenerateWithModel(modelName, contents);
        
        if (result.success) {
            // Success! Update current model index for next time
            currentModelIndex = modelIndex;
            console.log(`✓ Success with model: ${modelName}`);
            return result.content;
        }
        
        lastError = result;
        
        // If rate limit, model not found, or timeout - try next model
        if (!result.isRateLimit && !result.isModelNotFound && !result.isTimeout) {
            console.error(`Non-recoverable error with ${modelName}:`, result.error);
            break;
        }
        
        if (result.isRateLimit) {
            console.log(`Rate limit hit on ${modelName}, trying next model...`);
        } else if (result.isModelNotFound) {
            console.log(`Model ${modelName} not available, trying next model...`);
        } else if (result.isTimeout) {
            console.log(`Timeout on ${modelName}, trying next model...`);
        }
    }
    
    // All models failed
    console.error('All models failed. Attempted:', attemptedModels);
    
    const enhancedError = new Error('AI Service Error');
    enhancedError.code = lastError?.code || 500;
    enhancedError.details = lastError?.error || 'All AI models unavailable';
    enhancedError.attemptedModels = attemptedModels;
    throw enhancedError;
};
