const router = require('express').Router();
const { check, validationResult } = require('express-validator');
const { ratelimitMiddleware } = require('../middlewares/ratelimit.middleware');
const { ssoAuth, linkSSOProvider, unlinkSSOProvider } = require('../controllers/sso.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { recentAuthMiddleware } = require('../middlewares/recent-auth.middleware');
const { generateLoginUrl } = require('../utils/sso.util');
const { log } = require('../utils/logger.util');

router.get('/:provider', ratelimitMiddleware(20), [
    check('provider').isIn(['apple']).withMessage('Only Apple SSO is currently supported')
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    try {
        const { provider } = req.params;
        const { redirect_uri, state, platform = 'principal' } = req.query;
        
        if (!redirect_uri) {
            return res.status(400).json({ message: 'redirect_uri query parameter is required' });
        }

        const loginData = generateLoginUrl(provider, redirect_uri, state, platform);
        
        return res.status(200).json({
            provider,
            platform,
            loginUrl: loginData.url,
            state: loginData.state,
            clientId: loginData.clientId,
            redirectUri: redirect_uri
        });
    } catch (error) {
        log(error, 'error');
        
        if (error.message === 'Unsupported provider') {
            return res.status(400).json({ message: 'Unsupported SSO provider' });
        }
        
        return res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/:provider', ratelimitMiddleware(10), [
    check('provider').isIn(['apple']).withMessage('Only Apple SSO is currently supported'),
    check('token').notEmpty().withMessage('SSO token is required'),
    check('firstName').optional().isString().isLength({ min: 1, max: 50 }),
    check('lastName').optional().isString().isLength({ min: 1, max: 50 })
], async (req, res) => {
    const bodyError = validationResult(req);
    if (!bodyError.isEmpty()) {
        return res.status(400).json({ errors: bodyError.array() });
    }

    try {
        const { provider } = req.params;
        const requestData = { ...req.body, provider };
        const { user, token } = await ssoAuth(requestData);
        
        return res.status(200).json({ 
            message: 'SSO authentication successful', 
            user, 
            token,
            tokenType: 'user'
        });
    } catch (error) {
        log(error, 'error');
        
        if (error.message.includes('Invalid') || error.message.includes('expired')) {
            return res.status(401).json({ message: 'Invalid or expired SSO token' });
        }
        
        if (error.message === 'Account not found. Please register first or contact support.') {
            return res.status(404).json({ message: error.message });
        }
        
        if (error.message === 'User already registered with other sign in method') {
            return res.status(409).json({ message: error.message });
        }
        
        return res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/:provider/link', recentAuthMiddleware(10, ["sso:own:write"]), ratelimitMiddleware(5), [
    check('provider').isIn(['apple']).withMessage('Only Apple SSO is currently supported'),
    check('token').notEmpty().withMessage('SSO token is required')
], async (req, res) => {
    const bodyError = validationResult(req);
    if (!bodyError.isEmpty()) {
        return res.status(400).json({ errors: bodyError.array() });
    }

    try {
        const { provider } = req.params;
        const requestData = { ...req.body, provider };
        const result = await linkSSOProvider(req.user.id, requestData);
        
        return res.status(200).json(result);
    } catch (error) {
        log(error, 'error');
        
        if (error.message === 'User not found') {
            return res.status(404).json({ message: 'User not found' });
        }
        
        if (error.message === 'Provider already linked') {
            return res.status(400).json({ message: 'SSO provider already linked to this account' });
        }
        
        if (error.message === 'SSO account already linked to another user') {
            return res.status(400).json({ message: 'This SSO account is already linked to another user' });
        }
        
        if (error.message.includes('Invalid') || error.message.includes('expired')) {
            return res.status(401).json({ message: 'Invalid or expired SSO token' });
        }
        
        return res.status(500).json({ message: 'Internal server error' });
    }
});

router.delete('/:provider/unlink', recentAuthMiddleware(10, ["sso:own:write"]), ratelimitMiddleware(5), [
    check('provider').isIn(['apple']).withMessage('Only Apple SSO is currently supported')
], async (req, res) => {
    const bodyError = validationResult(req);
    if (!bodyError.isEmpty()) {
        return res.status(400).json({ errors: bodyError.array() });
    }

    try {
        const { provider } = req.params;
        const result = await unlinkSSOProvider(req.user.id, provider);
        
        return res.status(200).json(result);
    } catch (error) {
        log(error, 'error');
        
        if (error.message === 'User not found') {
            return res.status(404).json({ message: 'User not found' });
        }
        
        if (error.message === 'Provider not linked') {
            return res.status(400).json({ message: 'SSO provider not linked to this account' });
        }
        
        if (error.message === 'Cannot unlink last authentication method') {
            return res.status(400).json({ message: 'Cannot unlink last authentication method. Set a password first.' });
        }
        
        return res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;