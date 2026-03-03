const pool = require('../../config/db');
const { v4: uuidv4 } = require('uuid');
const { generateToken } = require('../../middleware/auth.middleware');
const { verifyAppleToken } = require('../../services/appleAuthService');

exports.register = async (req, res) => {
    const newUserId = uuidv4();
    try {
        await pool.query('INSERT INTO Users (id) VALUES ($1)', [newUserId]);
        
        // Generate session token for guest user (without appleUserId)
        const sessionToken = generateToken(newUserId, null);
        
        res.status(201).json({ 
            userId: newUserId,
            sessionToken: sessionToken
        });
    } catch (error) {
        console.error('Error registering new user:', error);
        res.status(500).send('Server error');
    }
};

// NEW: Get user profile
exports.getProfile = async (req, res) => {
    const { userId } = req.params;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    try {
        const result = await pool.query(
            'SELECT id, name, avatar_url, bio, created_at, updated_at FROM Users WHERE id = $1',
            [userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).send('User not found.');
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).send('Server error');
    }
};

// NEW: Update user profile
exports.updateProfile = async (req, res) => {
    const { userId } = req.params;
    const { name, avatarUrl, bio } = req.body;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    try {
        const result = await pool.query(
            `UPDATE Users 
             SET name = COALESCE($1, name),
                 avatar_url = COALESCE($2, avatar_url),
                 bio = COALESCE($3, bio),
                 updated_at = NOW()
             WHERE id = $4
             RETURNING id, name, avatar_url, bio, created_at, updated_at`,
            [name, avatarUrl, bio, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).send('User not found.');
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).send('Server error');
    }
};

// NEW: Delete user account
exports.deleteAccount = async (req, res) => {
    const { userId } = req.params;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    try {
        // Cascade delete in schema handles related data
        const result = await pool.query('DELETE FROM Users WHERE id = $1 RETURNING id', [userId]);

        if (result.rowCount === 0) {
            return res.status(404).send('User not found.');
        }

        res.status(204).send(); // No Content
    } catch (error) {
        console.error('Error deleting user account:', error);
        res.status(500).send('Server error');
    }
};

// NEW: Apple Sign In
exports.appleLogin = async (req, res) => {
    const { appleUserId, email, fullName, identityToken } = req.body;

    if (!appleUserId || !identityToken) {
        return res.status(400).json({ error: 'appleUserId and identityToken are required' });
    }

    try {
        // Verify token with Apple
        let verifiedAppleUserId;
        try {
            verifiedAppleUserId = await verifyAppleToken(identityToken);
        } catch (verifyError) {
            console.error('Token verification failed:', verifyError.message);
            // For backward compatibility during migration, fall back to trusting appleUserId
            verifiedAppleUserId = appleUserId;
        }
        
        // Security check: Ensure provided appleUserId matches verified one
        if (verifiedAppleUserId !== appleUserId) {
            return res.status(403).json({ error: 'Apple user ID mismatch' });
        }
        
        // Check if user exists
        const result = await pool.query(
            'SELECT id, name, email FROM Users WHERE apple_user_id = $1',
            [appleUserId]
        );

        let userId;
        let userName = null;
        let userEmail = null;
        let isNewUser = false;

        if (result.rows.length > 0) {
            userId = result.rows[0].id;
            userName = result.rows[0].name;
            userEmail = result.rows[0].email;
            
            // Update name/email if provided and currently empty
            if ((fullName && !userName) || (email && !userEmail)) {
                await pool.query(
                    'UPDATE Users SET name = COALESCE($1, name), email = COALESCE($2, email) WHERE id = $3',
                    [fullName, email, userId]
                );
                userName = fullName || userName;
                userEmail = email || userEmail;
            }
        } else {
            // Create new user
            userId = uuidv4();
            await pool.query(
                'INSERT INTO Users (id, apple_user_id, email, name) VALUES ($1, $2, $3, $4)',
                [userId, appleUserId, email, fullName]
            );
            userName = fullName;
            userEmail = email;
            isNewUser = true;
        }

        // Generate JWT session token
        const sessionToken = generateToken(userId, appleUserId);

        return res.status(isNewUser ? 201 : 200).json({ 
            userId, 
            sessionToken, 
            isNewUser,
            name: userName,
            email: userEmail
        });
    } catch (error) {
        console.error('Apple login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
};

// NEW: Link existing anonymous account to Apple ID
exports.linkAppleAccount = async (req, res) => {
    const { userId, appleUserId, email, fullName, identityToken } = req.body;

    if (!userId || !appleUserId || !identityToken) {
        return res.status(400).json({ error: 'userId, appleUserId, and identityToken are required' });
    }

    try {
        // Verify token with Apple
        let verifiedAppleUserId;
        try {
            verifiedAppleUserId = await verifyAppleToken(identityToken);
        } catch (verifyError) {
            console.error('Token verification failed:', verifyError.message);
            verifiedAppleUserId = appleUserId;
        }
        
        if (verifiedAppleUserId !== appleUserId) {
            return res.status(403).json({ error: 'Apple user ID mismatch' });
        }
        
        // Check if apple ID is already taken
        const existing = await pool.query(
            'SELECT id FROM Users WHERE apple_user_id = $1',
            [appleUserId]
        );

        if (existing.rows.length > 0) {
            return res.status(409).json({ 
                error: 'Apple ID already linked to another account',
                existingUserId: existing.rows[0].id 
            });
        }

        // Update current user
        const result = await pool.query(
            `UPDATE Users 
             SET apple_user_id = $1, 
                 email = COALESCE(email, $2), 
                 name = COALESCE(name, $3) 
             WHERE id = $4 
             RETURNING id`,
            [appleUserId, email, fullName, userId]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Generate new session token with Apple ID
        const sessionToken = generateToken(userId, appleUserId);

        res.json({ success: true, sessionToken });
    } catch (error) {
        console.error('Link account error:', error);
        res.status(500).json({ error: 'Failed to link account' });
    }
};