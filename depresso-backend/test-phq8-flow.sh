#!/bin/bash

# Test PHQ-8 submission flow
set -e

BASE_URL="http://192.168.1.11:3000/api/v1"

echo "🧪 Testing PHQ-8 Submission Flow"
echo "================================="
echo ""

# Step 1: Register a new user
echo "Step 1: Registering new user..."
USER_RESPONSE=$(curl -s -X POST "${BASE_URL}/users/register")
USER_ID=$(echo $USER_RESPONSE | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)

if [ -z "$USER_ID" ]; then
    echo "❌ Failed to register user"
    echo "Response: $USER_RESPONSE"
    exit 1
fi

echo "✅ User registered: $USER_ID"
echo ""

# Step 2: Submit PHQ-8 assessment
echo "Step 2: Submitting PHQ-8 assessment..."
ASSESSMENT_DATA='{
    "userId": "'$USER_ID'",
    "assessmentType": "PHQ-8",
    "score": 15,
    "answers": [2, 2, 2, 2, 2, 2, 2, 1]
}'

ASSESSMENT_RESPONSE=$(curl -s -X POST "${BASE_URL}/assessments" \
    -H "Content-Type: application/json" \
    -d "$ASSESSMENT_DATA")

echo "$ASSESSMENT_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$ASSESSMENT_RESPONSE"

if echo "$ASSESSMENT_RESPONSE" | grep -q "error"; then
    echo "❌ Failed to submit assessment"
    exit 1
fi

echo ""
echo "✅ Assessment submitted successfully!"
echo ""

# Step 3: Get streak
echo "Step 3: Getting user streak..."
STREAK_RESPONSE=$(curl -s "${BASE_URL}/assessments/streak?userId=${USER_ID}")
echo "$STREAK_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STREAK_RESPONSE"
echo ""

echo "✅ All tests passed!"
echo ""
echo "Summary:"
echo "--------"
echo "User ID: $USER_ID"
echo "Check backend logs at: /tmp/server.log"
