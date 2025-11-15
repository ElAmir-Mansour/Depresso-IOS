-- Migration: Create ml_analyses table for storing Huawei Agent analysis results

CREATE TABLE IF NOT EXISTS ml_analyses (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    risk_score DECIMAL(5,2),
    confidence DECIMAL(5,4),
    severity VARCHAR(50),
    recommendations JSONB,
    key_factors JSONB,
    red_flags JSONB,
    raw_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ml_analyses_user_id ON ml_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_ml_analyses_created_at ON ml_analyses(created_at DESC);

COMMENT ON TABLE ml_analyses IS 'Stores ML-based depression risk analyses from Huawei Agent';
COMMENT ON COLUMN ml_analyses.risk_score IS 'Depression risk score (0-100)';
COMMENT ON COLUMN ml_analyses.confidence IS 'Model confidence score (0-1)';
COMMENT ON COLUMN ml_analyses.severity IS 'Risk severity level (Low/Mild/Moderate/Severe)';
