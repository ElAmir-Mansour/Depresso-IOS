const axios = require('axios');

// Configuration
const QWEN_API_URL = 'https://api-ap-southeast-1.modelarts-maas.com/v1/chat/completions';
const MODEL_NAME = process.env.QWEN_MODEL_NAME || 'qwen3-32b';

const SYSTEM_PROMPT = {
    role: 'system',
    content: process.env.AI_SYSTEM_PROMPT || 'You are a compassionate AI companion for a mental wellness app. You provide supportive, empathetic responses to users sharing their thoughts and feelings. This is a safe, therapeutic context for discussing mental health, emotions, and personal challenges. Respond with care, validation, and encouragement.'
};

/**
 * Generates a response from the Qwen AI model.
 * @param {Array} history - Array of previous messages { sender: 'user'|'ai', content: string }
 * @returns {Promise<string>} - The AI's response content
 */
exports.generateResponse = async (history) => {
    // Map roles: 'user' -> 'user', 'ai' -> 'assistant'
    const messages = [
        SYSTEM_PROMPT,
        ...history.map(msg => ({
            role: msg.sender === 'ai' ? 'assistant' : 'user',
            content: msg.content
        }))
    ];

    try {
        const qwenResponse = await axios.post(QWEN_API_URL, {
            model: MODEL_NAME,
            messages: messages
        }, {
            headers: {
                'Authorization': `Bearer ${process.env.QWEN_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        const aiContent = qwenResponse.data.choices[0]?.message?.content.trim();

        if (!aiContent) {
            throw new Error('Invalid AI response format');
        }

        return aiContent;

    } catch (error) {
        // Enhance error with context
        if (error.response && error.response.data) {
            const errorData = error.response.data;
            const enhancedError = new Error('AI Service Error');
            enhancedError.code = errorData.error_code;
            enhancedError.details = errorData.error_msg;
            enhancedError.isContentFilter = errorData.error_code === 'ModelArts.81011';
            throw enhancedError;
        }
        throw error;
    }
};
