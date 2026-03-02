#!/bin/bash

echo "🔧 PRODUCTION DATABASE MIGRATION SCRIPT"
echo "========================================"
echo ""
echo "This script will run the UnifiedEntries migration on your production database."
echo ""
echo "⚠️  You need your production DATABASE_URL from Vercel."
echo ""
read -p "Enter your production DATABASE_URL: " DB_URL

if [ -z "$DB_URL" ]; then
    echo "❌ No DATABASE_URL provided. Exiting."
    exit 1
fi

echo ""
echo "📊 Running migration on production..."
echo ""

export DATABASE_URL="$DB_URL"

cd depresso-backend
node run_migrations.js

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration completed successfully!"
    echo ""
    echo "🧪 Testing endpoints..."
    echo ""
    
    USER_ID=$(uuidgen)
    
    echo "Testing analysis endpoint..."
    RESULT=$(curl -s -X POST "https://depresso-ios.vercel.app/api/v1/analysis/submit" \
        -H "Content-Type: application/json" \
        -d "{\"userId\":\"$USER_ID\",\"source\":\"test\",\"content\":\"I feel happy and grateful today\"}")
    
    if echo "$RESULT" | grep -q "entry"; then
        echo "✅ Analysis endpoint working!"
    else
        echo "❌ Analysis endpoint error: $RESULT"
    fi
    
    echo ""
    echo "Testing community stats..."
    STATS=$(curl -s "https://depresso-ios.vercel.app/api/v1/community/stats")
    
    if echo "$STATS" | grep -q "overview"; then
        echo "✅ Community stats working!"
    else
        echo "❌ Community stats error: $STATS"
    fi
    
    echo ""
    echo "🎉 ALL DONE! Your app is ready to use."
    echo ""
    echo "📱 Next: Run the iOS app on your iPhone and test:"
    echo "   1. Navigate to Insights tab (Tab 3)"
    echo "   2. Create a journal entry"
    echo "   3. Check Community → Trending"
    echo ""
else
    echo ""
    echo "❌ Migration failed. Check the error above."
    echo ""
fi
