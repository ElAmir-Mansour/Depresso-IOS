const express = require('express');
const router = express.Router();
const controller = require('./metrics.controller');
const { validateUserOwnership } = require('../../middleware/authorization.middleware');

router.post('/submit', validateUserOwnership, controller.submitMetrics);

module.exports = router;
