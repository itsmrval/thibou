const router = require('express').Router();
const { check, validationResult } = require('express-validator');
const { ratelimitMiddleware } = require('../middlewares/ratelimit.middleware');
const { authMiddleware } = require('../middlewares/auth.middleware');
const {
    getBugList,
    getBug,
    createBug,
    updateBug,
    deleteBug,
} = require('../controllers/bug.controller');
const { log } = require('../utils/logger.util');

router.get('/', async (req, res) => {
        try {
            const filters = {
                location: req.query.location,
                weather: req.query.weather,
                rarity: req.query.rarity,
                search: req.query.search
            };

            const bugs = await getBugList(filters);

            res.status(200).json({
                message: 'Bugs retrieved successfully',
                count: bugs.length,
                bugs
            });
        } catch (error) {
            log(`Error retrieving bugs: ${error.message}`, 'error');
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.get('/:id', async (req, res) => {
        try {
            const { id } = req.params;
            const bug = await getBug(id);

            res.status(200).json({
                message: 'Bug retrieved successfully',
                bug
            });
        } catch (error) {
            log(`Error retrieving bug: ${error.message}`, 'error');

            if (error.message === 'Bug not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.post('/',
    authMiddleware(['bug:write']),
    [
        check('name.en').notEmpty().withMessage('Original name is required'),
        check('location').isIn(['flying', 'trees', 'ground', 'flowers', 'water', 'rocks', 'stumps', 'villagers', 'special']).withMessage('Location must be one of: flying, trees, ground, flowers, water, rocks, stumps, villagers, special'),
        check('weather').isIn(['any', 'rain']).withMessage('Weather must be one of: any, rain'),
        check('price.shop').isNumeric().withMessage('Shop price must be a number'),
        check('price.flick').isNumeric().withMessage('Flick price must be a number'),
        check('rarity').optional().isIn(['very_common', 'common', 'uncommon', 'rare']).withMessage('Rarity must be one of: very_common, common, uncommon, rare')
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const bug = await createBug(req.body);

            res.status(201).json({
                message: 'Bug created successfully',
                bug
            });
        } catch (error) {
            log(`Error creating bug: ${error.message}`, 'error');

            if (error.message === 'Bug already exists') {
                return res.status(409).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.put('/:id',
    authMiddleware(['bug:write']),
    [
        check('location').optional().isIn(['flying', 'trees', 'ground', 'flowers', 'water', 'rocks', 'stumps', 'villagers', 'special']).withMessage('Location must be one of: flying, trees, ground, flowers, water, rocks, stumps, villagers, special'),
        check('weather').optional().isIn(['any', 'rain']).withMessage('Weather must be one of: any, rain'),
        check('price.shop').optional().isNumeric().withMessage('Shop price must be a number'),
        check('price.flick').optional().isNumeric().withMessage('Flick price must be a number'),
        check('rarity').optional().isIn(['very_common', 'common', 'uncommon', 'rare']).withMessage('Rarity must be one of: very_common, common, uncommon, rare')
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const { id } = req.params;
            const bug = await updateBug(id, req.body);

            res.status(200).json({
                message: 'Bug updated successfully',
                bug
            });
        } catch (error) {
            log(`Error updating bug: ${error.message}`, 'error');

            if (error.message === 'Bug not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.delete('/:id',
    authMiddleware(['bug:admin']),
    async (req, res) => {
        try {
            const { id } = req.params;
            const result = await deleteBug(id);

            res.status(200).json(result);
        } catch (error) {
            log(`Error deleting bug: ${error.message}`, 'error');

            if (error.message === 'Bug not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

module.exports = router;