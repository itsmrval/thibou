const router = require('express').Router();
const { check, validationResult } = require('express-validator');
const { ratelimitMiddleware } = require('../middlewares/ratelimit.middleware');
const { authMiddleware } = require('../middlewares/auth.middleware');
const {
    getFishList,
    getFish,
    createFish,
    updateFish,
    deleteFish,
} = require('../controllers/fish.controller');
const {
    getFishImage,
    uploadFishImage,
    deleteFishImage,
} = require('../controllers/fishImage.controller');
const { log } = require('../utils/logger.util');

router.get('/', async (req, res) => {
        try {
            const filters = {
                location: req.query.location,
                rarity: req.query.rarity,
                search: req.query.search
            };

            const fishes = await getFishList(filters);

            res.status(200).json({
                message: 'Fishes retrieved successfully',
                count: fishes.length,
                fishes
            });
        } catch (error) {
            log(`Error retrieving fishes: ${error.message}`, 'error');
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.get('/:id', async (req, res) => {
        try {
            const { id } = req.params;
            const fish = await getFish(id);

            res.status(200).json({
                message: 'Fish retrieved successfully',
                fish
            });
        } catch (error) {
            log(`Error retrieving fish: ${error.message}`, 'error');

            if (error.message === 'Fish not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.post('/',
    authMiddleware(['fish:write']),
    [
        check('name.en').notEmpty().withMessage('Original name is required'),
        check('location').isIn(['river', 'pond', 'sea', 'pier']).withMessage('Location must be river, pond, sea, or pier'),
        check('price.cj').isInt({ min: 0 }).withMessage('CJ price must be a non-negative integer'),
        check('price.shop').isInt({ min: 0 }).withMessage('Shop price must be a non-negative integer'),
        check('rarity').isIn(['common', 'uncommon', 'rare']).withMessage('Rarity must be common, uncommon, or rare'),
        check('availability.north').optional().isObject().withMessage('North availability must be an object'),
        check('availability.south').optional().isObject().withMessage('South availability must be an object')
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const fish = await createFish(req.body);

            res.status(201).json({
                message: 'Fish created successfully',
                fish
            });
        } catch (error) {
            log(`Error creating fish: ${error.message}`, 'error');

            if (error.message === 'Fish already exists') {
                return res.status(409).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.put('/:id',
    authMiddleware(['fish:write']),
    [
        check('location').optional().isIn(['river', 'pond', 'sea', 'pier']).withMessage('Location must be river, pond, sea, or pier'),
        check('price.cj').optional().isInt({ min: 0 }).withMessage('CJ price must be a non-negative integer'),
        check('price.shop').optional().isInt({ min: 0 }).withMessage('Shop price must be a non-negative integer'),
        check('rarity').optional().isIn(['common', 'uncommon', 'rare']).withMessage('Rarity must be common, uncommon, or rare'),
        check('availability.north').optional().isObject().withMessage('North availability must be an object'),
        check('availability.south').optional().isObject().withMessage('South availability must be an object')
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const { id } = req.params;
            const fish = await updateFish(id, req.body);

            res.status(200).json({
                message: 'Fish updated successfully',
                fish
            });
        } catch (error) {
            log(`Error updating fish: ${error.message}`, 'error');

            if (error.message === 'Fish not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.delete('/:id',
    authMiddleware(['fish:admin']),
    async (req, res) => {
        try {
            const { id } = req.params;
            const result = await deleteFish(id);

            res.status(200).json(result);
        } catch (error) {
            log(`Error deleting fish: ${error.message}`, 'error');

            if (error.message === 'Fish not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.get('/:id/img/:type', async (req, res) => {
    try {
        const { id, type } = req.params;

        if (!['full', 'small'].includes(type)) {
            return res.status(400).json({
                message: 'Type must be one of: full, small'
            });
        }

        const image = await getFishImage(id, type);

        res.status(200).json({
            message: 'Fish image retrieved successfully',
            image
        });
    } catch (error) {
        log(`Error retrieving fish image: ${error.message}`, 'error');

        if (error.message === 'Fish not found' || error.message === 'Image not found') {
            return res.status(404).json({ message: error.message });
        }

        res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/:id/img/:type',
    authMiddleware(['fish:write']),
    [
        check('image_data')
            .notEmpty()
            .withMessage('Image data is required')
            .matches(/^data:image\/png;base64,[A-Za-z0-9+/]+={0,2}$/)
            .withMessage('Image must be a valid Base64 PNG format')
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const { id, type } = req.params;
            const { image_data } = req.body;

            if (!['full', 'small'].includes(type)) {
                return res.status(400).json({
                    message: 'Type must be one of: full, small'
                });
            }

            const image = await uploadFishImage(id, type, image_data);

            res.status(200).json({
                message: 'Fish image uploaded successfully',
                image
            });
        } catch (error) {
            log(`Error uploading fish image: ${error.message}`, 'error');

            if (error.message === 'Fish not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.delete('/:id/img/:type',
    authMiddleware(['fish:admin']),
    async (req, res) => {
        try {
            const { id, type } = req.params;

            if (!['full', 'small'].includes(type)) {
                return res.status(400).json({
                    message: 'Type must be one of: full, small'
                });
            }

            const result = await deleteFishImage(id, type);

            res.status(200).json(result);
        } catch (error) {
            log(`Error deleting fish image: ${error.message}`, 'error');

            if (error.message === 'Fish not found' || error.message === 'Image not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

module.exports = router;