// depresso-backend/src/api/analysis/analysis.controller.js
const pool = require('../../config/db');
const textAnalysisService = require('../../services/textAnalysisService');

/**
 * POST /api/v1/analysis/submit
 * Submit any text entry for unified analysis
 */
exports.submitEntry = async (req, res) => {
    const { userId, source, content, originalId, context } = req.body;
    
    if (!userId || !source || !content) {
        return res.status(400).json({ error: 'userId, source, and content are required' });
    }
    
    try {
        // Analyze the text
        const analysis = await textAnalysisService.analyzeText(content, context || {});
        
        // Store in unified table
        const result = await pool.query(
            `INSERT INTO UnifiedEntries (
                user_id, source, content, original_id,
                sentiment, sentiment_score, cbt_distortions,
                emotion_tags, keywords, risk_level,
                typing_speed, session_duration, edit_count, time_of_day,
                word_count, character_count
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
            RETURNING *`,
            [
                userId, source, content, originalId,
                analysis.sentiment, analysis.sentimentScore, JSON.stringify(analysis.cbtDistortions),
                analysis.emotions.map(e => e.emotion), analysis.keywords, analysis.riskLevel,
                analysis.metadata.typingSpeed, analysis.metadata.sessionDuration,
                context.editCount || null, analysis.metadata.timeOfDay,
                analysis.metadata.wordCount, analysis.metadata.characterCount
            ]
        );
        
        res.status(201).json({
            entry: result.rows[0],
            analysis: analysis
        });
    } catch (error) {
        console.error('Error submitting entry for analysis:', error);
        res.status(500).json({ error: 'Failed to analyze entry', details: error.message });
    }
};

/**
 * GET /api/v1/analysis/trends
 * Get sentiment and CBT trends for a user
 */
exports.getTrends = async (req, res) => {
    const { userId, days = 30 } = req.query;
    
    if (!userId) {
        return res.status(400).json({ error: 'userId is required' });
    }
    
    try {
        // Sentiment timeline
        const sentimentTimeline = await pool.query(
            `SELECT 
                DATE(created_at) as date,
                AVG(sentiment_score) as avg_sentiment,
                COUNT(*) as entry_count,
                ARRAY_AGG(DISTINCT sentiment) as sentiments
            FROM UnifiedEntries
            WHERE user_id = $1 
                AND created_at >= NOW() - INTERVAL '${parseInt(days)} days'
            GROUP BY DATE(created_at)
            ORDER BY date ASC`,
            [userId]
        );
        
        // CBT distortion frequency
        const cbtFrequency = await pool.query(
            `SELECT 
                distortion->>'type' as distortion_type,
                distortion->>'description' as description,
                COUNT(*) as frequency
            FROM UnifiedEntries,
                 jsonb_array_elements(cbt_distortions) as distortion
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '${parseInt(days)} days'
            GROUP BY distortion->>'type', distortion->>'description'
            ORDER BY frequency DESC`,
            [userId]
        );
        
        // Emotion distribution
        const emotionDist = await pool.query(
            `SELECT 
                UNNEST(emotion_tags) as emotion,
                COUNT(*) as count
            FROM UnifiedEntries
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '${parseInt(days)} days'
            GROUP BY emotion
            ORDER BY count DESC
            LIMIT 10`,
            [userId]
        );
        
        res.json({
            sentimentTimeline: sentimentTimeline.rows,
            cbtPatterns: cbtFrequency.rows,
            emotions: emotionDist.rows
        });
    } catch (error) {
        console.error('Error fetching trends:', error);
        res.status(500).json({ error: 'Failed to fetch trends' });
    }
};

/**
 * GET /api/v1/analysis/insights
 * Get personalized insights for a user
 */
exports.getInsights = async (req, res) => {
    const { userId } = req.query;
    
    if (!userId) {
        return res.status(400).json({ error: 'userId is required' });
    }
    
    try {
        // Overall stats
        const stats = await pool.query(
            `SELECT 
                COUNT(*) as total_entries,
                AVG(sentiment_score) as avg_sentiment,
                COUNT(CASE WHEN sentiment = 'positive' THEN 1 END) as positive_count,
                COUNT(CASE WHEN sentiment = 'negative' THEN 1 END) as negative_count,
                AVG(typing_speed) as avg_typing_speed,
                AVG(word_count) as avg_word_count
            FROM UnifiedEntries
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '30 days'`,
            [userId]
        );
        
        // Most common CBT distortions
        const topDistortions = await pool.query(
            `SELECT 
                distortion->>'description' as distortion,
                COUNT(*) as frequency
            FROM UnifiedEntries,
                 jsonb_array_elements(cbt_distortions) as distortion
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '30 days'
            GROUP BY distortion->>'description'
            ORDER BY frequency DESC
            LIMIT 3`,
            [userId]
        );
        
        // Compare to previous period
        const thisWeek = await pool.query(
            `SELECT AVG(sentiment_score) as avg_sentiment
            FROM UnifiedEntries
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '7 days'`,
            [userId]
        );
        
        const lastWeek = await pool.query(
            `SELECT AVG(sentiment_score) as avg_sentiment
            FROM UnifiedEntries
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '14 days'
                AND created_at < NOW() - INTERVAL '7 days'`,
            [userId]
        );
        
        const thisWeekScore = parseFloat(thisWeek.rows[0]?.avg_sentiment || 0.5);
        const lastWeekScore = parseFloat(lastWeek.rows[0]?.avg_sentiment || 0.5);
        const improvement = lastWeekScore !== 0 ? ((thisWeekScore - lastWeekScore) / lastWeekScore * 100).toFixed(1) : 0;
        
        res.json({
            overview: stats.rows[0],
            topDistortions: topDistortions.rows,
            weeklyComparison: {
                thisWeek: thisWeekScore,
                lastWeek: lastWeekScore,
                improvement: parseFloat(improvement),
                isImproving: thisWeekScore > lastWeekScore
            }
        });
    } catch (error) {
        console.error('Error fetching insights:', error);
        res.status(500).json({ error: 'Failed to fetch insights' });
    }
};

/**
 * GET /api/v1/analysis/entries
 * Get all analyzed entries for a user
 */
exports.getEntries = async (req, res) => {
    const { userId, source, limit = 50 } = req.query;
    
    if (!userId) {
        return res.status(400).json({ error: 'userId is required' });
    }
    
    try {
        let query = `
            SELECT * FROM UnifiedEntries
            WHERE user_id = $1
        `;
        const params = [userId];
        
        if (source) {
            query += ` AND source = $2`;
            params.push(source);
        }
        
        query += ` ORDER BY created_at DESC LIMIT $${params.length + 1}`;
        params.push(parseInt(limit));
        
        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching entries:', error);
        res.status(500).json({ error: 'Failed to fetch entries' });
    }
};

module.exports = exports;
