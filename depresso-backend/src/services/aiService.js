const axios = require('axios');

// Gemini API Configuration
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const SYSTEM_INSTRUCTION = process.env.AI_SYSTEM_PROMPT || 'You are a compassionate AI companion for a mental wellness app. You provide supportive, empathetic responses to users sharing their thoughts and feelings. This is a safe, therapeutic context for discussing mental health, emotions, and personal challenges. Respond with care, validation, and encouragement.';

/**
 * Generates a response from the Gemini AI model.
 * @param {Array} history - Array of previous messages { sender: 'user'|'assistant', content: string }
 * @returns {Promise<string>} - The AI's response content
 */
exports.generateResponse = async (history) => {
    // Convert history to Gemini format
    const contents = history.map(msg => ({
        role: msg.sender === 'assistant' ? 'model' : 'user',
        parts: [{ text: msg.content }]
    }));

    try {
        const response = await axios.post(
            `${GEMINI_API_URL}?key=${GEMINI_API_KEY}`,
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
                }
            }
        );

        const aiContent = response.data.candidates[0]?.content?.parts[0]?.text?.trim();

        if (!aiContent) {
            throw new Error('Invalid AI response format');
        }

        return aiContent;

    } catch (error) {
        console.error('Gemini API Error:', error.response?.data || error.message);

        // Enhance error with context
        if (error.response && error.response.data) {
            const errorData = error.response.data;
            const enhancedError = new Error('AI Service Error');
            enhancedError.code = errorData.error?.code;
            enhancedError.details = errorData.error?.message || 'Gemini API error';
            enhancedError.isContentFilter = errorData.error?.status === 'INVALID_ARGUMENT';
            throw enhancedError;
        }
        throw error;
    }
};
