const express = require('express');
const router = express.Router();
const controller = require('./users.controller');
const { authenticateToken } = require('../../middleware/auth.middleware');
const { validateUserOwnership } = require('../../middleware/authorization.middleware');

router.post('/register', controller.register);
router.get('/profile/:userId', authenticateToken, validateUserOwnership, controller.getProfile);
router.put('/profile/:userId', authenticateToken, validateUserOwnership, controller.updateProfile);
router.delete('/:userId', authenticateToken, validateUserOwnership, controller.deleteAccount);

router.post('/auth/apple', controller.appleLogin);
router.post('/auth/apple/link', controller.linkAppleAccount);

module.exports = router;
