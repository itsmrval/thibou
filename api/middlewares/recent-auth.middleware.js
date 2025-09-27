const { log } = require('../utils/logger.util');
const { verifyJWT, isRecentToken } = require('../utils/auth.util');
const { hasScope } = require('./auth.middleware');

const recentAuthMiddleware = (maxAgeMinutes = 10, requiredScopes = []) => (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        
        if (!token) {
            return res.status(403).json({ 
                message: 'Missing authorization token.',
                requiresRecentAuth: true
            });
        }

        const decoded = verifyJWT(token);
        
        if (!isRecentToken(decoded, maxAgeMinutes)) {
            return res.status(403).json({ 
                message: 'Token is too old. Please verify your identity again.',
                requiresRecentAuth: true,
                field: 'recentAuth'
            });
        }

        if (requiredScopes.length > 0 && !hasScope(decoded.user?.scopes || [], requiredScopes)) {
            const requestedUrl = `${req.method} ${req.originalUrl}`;
            return res.status(403).json({ 
                message: `Insufficient permissions for user ${decoded.user.id} on ${requestedUrl}`,
                requiresRecentAuth: true
            });
        }

        req.user = decoded.user;
        req.tokenPayload = decoded;
        next();
    } catch (error) {
        log(`Recent auth middleware error: ${error.message}`, 'error');
        res.status(401).json({ 
            message: 'Invalid or expired token.',
            requiresRecentAuth: true
        });
    }
};

module.exports = { recentAuthMiddleware };