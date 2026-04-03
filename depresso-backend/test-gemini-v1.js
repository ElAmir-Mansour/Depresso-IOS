require('dotenv').config();
const axios = require('axios');

const keys = (process.env.GEMINI_API_KEY || '').split(',').map(k => k.trim()).filter(k => k);
const models = ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'];

async function testKeyModel(key, model, apiVersion) {
    try {
        const response = await axios.post(
            `https://generativelanguage.googleapis.com/${apiVersion}/models/${model}:generateContent?key=${key}`,
            {
                contents: [{
                    parts: [{ text: 'Hi' }]
                }]
            },
            { timeout: 5000 }
        );
        return { success: true, model, apiVersion };
    } catch (error) {
        const msg = error.response?.data?.error?.message || error.message;
        return { success: false, model, apiVersion, error: msg.substring(0, 80) };
    }
}

(async () => {
    console.log(`Testing ${keys.length} keys x ${models.length} models x 2 API versions...\n`);
    
    for (let i = 0; i < keys.length; i++) {
        console.log(`\n🔑 Key ${i + 1}:`);
        
        // Test v1
        for (const model of models) {
            const result = await testKeyModel(keys[i], model, 'v1');
            if (result.success) {
                console.log(`  ✅ v1/${model} WORKS`);
                process.exit(0); // Exit on first working combo
            }
        }
        
        // Test v1beta
        for (const model of models) {
            const result = await testKeyModel(keys[i], model, 'v1beta');
            if (result.success) {
                console.log(`  ✅ v1beta/${model} WORKS`);
                process.exit(0);
            }
        }
    }
    
    console.log('\n❌ ALL KEYS EXPIRED - Need new API keys from https://aistudio.google.com/apikey');
    process.exit(1);
})();
