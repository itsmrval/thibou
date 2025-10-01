const router = require('express').Router();
const { check, validationResult } = require('express-validator');
const { ratelimitMiddleware } = require('../middlewares/ratelimit.middleware');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { recentAuthMiddleware } = require('../middlewares/recent-auth.middleware');
const {
    getUserList,
    getUser,
    updateProfile,
    deleteUser,
    getIslandData,
    updateIslandResidents,
    updateIslandFavorites,
} = require('../controllers/user.controller');
const authUtil = require('../utils/auth.util');
const { log } = require('../utils/logger.util');
const User = require('../models/user.model');


router.get('/',
    authMiddleware(['user:admin']),
    async (req, res) => {
        try {
            const users = await getUserList();
            res.status(200).json({
                message: 'Users retrieved successfully',
                users
            });
        } catch (error) {
            log(`Error retrieving users: ${error.message}`, 'error');
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.get('/:id',
    authMiddleware(['user:read', 'user:own:read']),
    async (req, res) => {
        try {
            const { id } = req.params;
            const isAdmin = req.user.role === 'admin';
            const isOwnUser = req.user.id === id;
            const hasUserReadScope = req.user.scopes && req.user.scopes.includes('user:read');
            
            if (!isAdmin && !isOwnUser && !hasUserReadScope) {
                return res.status(403).json({ message: 'Access denied' });
            }

            const user = await getUser(id, isAdmin);
            
            res.status(200).json({
                message: 'User retrieved successfully',
                user
            });
        } catch (error) {
            log(`Error retrieving user: ${error.message}`, 'error');
            
            if (error.message === 'User not found') {
                return res.status(404).json({ message: error.message });
            }
            
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.put('/:id',
    authMiddleware(['user:own:write']),
    recentAuthMiddleware(10, ['user:own:write']),
    [
        check('name').optional().isString().isLength({ min: 1, max: 100 }),
        check('email').optional().isEmail(),
        check('newPassword').optional().isString().isLength({ min: 6, max: 50 })
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const { id } = req.params;
            const isOwnUser = req.user.id === id;
            
            if (!isOwnUser) {
                return res.status(403).json({ message: 'Access denied' });
            }

            const result = await updateProfile(id, req.body);
            
            res.status(200).json(result);
        } catch (error) {
            log(`Error updating profile: ${error.message}`, 'error');
            
            if (error.message === 'User not found') {
                return res.status(404).json({ message: error.message });
            }
            if (error.message === 'System users cannot update profile') {
                return res.status(403).json({ message: error.message });
            }
            if (error.message === 'Email already in use') {
                return res.status(400).json({ message: error.message, field: 'email' });
            }
            if (error.message.includes('must be at least') || 
                error.message.includes('can only contain') ||
                error.message.includes('must be between')) {
                return res.status(400).json({ message: error.message });
            }
            
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.delete('/:id',
    authMiddleware(['user:admin']),
    async (req, res) => {
        try {
            const { id } = req.params;
            const result = await deleteUser(id);

            res.status(200).json(result);
        } catch (error) {
            log(`Error deleting user: ${error.message}`, 'error');

            if (error.message === 'User not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

// Island routes
router.get('/:id/island',
    authMiddleware(['user:own:read']),
    async (req, res) => {
        try {
            const { id } = req.params;
            const isOwnUser = req.user.id === id;

            if (!isOwnUser) {
                return res.status(403).json({ message: 'Access denied' });
            }

            const islandData = await getIslandData(id);

            res.status(200).json({
                message: 'Island data retrieved successfully',
                island: islandData
            });
        } catch (error) {
            log(`Error retrieving island data: ${error.message}`, 'error');

            if (error.message === 'User not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.put('/:id/island/residents',
    authMiddleware(['user:own:write']),
    recentAuthMiddleware(10, ['user:own:write']),
    [
        check('residents').isArray().withMessage('Residents must be an array'),
        check('residents').custom((value) => {
            if (value.length > 10) {
                throw new Error('Island can have a maximum of 10 residents');
            }
            return true;
        })
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const { id } = req.params;
            const { residents } = req.body;
            const isOwnUser = req.user.id === id;

            if (!isOwnUser) {
                return res.status(403).json({ message: 'Access denied' });
            }

            const islandData = await updateIslandResidents(id, residents);

            res.status(200).json({
                message: 'Island residents updated successfully',
                island: islandData
            });
        } catch (error) {
            log(`Error updating island residents: ${error.message}`, 'error');

            if (error.message === 'User not found') {
                return res.status(404).json({ message: error.message });
            }
            if (error.message.includes('maximum') || error.message.includes('invalid') || error.message.includes('Duplicate')) {
                return res.status(400).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.put('/:id/island/favorites',
    authMiddleware(['user:own:write']),
    recentAuthMiddleware(10, ['user:own:write']),
    [
        check('favorites').isArray().withMessage('Favorites must be an array'),
        check('favorites').custom((value) => {
            if (value.length > 3) {
                throw new Error('You can have a maximum of 3 favorite villagers');
            }
            return true;
        })
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const { id } = req.params;
            const { favorites } = req.body;
            const isOwnUser = req.user.id === id;

            if (!isOwnUser) {
                return res.status(403).json({ message: 'Access denied' });
            }

            const islandData = await updateIslandFavorites(id, favorites);

            res.status(200).json({
                message: 'Island favorites updated successfully',
                island: islandData
            });
        } catch (error) {
            log(`Error updating island favorites: ${error.message}`, 'error');

            if (error.message === 'User not found') {
                return res.status(404).json({ message: error.message });
            }
            if (error.message.includes('maximum') || error.message.includes('residents') || error.message.includes('Duplicate')) {
                return res.status(400).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

module.exports = router;