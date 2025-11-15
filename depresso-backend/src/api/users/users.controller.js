const pool = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

exports.register = async (req, res) => {
    const newUserId = uuidv4();
    try {
        await pool.query('INSERT INTO Users (id) VALUES ($1)', [newUserId]);
        res.status(201).json({ userId: newUserId });
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