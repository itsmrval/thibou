const { log } = require('../utils/logger.util');
const { verifyJWT } = require('../utils/auth.util');
const User = require('../models/user.model');

const tokenCheck = async (req) => {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) throw { message: 'Missing authorization token.', statusCode: 403 };

    try {
        const decoded = verifyJWT(token);
        req.user = decoded.user;
    } catch (err) {
        console.log(err)
        throw { message: 'Invalid or expired token.', statusCode: 401 };
    }
};

const hasScope = (userScopes, requiredScopes) => 
    requiredScopes.some(scope => 
        userScopes.includes(scope) || 
        userScopes.includes(scope.replace(':read', ':write')) ||
        userScopes.includes(scope.replace(/:.+$/, ':admin'))
    );

const authMiddleware = (requiredScopes) => async (req, res, next) => {
    try {
        const requestedUrl = `${req.method} ${req.originalUrl}`;
        await tokenCheck(req);
        
        if (requiredScopes && requiredScopes.length > 0) {
            if (!hasScope(req.user?.scopes || [], requiredScopes)) {
                throw { message: `Insufficient permissions for user ${req.user.id} on ${requestedUrl}`, statusCode: 403 };
            }
        }
        
        
        next();
    } catch (error) {
        log(error.message, 'error');
        res.status(error.statusCode || 500).json({ message: error.message });
    }
};

module.exports = { authMiddleware, hasScope, tokenCheck };
