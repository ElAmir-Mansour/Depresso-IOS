-- 11. Add Authentication Fields
-- Support for Apple Sign In and future auth providers

ALTER TABLE Users
ADD COLUMN IF NOT EXISTS apple_user_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS full_name TEXT;

CREATE INDEX IF NOT EXISTS idx_users_apple_id ON Users(apple_user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON Users(email);
