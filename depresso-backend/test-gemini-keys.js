require('dotenv').config();
const axios = require('axios');

const keys = process.env.GEMINI_API_KEY.split(',');

async function testKey(key, index) {
    try {
        const response = await axios.post(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${key.trim()}`,
            {
                contents: [{
                    parts: [{ text: 'Hello' }]
                }]
            },
            { timeout: 5000 }
        );
        console.log(`✅ Key ${index + 1} WORKS`);
        return true;
    } catch (error) {
        console.log(`❌ Key ${index + 1} EXPIRED: ${error.response?.data?.error?.message || error.message}`);
        return false;
    }
}

(async () => {
    console.log('Testing', keys.length, 'API keys...\n');
    for (let i = 0; i < keys.length; i++) {
        await testKey(keys[i], i);
    }
    process.exit(0);
})();
