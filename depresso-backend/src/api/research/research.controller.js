const pool = require('../../config/db');

// GET /api/v1/research/stats - Overview KPIs
exports.getStats = async (req, res) => {
    try {
        const stats = await pool.query(`
            SELECT 
                (SELECT COUNT(*) FROM users) as total_users,
                (SELECT COUNT(*) FROM journalentries) as total_entries,
                (SELECT COUNT(*) FROM assessments) as total_assessments,
                (SELECT COUNT(*) FROM aichatmessages) as total_messages,
                (SELECT AVG(sentiment_score) FROM journalentries WHERE sentiment_score IS NOT NULL) as avg_sentiment,
                (SELECT COUNT(*) FROM journalentries WHERE analysis_json->>'risk_flag' = 'true') as risk_flags
        `);
        res.json(stats.rows[0]);
    } catch (error) {
        console.error('Research stats error:', error);
        res.status(500).json({ error: 'Failed to fetch stats' });
    }
};

// GET /api/v1/research/sentiment - Sentiment time series
exports.getSentimentData = async (req, res) => {
    try {
        const { days = 30 } = req.query;
        const result = await pool.query(`
            SELECT 
                DATE(created_at) as date,
                AVG(sentiment_score) as avg_sentiment,
                COUNT(*) as entry_count
            FROM journalentries 
            WHERE sentiment_score IS NOT NULL 
              AND created_at >= NOW() - INTERVAL '${parseInt(days)} days'
            GROUP BY DATE(created_at)
            ORDER BY date ASC
        `);

        // Also get sentiment distribution
        const distribution = await pool.query(`
            SELECT 
                CASE 
                    WHEN sentiment_score < -0.3 THEN 'negative'
                    WHEN sentiment_score > 0.3 THEN 'positive'
                    ELSE 'neutral'
                END as category,
                COUNT(*) as count
            FROM journalentries 
            WHERE sentiment_score IS NOT NULL
            GROUP BY category
        `);

        res.json({
            timeSeries: result.rows,
            distribution: distribution.rows
        });
    } catch (error) {
        console.error('Sentiment data error:', error);
        res.status(500).json({ error: 'Failed to fetch sentiment data' });
    }
};

// GET /api/v1/research/distortions - CBT Distortion frequency
exports.getDistortionsData = async (req, res) => {
    try {
        // Flatten distortions array and count occurrences
        const result = await pool.query(`
            SELECT 
                UNNEST(distortions) as distortion,
                COUNT(*) as count
            FROM journalentries 
            WHERE distortions IS NOT NULL AND array_length(distortions, 1) > 0
            GROUP BY distortion
            ORDER BY count DESC
        `);

        // Time series of distortion counts
        const timeSeries = await pool.query(`
            SELECT 
                DATE(created_at) as date,
                COUNT(*) as entries_with_distortions,
                SUM(array_length(distortions, 1)) as total_distortions
            FROM journalentries 
            WHERE distortions IS NOT NULL AND array_length(distortions, 1) > 0
            GROUP BY DATE(created_at)
            ORDER BY date ASC
        `);

        res.json({
            frequency: result.rows,
            timeSeries: timeSeries.rows
        });
    } catch (error) {
        console.error('Distortions data error:', error);
        res.status(500).json({ error: 'Failed to fetch distortions data' });
    }
};

// GET /api/v1/research/assessments - PHQ-8 stats
exports.getAssessmentsData = async (req, res) => {
    try {
        // Score distribution (PHQ-8 severity levels)
        const distribution = await pool.query(`
            SELECT 
                CASE 
                    WHEN score <= 4 THEN 'Minimal (0-4)'
                    WHEN score <= 9 THEN 'Mild (5-9)'
                    WHEN score <= 14 THEN 'Moderate (10-14)'
                    WHEN score <= 19 THEN 'Moderately Severe (15-19)'
                    ELSE 'Severe (20-24)'
                END as severity,
                COUNT(*) as count,
                AVG(score) as avg_score
            FROM assessments 
            WHERE assessment_type = 'PHQ-8'
            GROUP BY severity
            ORDER BY MIN(score)
        `);

        // Time series
        const timeSeries = await pool.query(`
            SELECT 
                DATE(created_at) as date,
                AVG(score) as avg_score,
                COUNT(*) as assessment_count
            FROM assessments 
            WHERE assessment_type = 'PHQ-8'
            GROUP BY DATE(created_at)
            ORDER BY date ASC
        `);

        res.json({
            distribution: distribution.rows,
            timeSeries: timeSeries.rows
        });
    } catch (error) {
        console.error('Assessments data error:', error);
        res.status(500).json({ error: 'Failed to fetch assessment data' });
    }
};

// GET /api/v1/research/export - CSV Export
exports.exportData = async (req, res) => {
    try {
        const { table = 'journalentries' } = req.query;

        let query;
        switch (table) {
            case 'journalentries':
                query = `SELECT id, created_at, sentiment_score, 
                         analysis_json->>'emotions' as emotions,
                         array_to_string(distortions, ', ') as distortions,
                         LEFT(content, 500) as content_preview
                         FROM journalentries ORDER BY created_at DESC`;
                break;
            case 'assessments':
                query = `SELECT id, user_id, assessment_type, score, created_at 
                         FROM assessments ORDER BY created_at DESC`;
                break;
            case 'users':
                query = `SELECT id, created_at FROM users ORDER BY created_at DESC`;
                break;
            default:
                query = `SELECT * FROM ${table} LIMIT 1000`;
        }

        const result = await pool.query(query);

        // Convert to CSV
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'No data found' });
        }

        const headers = Object.keys(result.rows[0]);
        const csvRows = [headers.join(',')];

        result.rows.forEach(row => {
            const values = headers.map(h => {
                const val = row[h];
                if (val === null) return '';
                if (typeof val === 'string') return `"${val.replace(/"/g, '""')}"`;
                return val;
            });
            csvRows.push(values.join(','));
        });

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename=${table}_export.csv`);
        res.send(csvRows.join('\n'));

    } catch (error) {
        console.error('Export error:', error);
        res.status(500).json({ error: 'Failed to export data' });
    }
};

// GET /api/v1/research/health - HealthKit correlations
exports.getHealthData = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                DATE(created_at) as date,
                AVG(steps) as avg_steps,
                AVG(active_energy) as avg_energy,
                AVG(heart_rate) as avg_heart_rate
            FROM dailymetrics 
            GROUP BY DATE(created_at)
            ORDER BY date ASC
        `);
        res.json(result.rows);
    } catch (error) {
        console.error('Health data error:', error);
        res.status(500).json({ error: 'Failed to fetch health data' });
    }
};

