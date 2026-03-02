/**
 * Middleware to validate that the authenticated user owns the resource
 * Use after authenticateToken middleware
 */

/**
 * Check if userId from token matches userId in request
 */
const validateUserOwnership = (req, res, next) => {
    const requestUserId = req.query.userId || req.body.userId || req.params.userId;
    
    // If no userId in request, let controller handle validation
    if (!requestUserId) {
        return next();
    }
    
    // If authenticated, verify ownership
    if (req.userId && req.userId !== requestUserId) {
        return res.status(403).json({ 
            error: 'Forbidden: Cannot access another user\'s data' 
        });
    }
    
    next();
};

/**
 * Check if resource belongs to authenticated user (by query lookup)
 */
const validateResourceOwnership = (resourceType, idParam = 'id') => {
    return async (req, res, next) => {
        if (!req.userId) {
            // No auth - will be handled by authenticateToken
            return next();
        }

        const pool = require('../config/db');
        const resourceId = req.params[idParam];
        
        try {
            let query;
            switch(resourceType) {
                case 'journal':
                    query = 'SELECT user_id FROM JournalEntries WHERE id = $1';
                    break;
                case 'post':
                    query = 'SELECT user_id FROM CommunityPosts WHERE id = $1';
                    break;
                default:
                    return next();
            }
            
            const result = await pool.query(query, [resourceId]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ error: 'Resource not found' });
            }
            
            if (result.rows[0].user_id !== req.userId) {
                return res.status(403).json({ error: 'Forbidden' });
            }
            
            next();
        } catch (error) {
            console.error('Ownership validation error:', error);
            res.status(500).json({ error: 'Server error' });
        }
    };
};

module.exports = {
    validateUserOwnership,
    validateResourceOwnership
};
