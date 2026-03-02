#!/bin/bash

# Quick script to update your name in the database via API

USER_ID="37063c67-28b0-4573-a894-8adab873c2cf"
API_URL="https://depresso-ios.vercel.app/api/v1"

echo "🔧 Updating your profile name..."

curl -X PUT "$API_URL/users/profile/$USER_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ElAmir",
    "bio": "iOS Developer"
  }'

echo -e "\n\n✅ Done! Now restart your app."
