#!/bin/bash

API_KEY="AIzaSyDI1t7XsBn2wBENMDfbi6TWkeUgdlExugE"

# List of models to test
MODELS=(
    "gemini-1.5-flash"
    "gemini-1.5-flash-8b"
    "gemini-1.5-pro"
    "gemini-pro"
    "gemini-1.0-pro"
)

echo "Testing Gemini models with v1beta API..."
echo "=========================================="

for model in "${MODELS[@]}"; do
    echo ""
    echo "Testing: $model"
    echo "---"
    
    response=$(curl -s -m 10 -X POST \
        "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "contents": [{
                "role": "user",
                "parts": [{"text": "Say hello in 3 words"}]
            }]
        }' 2>&1)
    
    if echo "$response" | grep -q '"text"'; then
        echo "✅ SUCCESS - Response received"
        echo "$response" | grep -o '"text":"[^"]*"' | head -1
    elif echo "$response" | grep -q '"error"'; then
        error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | head -1)
        echo "❌ ERROR - $error_msg"
    else
        echo "⏱️  TIMEOUT or UNKNOWN"
    fi
done

echo ""
echo "=========================================="
echo "Test complete!"
