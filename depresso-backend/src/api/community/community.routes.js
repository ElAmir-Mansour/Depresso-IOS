const express = require('express');
const router = express.Router();
const controller = require('./community.controller');

router.get('/posts', controller.getAllPosts);
router.post('/posts', controller.createPost);
router.post('/posts/:postId/like', controller.likePost);
router.delete('/posts/:postId/like', controller.unlikePost);
router.get('/posts/liked', controller.getLikedPosts); // NEW: Get liked posts

module.exports = router;
