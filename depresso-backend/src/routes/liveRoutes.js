const express = require('express');
const router = express.Router();
const liveAiService = require('../services/liveAiService');

// This file configures the WebSocket upgrade in the main Express app.
// Note: Actual WebSocket routing happens at the server level (app.js).

module.exports = router;
