#!/bin/bash
echo "Testing Gemini API directly..."
curl -s -m 15 -X POST \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyDHdR8B1RIOzzwYTXuJ6MUTfL8-iaLWWFg" \
    -H "Content-Type: application/json" \
    -d '{
        "contents": [{
            "role": "user",
            "parts": [{"text": "Say hello in 3 words"}]
        }]
    }' 2>&1 | python3 -c "import sys, json; data=json.load(sys.stdin); print('✅ AI Working:', data.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].get('text', 'ERROR'))" 2>&1 || echo "❌ AI Failed"
