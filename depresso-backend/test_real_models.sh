#!/bin/bash

API_KEY="AIzaSyDI1t7XsBn2wBENMDfbi6TWkeUgdlExugE"

# Real available models from ListModels
MODELS=(
    "gemini-2.5-flash"
    "gemini-2.0-flash"
    "gemini-2.0-flash-lite"
    "gemini-flash-latest"
    "gemini-pro-latest"
)

echo "Testing REAL Gemini models..."
echo "=============================="

for model in "${MODELS[@]}"; do
    echo ""
    echo "Testing: $model"
    echo "---"
    
    response=$(curl -s -m 15 -X POST \
        "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "contents": [{
                "role": "user",
                "parts": [{"text": "Say hello in 3 words"}]
            }]
        }' 2>&1)
    
    if echo "$response" | grep -q '"text"'; then
        echo "✅ SUCCESS"
        echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['candidates'][0]['content']['parts'][0]['text'])"
    elif echo "$response" | grep -q '"error"'; then
        error_code=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['error']['code'])" 2>/dev/null || echo "unknown")
        error_msg=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['error']['message'])" 2>/dev/null || echo "$response")
        echo "❌ ERROR ($error_code): $error_msg"
    else
        echo "⏱️  TIMEOUT"
    fi
done

echo ""
echo "=============================="
