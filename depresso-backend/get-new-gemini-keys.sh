#!/bin/bash

# 🔑 Get New Gemini API Keys Script
# This helps you quickly update your Gemini API keys

echo "🔑 Gemini API Key Update Script"
echo "================================"
echo ""
echo "📋 Instructions:"
echo "1. Open: https://aistudio.google.com/apikey"
echo "2. Sign in with your Google account"
echo "3. Create 3 new API keys (click 'Create API Key' 3 times)"
echo "4. Come back here and paste them"
echo ""
echo "⚠️  Note: You're currently on project 'AICOURSE'"
echo ""
echo "Best models for your app (in order):"
echo "  1. gemini-3.1-flash-lite (15 RPM, 500 RPD) ⭐ BEST"
echo "  2. gemini-2.5-flash-lite (10 RPM, 20 RPD)"
echo "  3. gemini-3-flash (5 RPM, 20 RPD)"
echo ""

# Get keys from user
read -p "Enter API Key 1: " KEY1
read -p "Enter API Key 2: " KEY2
read -p "Enter API Key 3: " KEY3

# Validate keys are not empty
if [ -z "$KEY1" ] || [ -z "$KEY2" ] || [ -z "$KEY3" ]; then
    echo "❌ Error: All 3 keys are required"
    exit 1
fi

# Backup old .env
if [ -f .env ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backed up old .env"
fi

# Update .env file
if grep -q "GEMINI_API_KEY" .env 2>/dev/null; then
    # Replace existing line
    sed -i.bak "s|GEMINI_API_KEY=.*|GEMINI_API_KEY=\"$KEY1,$KEY2,$KEY3\"|" .env
    rm .env.bak
    echo "✅ Updated existing GEMINI_API_KEY in .env"
else
    # Add new line
    echo "" >> .env
    echo "GEMINI_API_KEY=\"$KEY1,$KEY2,$KEY3\"" >> .env
    echo "✅ Added GEMINI_API_KEY to .env"
fi

echo ""
echo "🧪 Testing keys with best models..."
echo ""

# Test the keys
node -e "
require('dotenv').config();
const axios = require('axios');

const keys = process.env.GEMINI_API_KEY.split(',').map(k => k.trim());
const models = ['gemini-3.1-flash-lite', 'gemini-2.5-flash-lite', 'gemini-3-flash', 'gemini-2.5-flash'];

async function testKey(key, index) {
    console.log(\`\nTesting Key \${index + 1}...\`);
    let working = false;
    
    for (const model of models) {
        try {
            const response = await axios.post(
                \`https://generativelanguage.googleapis.com/v1/models/\${model}:generateContent?key=\${key}\`,
                {
                    contents: [{
                        parts: [{ text: 'Hi' }]
                    }]
                },
                { timeout: 5000 }
            );
            console.log(\`  ✅ \${model} WORKS\`);
            working = true;
            break;
        } catch (error) {
            const msg = error.response?.data?.error?.message || error.message;
            if (!msg.includes('not found')) {
                console.log(\`  ❌ \${model}: \${msg.substring(0, 60)}\`);
            }
        }
    }
    
    return working;
}

(async () => {
    let workingCount = 0;
    for (let i = 0; i < keys.length; i++) {
        const works = await testKey(keys[i], i);
        if (works) workingCount++;
    }
    
    console.log(\`\n\${workingCount > 0 ? '✅' : '❌'} \${workingCount}/\${keys.length} keys are working\n\`);
    
    if (workingCount > 0) {
        console.log('🎉 SUCCESS! Your keys are working.');
        console.log('');
        console.log('Next steps:');
        console.log('  1. Restart your backend: npm start');
        console.log('  2. Update Vercel: vercel env rm GEMINI_API_KEY production && vercel env add GEMINI_API_KEY production');
        console.log('  3. Redeploy: vercel --prod');
    } else {
        console.log('❌ FAILED: No keys are working. Check:');
        console.log('  - Keys are correct and complete');
        console.log('  - API is enabled in Google Cloud Console');
        console.log('  - Billing is set up (if required)');
    }
    
    process.exit(workingCount > 0 ? 0 : 1);
})();
"

echo ""
echo "✅ Done!"
