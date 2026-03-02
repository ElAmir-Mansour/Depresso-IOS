// depresso-backend/src/api/analysis/analysis.routes.js
const express = require('express');
const router = express.Router();
const analysisController = require('./analysis.controller');

// Submit entry for analysis
router.post('/submit', analysisController.submitEntry);

// Get trends and patterns
router.get('/trends', analysisController.getTrends);

// Get personalized insights
router.get('/insights', analysisController.getInsights);

// Get all analyzed entries
router.get('/entries', analysisController.getEntries);

module.exports = router;