// GET /api/v1/research/engagement - User engagement stats
exports.getEngagementData = async (req, res) => {
    try {
        const tasks = await pool.query(`
            SELECT 
                w.title as task_name,
                COUNT(ut.id) as completions
            FROM wellnesstasks w
            LEFT JOIN usertasks ut ON ut.task_id = w.id AND ut.completed = true
            GROUP BY w.id, w.title
            ORDER BY completions DESC
        `);

        const streaks = await pool.query(`
            SELECT 
                current_streak,
                COUNT(*) as user_count
            FROM usergamification
            GROUP BY current_streak
            ORDER BY current_streak
        `);

        res.json({
            taskCompletions: tasks.rows,
            streakDistribution: streaks.rows
        });
    } catch (error) {
        console.error('Engagement data error:', error);
        res.status(500).json({ error: 'Failed to fetch engagement data' });
    }
};

// GET /api/v1/research/community/stats - Community & Engagement
exports.getCommunityStats = async (req, res) => {
    try {
        // Overview
        const overview = await pool.query(`
            SELECT
                (SELECT COUNT(*) FROM CommunityPosts) as total_posts,
                (SELECT COUNT(*) FROM PostComments) as total_comments,
                (SELECT SUM(like_count) FROM CommunityPosts) as total_likes,
                (SELECT COUNT(*) FROM ContentReports WHERE status = 'pending') as pending_reports
        `);

        // Trending Topics (based on tags or categories)
        const trending = await pool.query(`
            SELECT category, COUNT(*) as count, SUM(view_count) as views
            FROM CommunityPosts
            GROUP BY category
            ORDER BY views DESC
            LIMIT 5
        `);

        // Engagement over time
        const timeSeries = await pool.query(`
            SELECT DATE(created_at) as date, COUNT(*) as posts, SUM(view_count) as views
            FROM CommunityPosts
            WHERE created_at >= NOW() - INTERVAL '30 days'
            GROUP BY DATE(created_at)
            ORDER BY date ASC
        `);

        res.json({
            overview: overview.rows[0],
            trending: trending.rows,
            timeSeries: timeSeries.rows
        });
    } catch (error) {
        console.error('Community stats error:', error);
        res.status(500).send('Server Error');
    }
};

// GET /api/v1/research/moderation/pending - Queue
exports.getModerationQueue = async (req, res) => {
    try {
        // Fetch flagged posts and pending reports
        // For simplicity, we'll focus on Posts with status 'flagged' or 'pending'
        const flaggedPosts = await pool.query(`
            SELECT id, title, content, user_id, moderation_status, created_at, 'post' as type
            FROM CommunityPosts
            WHERE moderation_status IN ('flagged', 'pending')
            ORDER BY created_at ASC
            LIMIT 50
        `);

        res.json(flaggedPosts.rows);
    } catch (error) {
        console.error('Moderation queue error:', error);
        res.status(500).send('Server Error');
    }
};

// POST /api/v1/research/moderation/action
exports.moderationAction = async (req, res) => {
    const { contentId, contentType, action } = req.body; // action: 'approve', 'reject', 'delete'

    try {
        let status = 'approved';
        if (action === 'reject') status = 'rejected';
        if (action === 'delete') status = 'deleted'; // Logic to delete or soft-delete

        if (contentType === 'post') {
            await pool.query(
                `UPDATE CommunityPosts SET moderation_status = $1 WHERE id = $2`,
                [status, contentId]
            );
        }

        res.json({ success: true, status });
    } catch (error) {
        console.error('Moderation action error:', error);
        res.status(500).send('Server Error');
    }
};

// POST /api/v1/research/entries
exports.submitEntry = async (req, res) => {
    const { userId, promptId, content, sentimentLabel, tags, metadata } = req.body;

    if (!userId || !content) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    try {
        const result = await pool.query(
            `INSERT INTO ResearchEntries (user_id, prompt_id, content, sentiment_label, tags, metadata)
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING id`,
            [userId, promptId, content, sentimentLabel, tags, metadata]
        );

        res.status(201).json({
            status: 'success',
            id: result.rows[0].id,
            message: 'Research entry recorded.'
        });
    } catch (error) {
        console.error('Submit Entry error:', error);
        res.status(500).json({ error: 'Failed to submit entry' });
    }
};

// GET /api/v1/research/entries - Get all research entries
exports.getEntries = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                id, user_id, prompt_id, content, sentiment_label, tags, metadata, created_at
            FROM ResearchEntries
            ORDER BY created_at DESC
            LIMIT 1000
        `);
        res.json(result.rows);
    } catch (error) {
        console.error('Get entries error:', error);
        res.status(500).json({ error: 'Failed to fetch entries' });
    }
};
