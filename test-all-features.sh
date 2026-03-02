#!/bin/bash

# Test all Depresso app features
# Base URL - Update this to your deployment URL
BASE_URL="https://depresso-ios.vercel.app/api/v1"

echo "🧪 TESTING ALL DEPRESSO FEATURES"
echo "================================="
echo "Base URL: $BASE_URL"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

test_endpoint() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4
    
    echo -n "Testing $name... "
    
    if [ "$method" = "GET" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL$endpoint")
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X "$method" "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        echo -e "${GREEN}✅ PASS${NC} (HTTP $HTTP_CODE)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC} (HTTP $HTTP_CODE)"
        echo "   Response: $BODY"
        ((FAILED++))
        return 1
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 1. USER REGISTRATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -X POST "$BASE_URL/users/register" -H "Content-Type: application/json")
USER_ID=$(echo $RESPONSE | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "Registered User ID: $USER_ID"

if [ -z "$USER_ID" ]; then
    echo -e "${RED}❌ Failed to register user${NC}"
    exit 1
else
    echo -e "${GREEN}✅ User registered${NC}"
    ((PASSED++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 2. ASSESSMENTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Submit PHQ-8 assessment
test_endpoint "Submit PHQ-8" "POST" "/assessments" \
    "{\"userId\":\"$USER_ID\",\"assessmentType\":\"PHQ-8\",\"score\":15,\"answers\":[2,2,2,2,2,2,2,1]}"

# Submit GAD-7 assessment
test_endpoint "Submit GAD-7" "POST" "/assessments" \
    "{\"userId\":\"$USER_ID\",\"assessmentType\":\"GAD-7\",\"score\":12,\"answers\":[2,2,1,2,1,2,2]}"

# Get streak
test_endpoint "Get Streak" "GET" "/assessments/streak?userId=$USER_ID" ""

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📖 3. JOURNAL ENTRIES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create journal entry
JOURNAL_RESPONSE=$(curl -s -X POST "$BASE_URL/journal/entries" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"title\":\"Test Entry\",\"content\":\"Testing journal functionality\"}")

ENTRY_ID=$(echo $JOURNAL_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)
echo "Created Entry ID: $ENTRY_ID"

if [ -z "$ENTRY_ID" ]; then
    echo -e "${RED}❌ Failed to create journal entry${NC}"
    ((FAILED++))
else
    echo -e "${GREEN}✅ Journal entry created${NC}"
    ((PASSED++))
fi

# Add message to entry (AI response)
test_endpoint "Add AI Message" "POST" "/journal/entries/$ENTRY_ID/messages" \
    "{\"userId\":\"$USER_ID\",\"sender\":\"user\",\"content\":\"I'm feeling anxious today\"}"

# Get messages
test_endpoint "Get Messages" "GET" "/journal/entries/$ENTRY_ID/messages" ""

# Get user entries
test_endpoint "Get User Entries" "GET" "/journal/entries?userId=$USER_ID" ""

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏘️  4. COMMUNITY POSTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create post
POST_RESPONSE=$(curl -s -X POST "$BASE_URL/community/posts" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"title\":\"Test Post\",\"content\":\"Testing community feature\"}")

POST_ID=$(echo $POST_RESPONSE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Created Post ID: $POST_ID"

if [ -z "$POST_ID" ]; then
    echo -e "${RED}❌ Failed to create post${NC}"
    ((FAILED++))
else
    echo -e "${GREEN}✅ Community post created${NC}"
    ((PASSED++))
fi

# Get all posts
test_endpoint "Get All Posts" "GET" "/community/posts" ""

# Like post
test_endpoint "Like Post" "POST" "/community/posts/$POST_ID/like" \
    "{\"userId\":\"$USER_ID\"}"

# Get liked posts
test_endpoint "Get Liked Posts" "GET" "/community/posts/liked?userId=$USER_ID" ""

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 5. METRICS SUBMISSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_endpoint "Submit Metrics" "POST" "/metrics/submit" \
    "{\"userId\":\"$USER_ID\",\"dailyMetrics\":{\"steps\":8500,\"activeEnergy\":450,\"heartRate\":72},\"typingMetrics\":{\"wordsPerMinute\":45,\"totalEditCount\":12},\"motionMetrics\":{\"avgAccelerationX\":0.1,\"avgAccelerationY\":0.2,\"avgAccelerationZ\":0.3}}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔬 6. RESEARCH DATA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Submit research entry
test_endpoint "Submit Research Entry" "POST" "/research/entries" \
    "{\"userId\":\"$USER_ID\",\"promptId\":\"test-prompt\",\"content\":\"I feel happy today\",\"sentimentLabel\":\"positive\",\"tags\":[\"mood\",\"positive\"],\"metadata\":{\"typingSpeed\":50,\"sessionDuration\":120,\"timeOfDay\":\"morning\",\"deviceModel\":\"iPhone\"}}"

# Get sentiment data
test_endpoint "Get Sentiment Data" "GET" "/research/sentiment" ""

# Get distortions (CBT)
test_endpoint "Get CBT Distortions" "GET" "/research/distortions" ""

# Get overview
test_endpoint "Get Research Overview" "GET" "/research/overview" ""

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👤 7. USER PROFILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get user profile
test_endpoint "Get User Profile" "GET" "/users/profile/$USER_ID" ""

# Update profile
test_endpoint "Update Profile" "PUT" "/users/profile/$USER_ID" \
    "{\"name\":\"Test User\",\"bio\":\"Testing the app\"}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 FINAL RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo "Total: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check backend connection and logs.${NC}"
    exit 1
fi
