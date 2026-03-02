-- Migration: Create Unified Entries Table for Analysis
-- This table stores ALL user text entries with analysis metadata

CREATE TABLE IF NOT EXISTS UnifiedEntries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    
    -- Entry info
    source VARCHAR(50) NOT NULL, -- 'ai_chat', 'cbt_journal', 'community_post', 'research'
    content TEXT NOT NULL,
    original_id VARCHAR(100), -- Reference to original entry (journal_id, post_id, etc)
    
    -- Sentiment analysis
    sentiment VARCHAR(20), -- 'positive', 'neutral', 'negative'
    sentiment_score FLOAT CHECK (sentiment_score >= 0 AND sentiment_score <= 1),
    
    -- CBT analysis
    cbt_distortions JSONB, -- Array of detected distortions
    
    -- Emotion detection
    emotion_tags TEXT[], -- ['anxious', 'hopeful', etc.]
    
    -- Keywords & themes
    keywords TEXT[],
    
    -- Risk assessment
    risk_level VARCHAR(20) DEFAULT 'safe', -- 'safe', 'caution', 'high'
    
    -- Context metadata
    typing_speed FLOAT,
    session_duration INT, -- in seconds
    edit_count INT,
    time_of_day VARCHAR(20), -- 'morning', 'afternoon', 'evening', 'night'
    word_count INT,
    character_count INT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast queries
CREATE INDEX IF NOT EXISTS idx_unified_user_date ON UnifiedEntries(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_unified_sentiment ON UnifiedEntries(sentiment, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_unified_source ON UnifiedEntries(source);
CREATE INDEX IF NOT EXISTS idx_unified_risk ON UnifiedEntries(risk_level, created_at DESC);

-- Migrate existing data from JournalEntries
INSERT INTO UnifiedEntries (user_id, source, content, original_id, created_at)
SELECT 
    user_id,
    'cbt_journal' as source,
    COALESCE(content, '') as content,
    id::TEXT as original_id,
    created_at
FROM JournalEntries
WHERE content IS NOT NULL AND content != ''
ON CONFLICT (id) DO NOTHING;

-- Migrate existing data from CommunityPosts
INSERT INTO UnifiedEntries (user_id, source, content, original_id, created_at)
SELECT 
    user_id,
    'community_post' as source,
    content,
    id::TEXT as original_id,
    created_at
FROM CommunityPosts
WHERE content IS NOT NULL AND content != ''
ON CONFLICT (id) DO NOTHING;

-- Migrate existing data from ResearchEntries
INSERT INTO UnifiedEntries (user_id, source, content, original_id, sentiment, created_at)
SELECT 
    user_id,
    'research' as source,
    content,
    id::TEXT as original_id,
    sentiment_label as sentiment,
    created_at
FROM ResearchEntries
WHERE content IS NOT NULL AND content != ''
ON CONFLICT (id) DO NOTHING;

COMMENT ON TABLE UnifiedEntries IS 'Unified storage for all user text entries with analysis metadata';
COMMENT ON COLUMN UnifiedEntries.source IS 'Origin: ai_chat, cbt_journal, community_post, research';
COMMENT ON COLUMN UnifiedEntries.cbt_distortions IS 'Detected cognitive distortions as JSON array';
COMMENT ON COLUMN UnifiedEntries.risk_level IS 'Crisis risk assessment: safe, caution, high';
