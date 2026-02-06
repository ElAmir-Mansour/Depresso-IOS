#!/bin/bash

echo "🧪 Testing PHQ-8 Assessment Flow"
echo "================================"

# Step 1: Register user
echo -e "\n1️⃣  Registering new user..."
RESPONSE=$(curl -s -X POST http://192.168.1.11:3000/api/v1/users/register \
  -H "Content-Type: application/json")
echo "   Response: $RESPONSE"

USER_ID=$(echo $RESPONSE | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "   User ID: $USER_ID"

if [ -z "$USER_ID" ]; then
  echo "   ❌ Failed to register user"
  exit 1
fi

# Step 2: Submit assessment
echo -e "\n2️⃣  Submitting PHQ-8 assessment..."
ASSESSMENT_RESPONSE=$(curl -s -X POST http://192.168.1.11:3000/api/v1/assessments \
  -H "Content-Type: application/json" \
  -d "{\"userId\":\"$USER_ID\",\"assessmentType\":\"PHQ-8\",\"score\":15,\"answers\":[2,2,2,2,2,2,2,1]}")
echo "   Response: $ASSESSMENT_RESPONSE"

ASSESSMENT_ID=$(echo $ASSESSMENT_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)
echo "   Assessment ID: $ASSESSMENT_ID"

if [ -z "$ASSESSMENT_ID" ]; then
  echo "   ❌ Failed to submit assessment"
  exit 1
fi

# Step 3: Get streak
echo -e "\n3️⃣  Getting streak..."
STREAK_RESPONSE=$(curl -s "http://192.168.1.11:3000/api/v1/assessments/streak?userId=$USER_ID")
echo "   Response: $STREAK_RESPONSE"

echo -e "\n✅ All tests passed!"
