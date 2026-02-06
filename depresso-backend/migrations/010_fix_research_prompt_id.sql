-- Fix Research Prompt ID type mismatch
-- The app sends text IDs (e.g., "daily_mood_1"), but the table expects UUID.
-- We must change the column type to TEXT.

ALTER TABLE ResearchEntries 
ALTER COLUMN prompt_id TYPE TEXT;
