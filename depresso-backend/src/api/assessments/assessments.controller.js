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
        // Fetch unique assessment dates for user, ordered by date descending
        const result = await pool.query(
            'SELECT DISTINCT created_at::date as assessment_date FROM Assessments WHERE user_id = $1 ORDER BY assessment_date DESC',
            [userId]
        );

        const assessments = result.rows;

        if (assessments.length === 0) {
            return res.json({ currentStreak: 0, longestStreak: 0 });
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Calculate current streak
        let currentStreak = 0;
        const mostRecentDate = new Date(assessments[0].assessment_date);
        mostRecentDate.setHours(0, 0, 0, 0);
        
        // Use a more relaxed check for "today or yesterday" to account for timezone shifts
        // diffToToday will be:
        // 0 if assessment is today
        // 1 if assessment was yesterday
        // -1 if assessment is "tomorrow" (user is ahead of server)
        const diffToToday = Math.floor((today - mostRecentDate) / (1000 * 60 * 60 * 24));

        // If most recent is today, yesterday, or even "tomorrow" (TZ shift), the streak is alive
        if (diffToToday <= 1) {
            currentStreak = 1;
            for (let i = 1; i < assessments.length; i++) {
                const prevDate = new Date(assessments[i-1].assessment_date);
                const currDate = new Date(assessments[i].assessment_date);
                prevDate.setHours(0, 0, 0, 0);
                currDate.setHours(0, 0, 0, 0);
                
                const daysBetween = Math.floor((prevDate - currDate) / (1000 * 60 * 60 * 24));
                
                if (daysBetween === 1) {
                    currentStreak++;
                } else if (daysBetween === 0) {
                    continue; // Same day, keep going
                } else {
                    break; // Gap found
                }
            }
        } else {
            currentStreak = 0; // Streak broken
        }

        // Calculate longest streak
        let longestStreak = 0;
        let tempStreak = 1;
        
        for (let i = 1; i < assessments.length; i++) {
            const prevDate = new Date(assessments[i-1].assessment_date);
            const currDate = new Date(assessments[i].assessment_date);
            prevDate.setHours(0, 0, 0, 0);
            currDate.setHours(0, 0, 0, 0);
            
            const daysBetween = Math.floor((prevDate - currDate) / (1000 * 60 * 60 * 24));
            
            if (daysBetween === 1) {
                tempStreak++;
            } else {
                longestStreak = Math.max(longestStreak, tempStreak);
                tempStreak = 1;
            }
        }
        longestStreak = Math.max(longestStreak, tempStreak);

        // Edge case: if currentStreak is higher than any historical streak
        longestStreak = Math.max(longestStreak, currentStreak);

        console.log(`🔥 Streak for ${userId}: Current=${currentStreak}, Longest=${longestStreak}`);
        res.json({ currentStreak, longestStreak });
    } catch (error) {
        console.error('Error calculating streak:', error);
        res.status(500).send('Server error');
    }
};