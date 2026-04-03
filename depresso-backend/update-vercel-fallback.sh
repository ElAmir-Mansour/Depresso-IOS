#!/bin/bash
echo "🚀 Updating Vercel with fallback mode..."
echo ""
echo "This will enable the AI fallback on production so journal works immediately."
echo ""

# Add USE_AI_FALLBACK to production
vercel env add USE_AI_FALLBACK production << ANSWER
true
ANSWER

echo ""
echo "✅ Added USE_AI_FALLBACK=true to production"
echo ""
echo "Now deploying to production..."
vercel --prod

echo ""
echo "✅ Done! Journal AI now works with fallback responses on production."
echo ""
echo "To get real AI responses:"
echo "1. Get new Gemini keys from https://aistudio.google.com/apikey"
echo "2. Run: ./get-new-gemini-keys.sh"
echo "3. Update Vercel: vercel env add GEMINI_API_KEY production"
echo "4. Set USE_AI_FALLBACK=false"
echo "5. Redeploy: vercel --prod"
