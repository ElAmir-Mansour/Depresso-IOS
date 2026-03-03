#!/bin/bash

# Run migration 013 to fix full_name -> name column
# This script can be run safely multiple times

echo "🔧 Running migration 013: Rename full_name to name"

# Load environment variables
if [ -f .env.local ]; then
    source .env.local
elif [ -f .env ]; then
    source .env
else
    echo "❌ Error: No .env or .env.local found"
    exit 1
fi

# Determine database connection
if [ -n "$POSTGRES_URL" ]; then
    DB_CONN="$POSTGRES_URL"
elif [ -n "$DATABASE_URL" ]; then
    DB_CONN="$DATABASE_URL"
else
    # Build connection string from individual vars
    DB_CONN="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_DATABASE}"
fi

echo "📊 Running migration..."

# Run the migration
psql "$DB_CONN" -f migrations/013_rename_full_name_to_name.sql

if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully"
    echo ""
    echo "📋 Verifying Users table structure:"
    psql "$DB_CONN" -c "\d Users"
else
    echo "❌ Migration failed"
    exit 1
fi
