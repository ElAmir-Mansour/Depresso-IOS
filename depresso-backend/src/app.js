const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const rateLimit = require('express-rate-limit');
const { optionalAuth } = require('./middleware/auth.middleware');

const userRoutes = require('./api/users/users.routes');
const metricsRoutes = require('./api/metrics/metrics.routes');
const communityRoutes = require('./api/community/community.routes');
const assessmentRoutes = require('./api/assessments/assessments.routes');
const journalRoutes = require('./api/journal/journal.routes');
const wellnessRoutes = require('./api/wellness/wellness.routes');
const supportRoutes = require('./api/support/support.routes');
const researchRoutes = require('./api/research/research.routes');
const debugRoutes = require('./api/debug/debug.routes');
const analysisRoutes = require('./api/analysis/analysis.routes');

const app = express();

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 200, // limit each IP to 200 requests per window
    message: 'Too many requests from this IP, please try again later'
});

app.use(cors());
app.use(bodyParser.json());
app.use('/api/v1/', limiter);

app.get('/', (req, res) => {
    res.send('Depresso Backend is running.');
});

// Serve the dashboard
app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, '../dashboard.html'));
});

// Public routes (no auth required)
app.use('/api/v1/users', userRoutes); // Auth endpoints are public

// Protected routes (require authentication)
app.use('/api/v1/metrics', optionalAuth, metricsRoutes);
app.use('/api/v1/community', optionalAuth, communityRoutes);
app.use('/api/v1/assessments', optionalAuth, assessmentRoutes);
app.use('/api/v1/journal', optionalAuth, journalRoutes);
app.use('/api/v1/wellness', optionalAuth, wellnessRoutes);
app.use('/api/v1/support', optionalAuth, supportRoutes);
app.use('/api/v1/research', optionalAuth, researchRoutes);
app.use('/api/v1/debug', optionalAuth, debugRoutes);
app.use('/api/v1/analysis', optionalAuth, analysisRoutes);

module.exports = app;
