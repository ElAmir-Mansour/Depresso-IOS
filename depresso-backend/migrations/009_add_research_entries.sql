-- 9. NLP Research Data
CREATE TABLE IF NOT EXISTS ResearchEntries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    prompt_id TEXT NOT NULL,
    content TEXT NOT NULL,
    sentiment_label TEXT,
    tags TEXT[],
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_research_entries_user_id ON ResearchEntries(user_id);
CREATE INDEX IF NOT EXISTS idx_research_entries_prompt_id ON ResearchEntries(prompt_id);
