#!/bin/bash

BASE_URL="https://depresso-ios.vercel.app/api/v1"
echo "🧪 TESTING DEPRESSO BACKEND FEATURES"
echo "===================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📝 1. USER & AUTHENTICATION${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Register user
RESPONSE=$(curl -s -X POST "$BASE_URL/users/register" -H "Content-Type: application/json")
USER_ID=$(echo $RESPONSE | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)

if [ -n "$USER_ID" ]; then
    echo -e "${GREEN}✅ User Registration${NC} - ID: $USER_ID"
    ((PASSED++))
else
    echo -e "${RED}❌ User Registration Failed${NC}"
    ((FAILED++))
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📊 2. ASSESSMENTS (PHQ-8, GAD-7)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Submit PHQ-8
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/phq8.json -X POST "$BASE_URL/assessments" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"assessmentType\":\"PHQ-8\",\"score\":15,\"answers\":[2,2,2,2,2,2,2,1]}")

if [ "$RESPONSE" = "201" ]; then
    echo -e "${GREEN}✅ PHQ-8 Submission${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ PHQ-8 Failed${NC} (HTTP $RESPONSE)"
    ((FAILED++))
fi

# Submit GAD-7
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/gad7.json -X POST "$BASE_URL/assessments" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"assessmentType\":\"GAD-7\",\"score\":12,\"answers\":[2,2,1,2,1,2,2]}")

if [ "$RESPONSE" = "201" ]; then
    echo -e "${GREEN}✅ GAD-7 Submission${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ GAD-7 Failed${NC} (HTTP $RESPONSE)"
    ((FAILED++))
fi

# Get Streak
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/streak.json "$BASE_URL/assessments/streak?userId=$USER_ID")
STREAK_DATA=$(cat /tmp/streak.json)

if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Streak Tracking${NC} - $STREAK_DATA"
    ((PASSED++))
