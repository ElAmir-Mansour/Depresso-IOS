const pool = require('../../config/db');
const textAnalysisService = require('../../services/textAnalysisService');

exports.getAllPosts = async (req, res) => {
    try {
        const result = await pool.query('SELECT id, title, content, like_count, created_at FROM CommunityPosts ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching posts:', error);
        res.status(500).send('Server error');
    }
};

exports.createPost = async (req, res) => {
    const { userId, title, content } = req.body;

    if (!userId || !content) {
        return res.status(400).send('userId and content are required.');
    }

    try {
        const result = await pool.query(
            'INSERT INTO CommunityPosts (user_id, title, content) VALUES ($1, $2, $3) RETURNING *',
            [userId, title, content]
        );
        
        // Auto-analyze the post in background
        setImmediate(async () => {
            try {
                const analysis = await textAnalysisService.analyzeText(content, {});
                await pool.query(
                    `INSERT INTO UnifiedEntries (
                        user_id, source, content, original_id,
                        sentiment, sentiment_score, cbt_distortions,
                        emotion_tags, keywords, risk_level,
                        word_count, character_count
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                    ON CONFLICT DO NOTHING`,
                    [
                        userId, 'community_post', content, result.rows[0].id.toString(),
                        analysis.sentiment, analysis.sentimentScore, JSON.stringify(analysis.cbtDistortions),
                        analysis.emotions.map(e => e.emotion), analysis.keywords, analysis.riskLevel,
                        analysis.metadata.wordCount, analysis.metadata.characterCount
                    ]
                );
                console.log(`✅ Analyzed community post for user ${userId}`);
            } catch (analysisError) {
                console.error('Background analysis failed:', analysisError);
            }
        });
        
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating post:', error);
        res.status(500).send('Server error');
    }
};

exports.likePost = async (req, res) => {
    const { postId } = req.params;
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const insertResult = await client.query(
            'INSERT INTO PostLikes (user_id, post_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [userId, postId]
        );

        if (insertResult.rowCount > 0) {
            await client.query(
                'UPDATE CommunityPosts SET like_count = like_count + 1 WHERE id = $1',
                [postId]
            );
        }

        await client.query('COMMIT');
        res.status(200).send('Post liked successfully.');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error liking post:', error);
        res.status(500).send('Server error');
    } finally {
        client.release();
    }
};

exports.unlikePost = async (req, res) => {
    const { postId } = req.params;
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const deleteResult = await client.query(
            'DELETE FROM PostLikes WHERE user_id = $1 AND post_id = $2',
            [userId, postId]
        );

        if (deleteResult.rowCount > 0) {
            await client.query(
                'UPDATE CommunityPosts SET like_count = like_count - 1 WHERE id = $1 AND like_count > 0',
                [postId]
            );
        }

        await client.query('COMMIT');
        res.status(200).send('Post unliked successfully.');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error unliking post:', error);
        res.status(500).send('Server error');
    } finally {
        client.release();
    }
};

// NEW: Get user's liked posts
exports.getLikedPosts = async (req, res) => {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    try {
        const result = await pool.query(
            'SELECT post_id FROM PostLikes WHERE user_id = $1',
            [userId]
        );
        
        // Return array of post IDs
        const likedPostIds = result.rows.map(row => row.post_id);
        res.json({ likedPostIds });
    } catch (error) {
        console.error('Error fetching liked posts:', error);
        res.status(500).send('Server error');
    }
};
/**
 * GET /api/v1/community/trending
 * Get trending posts (most liked in the past week)
 */
exports.getTrendingPosts = async (req, res) => {
    const { days = 7, limit = 10 } = req.query;
    
    try {
        const result = await pool.query(
            `SELECT id, title, content, like_count, created_at 
            FROM CommunityPosts 
            WHERE created_at >= NOW() - INTERVAL '${parseInt(days)} days'
            ORDER BY like_count DESC, created_at DESC 
            LIMIT $1`,
            [parseInt(limit)]
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching trending posts:', error);
        res.status(500).send('Server error');
    }
};

/**
 * GET /api/v1/community/stats
 * Get community engagement statistics
 */
exports.getCommunityStats = async (req, res) => {
    try {
        const stats = await pool.query(`
            SELECT 
                COUNT(*) as total_posts,
                SUM(like_count) as total_likes,
                AVG(like_count) as avg_likes_per_post,
                COUNT(DISTINCT user_id) as active_users,
                (SELECT COUNT(*) FROM CommunityPosts WHERE created_at >= NOW() - INTERVAL '7 days') as posts_this_week,
                (SELECT COUNT(*) FROM CommunityPosts WHERE created_at >= NOW() - INTERVAL '1 day') as posts_today
            FROM CommunityPosts
        `);
        
        // Get sentiment distribution from analyzed posts
        const sentimentDist = await pool.query(`
            SELECT 
                sentiment,
                COUNT(*) as count,
                AVG(sentiment_score) as avg_score
            FROM UnifiedEntries
            WHERE source = 'community_post'
            GROUP BY sentiment
        `);
        
        const overview = stats.rows[0] || {};
        
        res.json({
            overview: {
                total_posts: parseInt(overview.total_posts) || 0,
                total_likes: parseInt(overview.total_likes) || 0,
                avg_likes_per_post: parseFloat(overview.avg_likes_per_post) || 0,
                active_users: parseInt(overview.active_users) || 0,
                posts_this_week: parseInt(overview.posts_this_week) || 0,
                posts_today: parseInt(overview.posts_today) || 0
            },
            sentimentDistribution: sentimentDist.rows.map(s => ({
                sentiment: s.sentiment || 'neutral',
                count: parseInt(s.count) || 0,
                avg_score: s.avg_score ? parseFloat(s.avg_score) : null
            }))
        });
    } catch (error) {
        console.error('Error fetching community stats:', error);
        res.status(500).json({ error: 'Failed to fetch community stats' });
    }
};
