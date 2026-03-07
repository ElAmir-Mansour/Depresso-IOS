-- Migration: Fix UnifiedEntries Uniqueness
-- Adds a unique constraint to original_id to allow UPSERT operations

-- 1. Remove any existing duplicates before adding constraint
DELETE FROM UnifiedEntries a USING UnifiedEntries b
WHERE a.id < b.id AND a.original_id = b.original_id AND a.original_id IS NOT NULL;

-- 2. Add unique constraint to original_id
-- We only enforce uniqueness for rows that HAVE an original_id (which should be all source-linked rows)
ALTER TABLE UnifiedEntries ADD CONSTRAINT unique_original_id UNIQUE (original_id);

COMMENT ON CONSTRAINT unique_original_id ON UnifiedEntries IS 'Ensures one analysis entry per source document (journal, post, message)';
