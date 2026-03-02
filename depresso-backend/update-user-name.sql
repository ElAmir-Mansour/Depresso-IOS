-- Update user name for your Apple ID
-- Replace with your actual name
UPDATE Users 
SET name = 'ElAmir', 
    updated_at = NOW()
WHERE apple_user_id = '001824.f737fe0e56c347d6a589ee166feb5def.0319';

-- Verify the update
SELECT id, name, email, apple_user_id, created_at 
FROM Users 
WHERE apple_user_id = '001824.f737fe0e56c347d6a589ee166feb5def.0319';
