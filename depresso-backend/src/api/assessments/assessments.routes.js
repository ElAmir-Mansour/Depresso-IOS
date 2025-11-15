const express = require('express');
const router = express.Router();
const controller = require('./assessments.controller');

router.post('/', controller.submitAssessment);
router.get('/streak', controller.getStreak); // NEW: Get user's streak

module.exports = router;