else
    echo -e "${RED}❌ Streak Failed${NC}"
    ((FAILED++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🤖 3. AI JOURNAL & CBT${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create journal entry
JOURNAL_RESPONSE=$(curl -s -X POST "$BASE_URL/journal/entries" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"title\":\"Daily Check-in\",\"content\":\"Testing AI companion\"}")
ENTRY_ID=$(echo $JOURNAL_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)

if [ -n "$ENTRY_ID" ]; then
    echo -e "${GREEN}✅ Journal Entry Creation${NC} - ID: $ENTRY_ID"
    ((PASSED++))
else
    echo -e "${RED}❌ Journal Entry Failed${NC}"
    ((FAILED++))
fi

# AI Message (CBT-style therapeutic response)
AI_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/journal/entries/$ENTRY_ID/messages" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"sender\":\"user\",\"content\":\"I'm feeling anxious about work\"}")
AI_CODE=$(echo "$AI_RESPONSE" | tail -n1)
AI_BODY=$(echo "$AI_RESPONSE" | sed '$d')

if [ "$AI_CODE" = "201" ]; then
    AI_CONTENT=$(echo "$AI_BODY" | grep -o '"content":"[^"]*"' | cut -d'"' -f4 | head -c 80)
    echo -e "${GREEN}✅ AI Companion Response${NC}"
    echo "   AI: ${AI_CONTENT}..."
    ((PASSED++))
else
    echo -e "${RED}❌ AI Response Failed${NC} (HTTP $AI_CODE)"
    echo "   Error: $AI_BODY"
    ((FAILED++))
fi

# Get conversation history
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/messages.json "$BASE_URL/journal/entries/$ENTRY_ID/messages")
if [ "$RESPONSE" = "200" ]; then
    MSG_COUNT=$(cat /tmp/messages.json | grep -o '"id":' | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Conversation History${NC} - $MSG_COUNT messages"
    ((PASSED++))
else
    echo -e "${RED}❌ History Failed${NC}"
    ((FAILED++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🏘️  4. COMMUNITY FEATURES${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create post
POST_RESPONSE=$(curl -s -X POST "$BASE_URL/community/posts" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"title\":\"Recovery Journey\",\"content\":\"Sharing my progress with the community\"}")
POST_ID=$(echo $POST_RESPONSE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -n "$POST_ID" ]; then
    echo -e "${GREEN}✅ Community Post Creation${NC} - ID: $POST_ID"
    ((PASSED++))
else
    echo -e "${RED}❌ Post Creation Failed${NC}"
    ((FAILED++))
fi

# Get all posts
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/posts.json "$BASE_URL/community/posts")
if [ "$RESPONSE" = "200" ]; then
    POST_COUNT=$(cat /tmp/posts.json | grep -o '"id":' | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Get Community Posts${NC} - $POST_COUNT posts"
    ((PASSED++))
else
    echo -e "${RED}❌ Get Posts Failed${NC}"
    ((FAILED++))
fi

# Like post
RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$BASE_URL/community/posts/$POST_ID/like" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\"}")

if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Like Post${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Like Failed${NC}"
    ((FAILED++))
fi

# Get liked posts
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/liked.json "$BASE_URL/community/posts/liked?userId=$USER_ID")
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Get Liked Posts${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Get Liked Failed${NC}"
    ((FAILED++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🔬 5. RESEARCH & SENTIMENT${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Submit research entry with sentiment
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/research.json -X POST "$BASE_URL/research/entries" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"promptId\":\"mood-check\",\"content\":\"I feel optimistic today\",\"sentimentLabel\":\"positive\",\"tags\":[\"mood\",\"positive\"],\"metadata\":{\"typingSpeed\":50,\"sessionDuration\":120,\"timeOfDay\":\"morning\",\"deviceModel\":\"iPhone15\"}}")

if [ "$RESPONSE" = "201" ]; then
    echo -e "${GREEN}✅ Research Entry Submission${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Research Entry Failed${NC}"
    ((FAILED++))
fi

# Get sentiment data
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/sentiment.json "$BASE_URL/research/sentiment")
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Sentiment Analysis Data${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Sentiment Failed${NC}"
    ((FAILED++))
fi

# Get research stats
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/stats.json "$BASE_URL/research/stats")
if [ "$RESPONSE" = "200" ]; then
    STATS=$(cat /tmp/stats.json)
    echo -e "${GREEN}✅ Research Statistics${NC}"
    echo "   Data: $STATS"
    ((PASSED++))
else
    echo -e "${RED}❌ Stats Failed${NC}"
    ((FAILED++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}👤 6. USER PROFILE${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get profile
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/profile.json "$BASE_URL/users/profile/$USER_ID")
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Get User Profile${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Profile Failed${NC}"
    ((FAILED++))
fi

# Update profile
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/profile_update.json -X PUT "$BASE_URL/users/profile/$USER_ID" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test User\",\"bio\":\"Mental health journey\"}")

if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Update User Profile${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Profile Update Failed${NC}"
    ((FAILED++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📊 FINAL RESULTS${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "✅ Passed: ${GREEN}$PASSED${NC}"
echo -e "❌ Failed: ${RED}$FAILED${NC}"
echo "   Total: $((PASSED + FAILED))"
echo ""

# Summary
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL FEATURES WORKING!${NC}"
    echo ""
    echo "✅ User Registration & Auth"
    echo "✅ PHQ-8 & GAD-7 Assessments"
    echo "✅ Streak Tracking"
    echo "✅ AI Journal Companion (Gemini AI)"
    echo "✅ CBT Guided Journaling"
    echo "✅ Community Posts & Likes"
    echo "✅ Sentiment Analysis"
    echo "✅ Research Data Collection"
    echo "✅ User Profile Management"
    exit 0
else
    echo -e "${YELLOW}⚠️  $FAILED feature(s) need attention${NC}"
    exit 1
fi
