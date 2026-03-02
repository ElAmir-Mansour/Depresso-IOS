const express = require('express');
const router = express.Router();
const controller = require('./journal.controller');
const { validateUserOwnership, validateResourceOwnership } = require('../../middleware/authorization.middleware');

// Journal Entries
router.post('/entries', validateUserOwnership, controller.createEntry);
router.get('/entries', validateUserOwnership, controller.getEntriesForUser);

// AI Chat Messages
router.post('/entries/:entryId/messages', validateResourceOwnership('journal', 'entryId'), controller.addMessageToEntry);
router.get('/entries/:entryId/messages', controller.getMessagesForEntry);

module.exports = router;
