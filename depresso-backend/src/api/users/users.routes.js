const express = require('express');
const router = express.Router();
const controller = require('./users.controller');

router.post('/register', controller.register);
router.get('/profile/:userId', controller.getProfile); // NEW: Get profile
router.put('/profile/:userId', controller.updateProfile); // NEW: Update profile
router.delete('/:userId', controller.deleteAccount); // NEW: Delete account

router.post('/auth/apple', controller.appleLogin); // NEW: Apple Sign In
router.post('/auth/apple/link', controller.linkAppleAccount); // NEW: Link Account

module.exports = router;
