const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');

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

app.use(cors());
app.use(bodyParser.json());

app.get('/', (req, res) => {
    res.send('Depresso Backend is running.');
});

// Serve the dashboard
app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, '../dashboard.html'));
});

// API Routes
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/metrics', metricsRoutes);
app.use('/api/v1/community', communityRoutes);
app.use('/api/v1/assessments', assessmentRoutes);
app.use('/api/v1/journal', journalRoutes);
app.use('/api/v1/wellness', wellnessRoutes);
app.use('/api/v1/support', supportRoutes);
app.use('/api/v1/research', researchRoutes);
app.use('/api/v1/debug', debugRoutes);
app.use('/api/v1/analysis', analysisRoutes);

module.exports = app;
