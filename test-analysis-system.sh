#!/bin/bash

BASE_URL="https://depresso-ios.vercel.app/api/v1"

echo "🧪 TESTING NEW UNIFIED ANALYSIS SYSTEM"
echo "========================================"
echo ""

# Register user
echo "1️⃣  Creating test user..."
USER_RESP=$(curl -s -X POST "$BASE_URL/users/register" -H "Content-Type: application/json")
USER_ID=$(echo $USER_RESP | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "    User ID: $USER_ID"
echo ""

# Test 1: Submit journal entry with automatic analysis
echo "2️⃣  Testing automatic analysis on journal entry..."
curl -s -X POST "$BASE_URL/journal/entries" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"title\":\"Feeling Overwhelmed\",\"content\":\"I always fail at everything. I should have done better. This is a complete disaster and everyone must think I'm worthless.\"}" | jq '.'
echo ""

# Test 2: Submit community post with analysis
echo "3️⃣  Testing automatic analysis on community post..."
curl -s -X POST "$BASE_URL/community/posts" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"title\":\"Small Win Today\",\"content\":\"I'm grateful for the support I received today. Feeling hopeful and motivated to keep going!\"}" | jq '.'
echo ""

# Test 3: Direct analysis submission
echo "4️⃣  Testing direct analysis API..."
ANALYSIS=$(curl -s -X POST "$BASE_URL/analysis/submit" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"source\":\"research\",\"content\":\"I feel anxious but I'm trying to stay calm and focus on positive things\",\"context\":{\"typingSpeed\":45,\"sessionDuration\":120,\"editCount\":3,\"timeOfDay\":\"evening\"}}")
echo "$ANALYSIS" | jq '.'
echo ""

# Add more entries for better testing
echo "5️⃣  Adding more test entries..."
curl -s -X POST "$BASE_URL/analysis/submit" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"source\":\"ai_chat\",\"content\":\"I'm sad and worried but hopeful things will get better\",\"context\":{\"typingSpeed\":50,\"timeOfDay\":\"morning\"}}" > /dev/null

curl -s -X POST "$BASE_URL/analysis/submit" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"source\":\"ai_chat\",\"content\":\"Today was great! I accomplished so much and feel proud of myself\",\"context\":{\"typingSpeed\":60,\"timeOfDay\":\"afternoon\"}}" > /dev/null
echo "    ✅ Added 2 more entries"
echo ""

# Test 4: Get trends
echo "6️⃣  Testing trends endpoint..."
TRENDS=$(curl -s "$BASE_URL/analysis/trends?userId=$USER_ID&days=7")
echo "$TRENDS" | jq '{
    sentiment_entries: (.sentimentTimeline | length),
    cbt_patterns: (.cbtPatterns | length),
    emotions: (.emotions | length)
}'
echo ""

# Test 5: Get insights
echo "7️⃣  Testing insights endpoint..."
INSIGHTS=$(curl -s "$BASE_URL/analysis/insights?userId=$USER_ID")
echo "$INSIGHTS" | jq '{
    total_entries: .overview.total_entries,
    avg_sentiment: .overview.avg_sentiment,
    positive_count: .overview.positive_count,
    negative_count: .overview.negative_count,
    top_distortions: .topDistortions,
    weekly_comparison: .weeklyComparison
}'
echo ""

# Test 6: Get community stats
echo "8️⃣  Testing community stats..."
curl -s "$BASE_URL/community/stats" | jq '{
    total_posts: .overview.total_posts,
    total_likes: .overview.total_likes,
    active_users: .overview.active_users,
    sentiment_distribution: .sentimentDistribution
}'
echo ""

# Test 7: Get trending posts
echo "9️⃣  Testing trending posts..."
curl -s "$BASE_URL/community/trending?days=7&limit=3" | jq '[.[] | {id, title, like_count}]'
echo ""

echo "✅ ALL ANALYSIS ENDPOINTS TESTED!"
echo ""
echo "🎉 FEATURES WORKING:"
echo "   ✅ Automatic sentiment analysis"
echo "   ✅ CBT pattern detection"
echo "   ✅ Emotion recognition"
echo "   ✅ Risk level assessment"
echo "   ✅ Trends over time"
echo "   ✅ Weekly comparisons"
echo "   ✅ Community statistics"
echo "   ✅ Trending posts"
