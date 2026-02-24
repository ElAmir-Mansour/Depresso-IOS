const pool = require('../../config/db');
const aiService = require('../../services/aiService');

// Create a new journal entry
exports.createEntry = async (req, res) => {
    const { userId, title, content } = req.body;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    try {
        const result = await pool.query(
            'INSERT INTO JournalEntries (user_id, title, content) VALUES ($1, $2, $3) RETURNING *',
            [userId, title, content]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating journal entry:', error);
        res.status(500).send('Server error');
    }
};

// Get all journal entries for a specific user
exports.getEntriesForUser = async (req, res) => {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).send('userId query parameter is required.');
    }

    try {
        const result = await pool.query(
            'SELECT * FROM JournalEntries WHERE user_id = $1 ORDER BY created_at DESC',
            [userId]
        );
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching journal entries:', error);
        res.status(500).send('Server error');
    }
};

// Add a chat message to a journal entry and get AI response
exports.addMessageToEntry = async (req, res) => {
    const { entryId } = req.params;
    const { userId, sender, content } = req.body;

    if (!userId || !sender || !content) {
        return res.status(400).json({ error: 'userId, sender, and content are required.' });
    }

    // Validate entryId format
    if (!entryId || entryId === 'undefined' || entryId === 'null') {
        return res.status(400).json({ error: 'Valid entryId is required.' });
    }

    const client = await pool.connect();
    let historyRows = [];

    try {
        // --- PHASE 1: Save User Message & Fetch Context (Fast DB Lock) ---
        await client.query('BEGIN');

        // 1. Save the user's message
        await client.query(
            'INSERT INTO AIChatMessages (entry_id, user_id, sender, content) VALUES ($1, $2, $3, $4)',
            [entryId, userId, sender, content]
        );

        // 2. Fetch conversation history (Limit to last 20 for speed/context window)
        // We fetch DESC to get the recent ones, then reverse them for the AI
        const historyResult = await client.query(
            'SELECT sender, content FROM AIChatMessages WHERE entry_id = $1 ORDER BY created_at DESC LIMIT 20',
            [entryId]
        );
        historyRows = historyResult.rows.reverse();

        await client.query('COMMIT');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error saving user message:', error);
        return res.status(500).json({ error: 'Server error', message: 'Failed to save message' });
    } finally {
        client.release(); // Release connection while waiting for AI
    }

    // --- PHASE 2: Generate AI Response (Slow External Call - No DB Lock) ---
    let aiContent;
    try {
        aiContent = await aiService.generateResponse(historyRows);
    } catch (error) {
        console.error('AI Service Error:', error);
        
        // Handle specific AI errors (like content filters)
        if (error.isContentFilter) {
            aiContent = "I'm here to listen. Sometimes the system is extra cautious. Could you rephrase that, or tell me more about how you're feeling today?";
        } else {
            return res.status(500).json({
                error: 'AI service error',
                details: error.details || 'Please try again',
                code: error.code
            });
        }
    }

    // --- PHASE 3: Save AI Response (Fast DB Lock) ---
    const client2 = await pool.connect();
    try {
        await client2.query('BEGIN');
        
        const aiMessageResult = await client2.query(
            'INSERT INTO AIChatMessages (entry_id, user_id, sender, content) VALUES ($1, $2, $3, $4) RETURNING *',
            [entryId, userId, 'assistant', aiContent]
        );

        await client2.query('COMMIT');
        
        // Send success response
        res.status(201).json(aiMessageResult.rows[0]);
    } catch (error) {
        await client2.query('ROLLBACK');
        console.error('Error saving AI response:', error);
        res.status(500).json({ error: 'Server error', message: 'Failed to save AI response' });
    } finally {
        client2.release();
    }
};

// Get all messages for a specific journal entry
exports.getMessagesForEntry = async (req, res) => {
    const { entryId } = req.params;

    try {
        const result = await pool.query(
            'SELECT * FROM AIChatMessages WHERE entry_id = $1 ORDER BY created_at ASC',
            [entryId]
        );
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching messages for entry:', error);
        res.status(500).send('Server error');
    }
};