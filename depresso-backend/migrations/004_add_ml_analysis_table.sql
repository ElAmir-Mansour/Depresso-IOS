-- Migration: Add ML Analysis Results Table
-- Date: 2025-11-12
-- Description: Creates table for storing Huawei Agent ML analysis results

CREATE TABLE IF NOT EXISTS MLAnalysisResults (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    risk_score FLOAT NOT NULL,
    severity TEXT NOT NULL, -- 'Low', 'Mild', 'Moderate', 'Severe'
    confidence FLOAT,
    recommendations JSONB,
    warnings JSONB,
    trends JSONB,
    conversation_id TEXT,
    raw_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ml_analysis_user_id ON MLAnalysisResults(user_id);
CREATE INDEX IF NOT EXISTS idx_ml_analysis_created_at ON MLAnalysisResults(created_at);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON MLAnalysisResults TO PUBLIC;
GRANT USAGE, SELECT ON SEQUENCE mlanalysisresults_id_seq TO PUBLIC;
