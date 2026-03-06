const express = require('express');
const router = express.Router();
const controller = require('./community.controller');

router.get('/posts', controller.getAllPosts);
router.get('/trending', controller.getTrendingPosts);
router.get('/stats', controller.getCommunityStats);
router.post('/posts', controller.createPost);
router.post('/posts/:postId/like', controller.likePost);
router.delete('/posts/:postId/like', controller.unlikePost);
router.get('/posts/liked', controller.getLikedPosts); // NEW: Get liked posts
router.get('/posts/:postId/comments', controller.getComments); // NEW: Get comments for post
router.post('/posts/:postId/comments', controller.addComment); // NEW: Add comment to post

module.exports = router;
