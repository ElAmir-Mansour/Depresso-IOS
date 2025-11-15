-- Add ML Analysis Results table
CREATE TABLE IF NOT EXISTS MLAnalysisResults (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    risk_score FLOAT NOT NULL,
    severity TEXT NOT NULL,
    confidence FLOAT,
    recommendations JSONB,
    warnings TEXT[],
    trends JSONB,
    raw_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_ml_analysis_user_date ON MLAnalysisResults(user_id, created_at DESC);

-- Add sleep_hours column to DailyMetrics if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'dailymetrics' AND column_name = 'sleep_hours'
    ) THEN
        ALTER TABLE DailyMetrics ADD COLUMN sleep_hours FLOAT;
    END IF;
END $$;
