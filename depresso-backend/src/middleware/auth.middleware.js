const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'depresso-secret-key-change-in-production';

/**
 * Middleware to authenticate requests using JWT tokens
 * Expects: Authorization: Bearer <token>
 * Sets: req.userId (from verified token)
 */
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.userId = decoded.userId;
        req.appleUserId = decoded.appleUserId;
        next();
    } catch (error) {
        return res.status(403).json({ error: 'Invalid or expired token' });
    }
};

/**
 * Optional auth - sets userId if token present, but doesn't require it
 * Useful for endpoints that work both authenticated and anonymous
 */
const optionalAuth = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
        try {
            const decoded = jwt.verify(token, JWT_SECRET);
            req.userId = decoded.userId;
            req.appleUserId = decoded.appleUserId;
        } catch (error) {
            // Token invalid but don't fail - just proceed without userId
        }
    }
    next();
};

/**
 * Generate JWT token for authenticated user
 */
const generateToken = (userId, appleUserId) => {
    return jwt.sign(
        { userId, appleUserId },
        JWT_SECRET,
        { expiresIn: '30d' } // 30 days validity
    );
};

module.exports = {
    authenticateToken,
    optionalAuth,
    generateToken,
    JWT_SECRET
};
