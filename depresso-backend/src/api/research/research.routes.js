const express = require('express');
const router = express.Router();
const researchController = require('./research.controller');

// Overview stats
router.get('/stats', researchController.getStats);

// Sentiment analysis data
router.get('/sentiment', researchController.getSentimentData);

// CBT Distortions data
router.get('/distortions', researchController.getDistortionsData);

// PHQ-8 Assessment data
router.get('/assessments', researchController.getAssessmentsData);

// HealthKit correlations
router.get('/health', researchController.getHealthData);

// User engagement data
router.get('/engagement', researchController.getEngagementData);

// CSV Export
router.get('/export', researchController.exportData);

// Community & Engagement
router.get('/community/stats', researchController.getCommunityStats);

// Moderation
router.get('/moderation/pending', researchController.getModerationQueue);
router.post('/moderation/action', researchController.moderationAction);

// Data Submission
router.post('/entries', researchController.submitEntry);

// Get all research entries (for dashboard)
router.get('/entries', researchController.getEntries);

module.exports = router;

