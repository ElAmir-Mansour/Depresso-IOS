const { GoogleGenAI } = require('@google/genai');

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
const AVAILABLE_MODELS = [
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash-lite',
    'gemini-3-flash',
    'gemini-2.5-flash'
];

let currentModelIndex = 0;

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

const SYSTEM_INSTRUCTION = process.env.AI_SYSTEM_PROMPT || 'You are a compassionate AI companion for a mental wellness app. You provide supportive, empathetic responses to users sharing their thoughts and feelings. This is a safe, therapeutic context for discussing mental health, emotions, and personal challenges. Respond with care, validation, and encouragement. If you offer therapeutic advice or grounding exercises, ALWAYS search the clinical knowledge base (your File Search tool) and ground your advice in established Cognitive Behavioral Therapy (CBT) practices. CRITICAL RULE FOR CITATIONS: Do NOT use raw numerical brackets like [1.3] or [2] under any circumstances. Instead, seamlessly integrate the citation into your conversational sentences naturally, for example: "According to standard CBT practices..." or "As noted in the Therapist\\'s Guide...". Your response must look completely natural and conversational to the user without any academic formatting marks.';

async function tryGenerateWithModel(modelName, contents, apiKey, fileSearchStoreName = null) {
    if (!apiKey) {
        return { success: false, error: 'No API keys configured', isInvalidKey: true };
    }
    
    try {
        const ai = new GoogleGenAI({ apiKey: apiKey });
        
        const config = {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024,
            systemInstruction: SYSTEM_INSTRUCTION
        };

        // If a file search store is provided, attach the tool
        if (fileSearchStoreName) {
            config.tools = [{
                fileSearch: {
                    fileSearchStoreNames: [fileSearchStoreName]
                }
            }];
        }
        
        const response = await ai.models.generateContent({
            model: modelName,
            contents: contents,
            config: config
        });
        
        const aiContent = response.text;
        
        if (!aiContent) {
            throw new Error('Invalid AI response format');
        }
        
        return { success: true, content: aiContent, model: modelName };
        
    } catch (error) {
        const statusCode = error.status || error.response?.status;
        const errorMessage = error.message?.toLowerCase() || '';
        
        const isTimeout = error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT' || errorMessage.includes('timeout');
        
        const isRateLimit = statusCode === 429 || statusCode === 503 || 
                           errorMessage.includes('rate limit') ||
                           errorMessage.includes('quota');
                           
        const isInvalidKey = statusCode === 400 && (errorMessage.includes('api key') || error.statusText === 'INVALID_ARGUMENT');
        
        const isModelNotFound = statusCode === 404 || 
                               errorMessage.includes('not found') ||
                               errorMessage.includes('not supported');
        
        return {
            success: false,
            isRateLimit,
            isModelNotFound,
            isTimeout,
            isInvalidKey,
            error: error.message,
            code: statusCode
        };
    }
}

/**
 * Generates a response from the Gemini AI model with automatic fallback.
 * @param {Array} history - Array of previous messages { sender: 'user'|'assistant', content: string }
 * @param {string} fileSearchStoreName - Optional ID of a FileSearchStore to use for RAG
 * @returns {Promise<string>} - The AI's response content
 */
exports.generateResponse = async (history, fileSearchStoreName = null) => {
    logKeyStatus();
    
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
    
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
        const apiKey = getNextApiKey();
        const modelName = AVAILABLE_MODELS[currentModelIndex];
        attemptedModels.push(`${modelName} (Key ${currentKeyIndex})`);
        
        console.log(`Attempting with model: ${modelName} and key index: ${currentKeyIndex === 0 ? keys.length - 1 : currentKeyIndex - 1}`);
        
        const result = await tryGenerateWithModel(modelName, contents, apiKey, fileSearchStoreName);
        
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
    
    console.error('All attempts failed. Tried combinations:', attemptedModels);
    
    const enhancedError = new Error('AI Service Error');
    enhancedError.code = lastError?.code || 500;
    enhancedError.details = lastError?.error || 'All AI models/keys unavailable';
    enhancedError.attemptedModels = attemptedModels;
    throw enhancedError;
};

exports.generateEmbedding = async (text) => {
    if (!text || text.trim() === '') {
        return null;
    }
    
    const USE_FALLBACK = process.env.USE_AI_FALLBACK === 'true';
    if (USE_FALLBACK) {
        return new Array(768).fill(0);
    }
    
    const apiKey = getApiKeys()[0] || process.env.GEMINI_API_KEY;
    if (!apiKey) {
        throw new Error('No API keys configured for embeddings');
    }
    
    const EMBEDDING_MODEL = 'text-embedding-004';
    
    try {
        const ai = new GoogleGenAI({ apiKey: apiKey });
        
        const response = await ai.models.embedContent({
            model: EMBEDDING_MODEL,
            contents: text
        });

        const embedding = response.embeddings?.[0]?.values;
        
        if (!embedding || !Array.isArray(embedding)) {
            throw new Error('Invalid embedding response format');
        }
        
        return embedding;
        
    } catch (error) {
        console.error('Embedding Generation Error:', error.message);
        throw error;
    }
};