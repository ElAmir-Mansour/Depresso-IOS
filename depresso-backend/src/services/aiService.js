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
// Updated March 7, 2026 - Using latest available models
// Best options based on your rate limits:
// - Gemini 3.1 Flash Lite: 15 RPM, 250K TPM, 500 RPD (BEST for high volume)
// - Gemini 2.5 Flash Lite: 10 RPM, 250K TPM, 20 RPD
// - Gemini 3 Flash: 5 RPM, 250K TPM, 20 RPD
// - Gemini 2.5 Flash: 5 RPM, 250K TPM, 20 RPD (currently being used)
const AVAILABLE_MODELS = [
    'gemini-3.1-flash-lite',  // ✅ BEST: 15 RPM, 500 RPD
    'gemini-2.5-flash-lite',  // ✅ Good: 10 RPM, 20 RPD
    'gemini-3-flash',         // ✅ Backup: 5 RPM, 20 RPD
    'gemini-2.5-flash'        // ✅ Fallback: 5 RPM, 20 RPD (currently used)
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
    
    // Try v1 API first (more stable), fallback to v1beta
    const API_VERSIONS = ['v1', 'v1beta'];
    
    for (const apiVersion of API_VERSIONS) {
        const GEMINI_API_URL = `https://generativelanguage.googleapis.com/${apiVersion}/models/${modelName}:generateContent`;
        
        try {
            const requestBody = {
                contents: contents,
                generationConfig: {
                    temperature: 0.7,
                    topK: 40,
                    topP: 0.95,
                    maxOutputTokens: 1024,
                }
            };
            
            // Add system_instruction only for v1beta (v1 doesn't support it)
            if (apiVersion === 'v1beta') {
                requestBody.system_instruction = {
                    parts: [{ text: SYSTEM_INSTRUCTION }]
                };
            }
            
            const response = await axios.post(
                `${GEMINI_API_URL}?key=${apiKey}`,
                requestBody,
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
            
            return { success: true, content: aiContent, model: modelName, apiVersion };
            
        } catch (error) {
            const errorData = error.response?.data?.error;
            const statusCode = error.response?.status;
            
            // If this API version failed, try next one
            if (apiVersion === 'v1' && API_VERSIONS.length > 1) {
                continue;
            }
            
            // Both versions failed, return error
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
    
    // If we get here, both API versions failed
    return {
        success: false,
        error: 'All API versions failed',
        isModelNotFound: true
    };
}

/**
 * Generates a response from the Gemini AI model with automatic fallback.
 * @param {Array} history - Array of previous messages { sender: 'user'|'assistant', content: string }
 * @returns {Promise<string>} - The AI's response content
 */
exports.generateResponse = async (history) => {
    logKeyStatus(); // Log key status on first use
    
    // FALLBACK MODE: Use canned responses if keys are expired
    const USE_FALLBACK = process.env.USE_AI_FALLBACK === 'true';
    const keys = getApiKeys();
    
    if (USE_FALLBACK || keys.length === 0) {
        console.log('⚠️ Using fallback responses (no valid API keys)');
        
        const compassionateResponses = [
            "I hear you. It's completely valid to feel this way. Would you like to tell me more about what's on your mind?",
            "Thank you for sharing that with me. Your feelings are important and I'm here to listen. How are you taking care of yourself today?",
            "That sounds challenging. Remember, it's okay to feel overwhelmed sometimes. What's one small thing that might help you feel a bit better right now?",
            "I appreciate you opening up to me. You're doing great by journaling and reflecting on your thoughts. Every entry is a step forward.",
            "It takes courage to acknowledge these feelings. What's one positive thing, even if small, from your day that you can recognize?",
            "I'm glad you're here and sharing with me. Your journey matters. What would make today feel a little easier?",
            "Those feelings are real and they matter. Sometimes just expressing them helps. How long have you been feeling this way?",
            "Thank you for trusting me with these thoughts. You're not alone in this. What support do you have around you?",
            "I can sense this is weighing on you. It's okay to not be okay. What's one thing you're looking forward to?",
            "Your awareness of these patterns shows real growth. Keep being kind to yourself. What do you need most right now?"
        ];
        
        // Pick response based on conversation length (feels more natural)
        const index = history.length % compassionateResponses.length;
        return compassionateResponses[index];
    }
    
    // Convert history to Gemini format
    const contents = history.map(msg => ({
        role: msg.sender === 'assistant' ? 'model' : 'user',
        parts: [{ text: msg.content }]
    }));

    let lastError = null;
    let attemptedModels = [];
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

/**
 * Generates vector embeddings for a given text using the Gemini embedding model.
 * @param {string} text - The text to embed
 * @returns {Promise<Array<number>>} - A 768-dimensional float array
 */
exports.generateEmbedding = async (text) => {
    if (!text || text.trim() === '') {
        return null; // Don't embed empty strings
    }
    
    const USE_FALLBACK = process.env.USE_AI_FALLBACK === 'true';
    if (USE_FALLBACK) {
        // Return a zero-vector if in fallback mode to avoid breaking the DB insert
        return new Array(768).fill(0);
    }
    
    const apiKey = getApiKeys()[0] || process.env.GEMINI_API_KEY;
    if (!apiKey) {
        throw new Error('No API keys configured for embeddings');
    }
    
    const EMBEDDING_MODEL = 'text-embedding-004';
    const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${EMBEDDING_MODEL}:embedContent`;
    
    try {
        const response = await axios.post(
            `${GEMINI_API_URL}?key=${apiKey}`,
            {
                model: `models/${EMBEDDING_MODEL}`,
                content: {
                    parts: [{ text: text }]
                }
            },
            {
                headers: {
                    'Content-Type': 'application/json'
                },
                timeout: 10000 // 10 second timeout for embeddings
            }
        );

        const embedding = response.data.embedding?.values;
        
        if (!embedding || !Array.isArray(embedding)) {
            throw new Error('Invalid embedding response format');
        }
        
        return embedding;
        
    } catch (error) {
        console.error('Embedding Generation Error:', error.response?.data?.error?.message || error.message);
        throw error;
    }
};
