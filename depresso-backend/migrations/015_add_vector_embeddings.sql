-- Enable the pgvector extension if it is not already enabled
CREATE EXTENSION IF NOT EXISTS vector;

-- Add an embedding column to the AIChatMessages table
-- We use 768 dimensions which is standard for Gemini's text-embedding-004 model
ALTER TABLE AIChatMessages
ADD COLUMN IF NOT EXISTS embedding vector(768);

-- Create an index to speed up similarity searches (Cosine Similarity)
CREATE INDEX IF NOT EXISTS aichatmessages_embedding_idx 
ON AIChatMessages 
USING ivfflat (embedding vector_cosine_ops);
