const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const defaultAdminScopes = ['user:admin', 'sso:admin', 'villager:admin', 'villager:write', 'villager:read', 'fish:admin', 'bug:admin', 'bug:write'];
const defaultUserScopes = ['user:own:read', 'user:own:write', 'user:read', 'sso:own:read', 'sso:own:write', 'villager:read'];


const hashPassword = async (password) => {
    try {
        return await argon2.hash(password);
    } catch (error) {
        throw new Error(error);
    }
}

const checkHash = async (password, hash) => {
    try {
        return await argon2.verify(hash, password);
    } catch (error) {
        throw new Error(error);
    }
}

const generateJWT = (user) => {
    if (!user) {
        throw new Error('User is required');
    }
    const isAdmin = user.role === 'admin';
    user.scopes = isAdmin ? defaultAdminScopes : defaultUserScopes;
    const payload = {
        user: {
            id: user._id,
            email: user.email,
            name: user.name,
            scopes: user.scopes,
            role: user.role
        },
        iat: Math.floor(Date.now() / 1000),
        iss: 'auth-api',
        type: 'main'
    };
    
    return jwt.sign(payload, process.env.JWT_SECRET, { 
        expiresIn: process.env.JWT_DURATION,
        jwtid: crypto.randomUUID()
    });
}


const verifyJWT = (token) => {
    try {
        return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
        throw new Error(error);
    }
}


const isRecentToken = (tokenPayload, maxAgeMinutes = 10) => {
    const now = Math.floor(Date.now() / 1000);
    const tokenIssuedAt = tokenPayload.iat;
    const maxAge = maxAgeMinutes * 60; 
    
    return (now - tokenIssuedAt) <= maxAge;
}

const generateSystemToken = () => {
    const systemScopes = ['villager:admin', 'bug:admin', 'fish:admin'];
    const payload = {
        user: {
            id: 'system-token',
            email: 'system@local.dev',
            name: 'System Token',
            scopes: systemScopes,
            role: 'system'
        },
        iat: Math.floor(Date.now() / 1000),
        iss: 'auth-api',
        type: 'system'
    };

    return jwt.sign(payload, process.env.JWT_SECRET, {
        expiresIn: '1h',
        jwtid: 'system-token'
    });
}

module.exports = {
    hashPassword,
    checkHash,
    generateJWT,
    verifyJWT,
    isRecentToken,
    generateSystemToken,
    defaultAdminScopes
};
