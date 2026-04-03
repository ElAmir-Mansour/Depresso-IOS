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
                context?.typingSpeed || analysis.metadata.typingSpeed, 
                context?.sessionDuration || analysis.metadata.sessionDuration,
                context?.editCount || null, 
                analysis.metadata.timeOfDay,
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
        // Sentiment timeline - handle NULL sentiment_score
        const sentimentTimeline = await pool.query(
            `SELECT 
                DATE(created_at) as date,
                COALESCE(AVG(sentiment_score), 0.5)::FLOAT as avg_sentiment,
                COUNT(*)::INTEGER as entry_count
            FROM UnifiedEntries
            WHERE user_id = $1 
                AND created_at >= NOW() - INTERVAL '${parseInt(days)} days'
            GROUP BY DATE(created_at)
            ORDER BY date ASC`,
            [userId]
        );
        
        // CBT distortion frequency - handle NULL cbt_distortions
        const cbtFrequency = await pool.query(
            `SELECT 
                distortion->>'type' as distortion_type,
                distortion->>'description' as description,
                COUNT(*)::INTEGER as frequency
            FROM UnifiedEntries,
                 jsonb_array_elements(cbt_distortions) as distortion
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '${parseInt(days)} days'
                AND cbt_distortions IS NOT NULL
            GROUP BY distortion->>'type', distortion->>'description'
            ORDER BY frequency DESC`,
            [userId]
        );
        
        // Emotion distribution - handle NULL emotion_tags
        const emotionDist = await pool.query(
            `SELECT 
                UNNEST(emotion_tags) as emotion,
                COUNT(*)::INTEGER as count
            FROM UnifiedEntries
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '${parseInt(days)} days'
                AND emotion_tags IS NOT NULL
                AND array_length(emotion_tags, 1) > 0
            GROUP BY emotion
            ORDER BY count DESC
            LIMIT 10`,
            [userId]
        );
        
        res.json({
            sentimentTimeline: sentimentTimeline.rows.map(row => ({
                ...row,
                date: row.date ? new Date(row.date).toISOString().split('.')[0] + 'Z' : new Date().toISOString().split('.')[0] + 'Z'
            })),
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
 * Get personalized clinical insights for a user
 */
exports.getInsights = async (req, res) => {
    const { userId } = req.query;
    
    if (!userId) {
        return res.status(400).json({ error: 'userId is required' });
    }
    
    try {
        // 1. Overall stats (30 days)
        const stats = await pool.query(
            `SELECT 
                COUNT(*)::INTEGER as total_entries,
                COALESCE(AVG(sentiment_score), 0.5)::FLOAT as avg_sentiment,
                STDDEV(sentiment_score)::FLOAT as mood_stability,
                COUNT(CASE WHEN sentiment = 'positive' THEN 1 END)::INTEGER as positive_count,
                COUNT(CASE WHEN sentiment = 'negative' THEN 1 END)::INTEGER as negative_count
            FROM UnifiedEntries
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '30 days'`,
            [userId]
        );
        
        // 2. Correlation: Mood vs Steps
        const correlation = await pool.query(
            `WITH DailyMood AS (
                SELECT DATE(created_at) as date, AVG(sentiment_score) as mood
                FROM UnifiedEntries
                WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '30 days'
                GROUP BY DATE(created_at)
            ),
            DailyActivity AS (
                SELECT DATE(created_at) as date, SUM(steps) as steps
                FROM DailyMetrics
                WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '30 days'
                GROUP BY DATE(created_at)
            )
            SELECT 
                CORR(m.mood, a.steps)::FLOAT as correlation_coefficient,
                AVG(CASE WHEN a.steps > 5000 THEN m.mood END)::FLOAT as mood_high_activity,
                AVG(CASE WHEN a.steps <= 5000 THEN m.mood END)::FLOAT as mood_low_activity
            FROM DailyMood m
            JOIN DailyActivity a ON m.date = a.date`,
            [userId]
        );

        // 3. Time of Day Analysis
        const timeOfDay = await pool.query(
            `SELECT 
                time_of_day,
                AVG(sentiment_score)::FLOAT as avg_sentiment,
                COUNT(*)::INTEGER as frequency
            FROM UnifiedEntries
            WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '30 days'
            GROUP BY time_of_day
            ORDER BY avg_sentiment DESC`,
            [userId]
        );
        
        // 4. Most common CBT distortions
        const topDistortions = await pool.query(
            `SELECT 
                distortion->>'type' as distortion_type,
                distortion->>'description' as description,
                COUNT(*)::INTEGER as frequency
            FROM UnifiedEntries,
                 jsonb_array_elements(cbt_distortions) as distortion
            WHERE user_id = $1
                AND created_at >= NOW() - INTERVAL '30 days'
                AND cbt_distortions IS NOT NULL
            GROUP BY distortion->>'type', distortion->>'description'
            ORDER BY frequency DESC
            LIMIT 3`,
            [userId]
        );
        
        // 5. Comparison
        const comparison = await pool.query(
            `SELECT 
                (SELECT AVG(sentiment_score) FROM UnifiedEntries WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '7 days') as this_week,
                (SELECT AVG(sentiment_score) FROM UnifiedEntries WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '14 days' AND created_at < NOW() - INTERVAL '7 days') as last_week`,
            [userId]
        );
        
        const overview = stats.rows[0] || {};
        const corrData = correlation.rows[0] || {};
        const thisWeek = parseFloat(comparison.rows[0]?.this_week || 0.5);
        const lastWeek = parseFloat(comparison.rows[0]?.last_week || 0.5);
        
        // Generate Dynamic AI Recommendation
        let recommendation = "Keep tracking your journey to unlock more personalized insights.";
        if (corrData.correlation_coefficient > 0.3) {
            recommendation = "We noticed a strong link between your physical activity and mood. On days you walk more, you feel significantly more positive!";
        } else if (overview.mood_stability > 0.3) {
            recommendation = "Your mood has been quite variable lately. Deep breathing exercises or guided journaling might help find some balance.";
        } else if (timeOfDay.rows.length > 0 && timeOfDay.rows[timeOfDay.rows.length - 1].avg_sentiment < 0.4) {
            const worstTime = timeOfDay.rows[timeOfDay.rows.length - 1].time_of_day;
            recommendation = `You tend to feel more anxious during the ${worstTime}. Consider scheduling a short mindfulness break during this time.`;
        }

        res.json({
            overview: {
                total_entries: parseInt(overview.total_entries) || 0,
                avg_sentiment: parseFloat(overview.avg_sentiment) || 0.5,
                positive_count: parseInt(overview.positive_count) || 0,
                negative_count: parseInt(overview.negative_count) || 0,
                mood_stability: 1.0 - Math.min(parseFloat(overview.mood_stability || 0), 1.0) // Stability is inverse of volatility
            },
            correlations: {
                mood_activity_corr: parseFloat(corrData.correlation_coefficient) || 0,
                mood_boost_pct: corrData.mood_high_activity && corrData.mood_low_activity ? 
                    ((corrData.mood_high_activity - corrData.mood_low_activity) / corrData.mood_low_activity * 100).toFixed(1) : 0
            },
            timeOfDayAnalysis: timeOfDay.rows,
            topDistortions: topDistortions.rows,
            recommendation: recommendation,
            weeklyComparison: {
                thisWeek: thisWeek,
                lastWeek: lastWeek,
                improvement: lastWeek !== 0 ? parseFloat(((thisWeek - lastWeek) / lastWeek * 100).toFixed(1)) : 0,
                isImproving: thisWeek > lastWeek
            }
        });
    } catch (error) {
        console.error('Error fetching insights:', error);
        res.status(500).json({ error: 'Failed to fetch insights', details: error.message });
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
