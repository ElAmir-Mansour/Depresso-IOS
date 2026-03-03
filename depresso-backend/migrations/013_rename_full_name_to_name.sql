-- 12. Rename full_name to name for consistency
-- The code uses 'name' but migration 011 created 'full_name'

-- Rename the column if it exists
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='full_name'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='name'
    ) THEN
        ALTER TABLE Users RENAME COLUMN full_name TO name;
    END IF;
    
    -- If both exist (shouldn't happen but just in case), keep name and drop full_name
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='full_name'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='name'
    ) THEN
        -- Copy full_name to name if name is null
        UPDATE Users SET name = full_name WHERE name IS NULL AND full_name IS NOT NULL;
        ALTER TABLE Users DROP COLUMN full_name;
    END IF;
END $$;
