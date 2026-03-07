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
 * Checks both internal UUID and Apple User ID for robust ownership validation
 */
const validateResourceOwnership = (resourceType, idParam = 'id') => {
    return async (req, res, next) => {
        if (!req.userId) {
            // No auth - skip validation or let authenticateToken handle it
            return next();
        }

        const pool = require('../config/db');
        const resourceId = req.params[idParam];
        
        try {
            let query;
            switch(resourceType) {
                case 'journal':
                    // Join with Users to check against both IDs
                    query = `
                        SELECT je.user_id, u.apple_user_id 
                        FROM JournalEntries je
                        JOIN Users u ON je.user_id = u.id
                        WHERE je.id = $1
                    `;
                    break;
                case 'post':
                    query = `
                        SELECT cp.user_id, u.apple_user_id 
                        FROM CommunityPosts cp
                        JOIN Users u ON cp.user_id = u.id
                        WHERE cp.id = $1
                    `;
                    break;
                default:
                    return next();
            }
            
            const result = await pool.query(query, [resourceId]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ error: 'Resource not found' });
            }
            
            const row = result.rows[0];
            const isOwner = row.user_id === req.userId || 
                          (req.appleUserId && row.apple_user_id === req.appleUserId);
            
            if (!isOwner) {
                console.warn(`🔒 Access denied for user ${req.userId} to ${resourceType} ${resourceId}`);
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
