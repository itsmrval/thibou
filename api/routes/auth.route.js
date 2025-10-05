
const router = require('express').Router();
const { check, validationResult } = require('express-validator');
const { ratelimitMiddleware } = require('../middlewares/ratelimit.middleware');
const { createUser, loginUser } = require('../controllers/user.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const authUtil = require('../utils/auth.util');
const { log } = require('../utils/logger.util');
const User = require('../models/user.model');

router.post('/register', ratelimitMiddleware(5), [
    check('name').isString().isLength({ min: 2, max: 100 }),
    check('email').isEmail(),
    check('password').optional().isString().isLength({ min: 6, max: 50 }) 
], async (req, res) => {
    const bodyError = validationResult(req);
    if (!bodyError.isEmpty()) {
        return res.status(400).json({ errors: bodyError.array() });
    }

    try {
        let {user, token} = await createUser(req.body);
        
        return res.status(201).json({ 
            message: 'User registered successfully', 
            user, 
            token,
            tokenType: 'user'
        });
    } catch (error) {
        log(error, 'error');

        if (error.message === 'User already exists') {
            return res.status(400).json({ message: 'User already exists' });
        }
        return res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/login', ratelimitMiddleware(10), [
    check('email').isEmail(),
    check('password').isString().isLength({ min: 6, max: 50 }) 
], async (req, res) => {
    const bodyError = validationResult(req);
    if (!bodyError.isEmpty()) {
        return res.status(400).json({ errors: bodyError.array() });
    }

    try {
        let {user, token} = await loginUser(req.body);
        
        return res.status(200).json({ 
            message: 'User logged in', 
            user, 
            token,
            tokenType: 'user'
        });
    } catch (error) {
        log(error, 'error');
        if (error.message === 'User not found' || error.message === 'Invalid password') {
            return res.status(401).json({ message: 'Invalid username or password' });
        } 
        return res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/system', ratelimitMiddleware(5), [
    check('key').isString().notEmpty()
], async (req, res) => {
    const bodyError = validationResult(req);
    if (!bodyError.isEmpty()) {
        return res.status(400).json({ errors: bodyError.array() });
    }

    try {
        const { key } = req.body;
        
        if (key !== process.env.SYSTEM_KEY) {
            return res.status(401).json({ message: 'Invalid system key' });
        }

        const token = authUtil.generateSystemToken();
        
        return res.status(200).json({
            message: 'System token generated successfully',
            token
        });
    } catch (error) {
        log(`System authentication error: ${error.message}`, 'error');
        return res.status(500).json({ message: 'Internal server error' });
    }
});


router.get('/me', authMiddleware(['user:own:read']), ratelimitMiddleware(30), async (req, res) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'Authorization header required' });
        }

        const token = authHeader.replace('Bearer ', '');
        const decoded = authUtil.verifyJWT(token);


        const user = await User.findById(decoded.user.id).select('+password');
        if (!user) {
            return res.status(401).json({ error: 'User not found' });
        }

        res.json({
            user: user.toFullJSON(),
            tokenInfo: {
                type: decoded.type || 'main',
                issuedAt: new Date(decoded.iat * 1000).toISOString(),
                expiresAt: new Date(decoded.exp * 1000).toISOString(),
                issuer: decoded.iss
            }
        });

    } catch (error) {
        res.status(401).json({
            error: 'Invalid token',
            details: error.message
        });
    }
});

module.exports = router;