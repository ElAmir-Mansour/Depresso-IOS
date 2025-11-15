-- Migration: Add comprehensive HealthKit metrics support
-- This adds support for additional health data points collected from HealthKit

-- Add new columns to DailyMetrics table for comprehensive health tracking
ALTER TABLE DailyMetrics 
ADD COLUMN IF NOT EXISTS distance FLOAT,
ADD COLUMN IF NOT EXISTS flights_climbed FLOAT,
ADD COLUMN IF NOT EXISTS exercise_time FLOAT,
ADD COLUMN IF NOT EXISTS stand_hours FLOAT,
ADD COLUMN IF NOT EXISTS resting_heart_rate FLOAT,
ADD COLUMN IF NOT EXISTS heart_rate_variability FLOAT,
ADD COLUMN IF NOT EXISTS vo2_max FLOAT,
ADD COLUMN IF NOT EXISTS walking_running_distance FLOAT,
ADD COLUMN IF NOT EXISTS cycling_distance FLOAT,
ADD COLUMN IF NOT EXISTS swimming_distance FLOAT,
ADD COLUMN IF NOT EXISTS respiratory_rate FLOAT,
ADD COLUMN IF NOT EXISTS body_mass FLOAT,
ADD COLUMN IF NOT EXISTS body_fat_percentage FLOAT,
ADD COLUMN IF NOT EXISTS lean_body_mass FLOAT,
ADD COLUMN IF NOT EXISTS mindful_minutes FLOAT,
ADD COLUMN IF NOT EXISTS sleep_hours FLOAT;

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_daily_metrics_user_date ON DailyMetrics(user_id, created_at DESC);

-- Add comments for documentation
COMMENT ON COLUMN DailyMetrics.distance IS 'Total distance covered in km';
COMMENT ON COLUMN DailyMetrics.flights_climbed IS 'Number of flights of stairs climbed';
COMMENT ON COLUMN DailyMetrics.exercise_time IS 'Active exercise time in minutes';
COMMENT ON COLUMN DailyMetrics.stand_hours IS 'Hours spent standing';
COMMENT ON COLUMN DailyMetrics.resting_heart_rate IS 'Resting heart rate in bpm';
COMMENT ON COLUMN DailyMetrics.heart_rate_variability IS 'HRV in milliseconds';
COMMENT ON COLUMN DailyMetrics.vo2_max IS 'VO2 Max in ml/kg/min';
COMMENT ON COLUMN DailyMetrics.walking_running_distance IS 'Walk + run distance in km';
COMMENT ON COLUMN DailyMetrics.cycling_distance IS 'Cycling distance in km';
COMMENT ON COLUMN DailyMetrics.swimming_distance IS 'Swimming distance in meters';
COMMENT ON COLUMN DailyMetrics.respiratory_rate IS 'Breathing rate in breaths/min';
COMMENT ON COLUMN DailyMetrics.body_mass IS 'Body weight in kg';
COMMENT ON COLUMN DailyMetrics.body_fat_percentage IS 'Body fat percentage';
COMMENT ON COLUMN DailyMetrics.lean_body_mass IS 'Lean muscle mass in kg';
COMMENT ON COLUMN DailyMetrics.mindful_minutes IS 'Mindfulness session time in minutes';
COMMENT ON COLUMN DailyMetrics.sleep_hours IS 'Total sleep time in hours';
