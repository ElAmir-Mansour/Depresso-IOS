const pool = require('../../config/db');

exports.submitAssessment = async (req, res) => {
    const { userId, assessmentType, score, answers } = req.body;

    console.log('📊 Submitting assessment:', { userId, assessmentType, score, answersLength: answers?.length });

    if (!userId || !assessmentType || score === undefined) {
        console.error('❌ Missing required fields');
        return res.status(400).json({ error: 'userId, assessmentType, and score are required.' });
    }

    try {
        const result = await pool.query(
            'INSERT INTO Assessments (user_id, assessment_type, score, answers) VALUES ($1, $2, $3, $4) RETURNING *',
            [userId, assessmentType, score, JSON.stringify(answers) || null]
        );
        console.log('✅ Assessment submitted successfully:', result.rows[0].id);
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('❌ Error submitting assessment:', error.message);
        console.error('   Stack:', error.stack);
        res.status(500).json({ error: 'Server error', message: error.message });
    }
};

// NEW: Calculate user's streak from assessments
exports.getStreak = async (req, res) => {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    try {
        // Fetch all assessments for user, ordered by date
        const result = await pool.query(
            'SELECT created_at::date as assessment_date FROM Assessments WHERE user_id = $1 ORDER BY created_at DESC',
            [userId]
        );

        const assessments = result.rows;

        if (assessments.length === 0) {
            return res.json({ currentStreak: 0, longestStreak: 0 });
        }

        // Calculate current streak
        let currentStreak = 0;
        let longestStreak = 0;
        let tempStreak = 0;
        let lastDate = null;

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        for (let i = 0; i < assessments.length; i++) {
            const assessmentDate = new Date(assessments[i].assessment_date);
            assessmentDate.setHours(0, 0, 0, 0);

            if (lastDate === null) {
                // First assessment
                const daysDiff = Math.floor((today - assessmentDate) / (1000 * 60 * 60 * 24));
                
                if (daysDiff === 0 || daysDiff === 1) {
                    // Assessment is today or yesterday - streak is active
                    currentStreak = 1;
                    tempStreak = 1;
                } else {
                    // Streak is broken - too old
                    currentStreak = 0;
                }
                lastDate = assessmentDate;
            } else {
                // Check consecutive days
                const daysBetween = Math.floor((lastDate - assessmentDate) / (1000 * 60 * 60 * 24));
                
                if (daysBetween === 1) {
                    // Consecutive day
                    tempStreak++;
                    if (currentStreak > 0) {
                        currentStreak++;
                    }
                } else if (daysBetween > 1) {
                    // Gap found - update longest if needed
                    longestStreak = Math.max(longestStreak, tempStreak);
                    tempStreak = 1;
                } else if (daysBetween === 0) {
                    // Same day - skip
                    continue;
                }
                
                lastDate = assessmentDate;
            }
        }

        // Final update for longest streak
        longestStreak = Math.max(longestStreak, tempStreak, currentStreak);

        res.json({ currentStreak, longestStreak });
    } catch (error) {
        console.error('Error calculating streak:', error);
        res.status(500).send('Server error');
    }
};