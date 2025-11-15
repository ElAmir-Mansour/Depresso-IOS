const express = require('express');
const router = express.Router();
const controller = require('./users.controller');

router.post('/register', controller.register);
router.get('/profile/:userId', controller.getProfile); // NEW: Get profile
router.put('/profile/:userId', controller.updateProfile); // NEW: Update profile

module.exports = router;
