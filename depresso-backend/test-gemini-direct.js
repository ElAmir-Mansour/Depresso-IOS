require('dotenv').config();
const axios = require('axios');

const keys = (process.env.GEMINI_API_KEY || '').split(',').map(k => k.trim()).filter(k => k);
const models = ['gemini-1.5-flash', 'gemini-2.0-flash-exp', 'gemini-1.5-pro'];

async function testKeyModel(key, model) {
    try {
        const response = await axios.post(
            `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`,
            {
                contents: [{
                    parts: [{ text: 'Hi' }]
                }]
            },
            { timeout: 5000 }
        );
        return { success: true, model };
    } catch (error) {
        const msg = error.response?.data?.error?.message || error.message;
        return { success: false, model, error: msg };
    }
}

(async () => {
    console.log(`Testing ${keys.length} keys x ${models.length} models...\n`);
    
    for (let i = 0; i < keys.length; i++) {
        console.log(`\nKey ${i + 1}:`);
        for (const model of models) {
            const result = await testKeyModel(keys[i], model);
            if (result.success) {
                console.log(`  ✅ ${model} WORKS`);
            } else {
                console.log(`  ❌ ${model} - ${result.error.substring(0, 100)}`);
            }
        }
    }
    process.exit(0);
})();
