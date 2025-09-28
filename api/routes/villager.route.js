const router = require('express').Router();
const { check, validationResult } = require('express-validator');
const { ratelimitMiddleware } = require('../middlewares/ratelimit.middleware');
const { authMiddleware } = require('../middlewares/auth.middleware');
const {
    getVillagerList,
    getVillager,
    createVillager,
    updateVillager,
    deleteVillager,
} = require('../controllers/villager.controller');
const {
    getVillagerImage,
    uploadVillagerImage,
    deleteVillagerImage,
} = require('../controllers/villagerImage.controller');
const { log } = require('../utils/logger.util');

router.get('/', async (req, res) => {
        try {
            const filters = {
                species: req.query.species,
                personality: req.query.personality,
                gender: req.query.gender,
                islander: req.query.islander === 'true' ? true : req.query.islander === 'false' ? false : undefined,
                search: req.query.search
            };

            const villagers = await getVillagerList(filters);
            
            res.status(200).json({
                message: 'Villagers retrieved successfully',
                count: villagers.length,
                villagers
            });
        } catch (error) {
            log(`Error retrieving villagers: ${error.message}`, 'error');
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.get('/:id', async (req, res) => {
        try {
            const { id } = req.params;
            const villager = await getVillager(id);
            
            res.status(200).json({
                message: 'Villager retrieved successfully',
                villager
            });
        } catch (error) {
            log(`Error retrieving villager: ${error.message}`, 'error');
            
            if (error.message === 'Villager not found') {
                return res.status(404).json({ message: error.message });
            }
            
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.post('/',
    authMiddleware(['villager:write']),
    [
        check('name.en').notEmpty().withMessage('Original name is required'),
        check('title_color').matches(/^[0-9a-fA-F]{6}$/).withMessage('Title color must be a valid hex color'),
        check('text_color').matches(/^[0-9a-fA-F]{6}$/).withMessage('Text color must be a valid hex color'),
        check('species').notEmpty().withMessage('Species is required'),
        check('personality').notEmpty().withMessage('Personality is required'),
        check('gender').isIn(['male', 'female']).withMessage('Gender must be male or female'),
        check('birthday_date').matches(/^\d{2}-\d{2}$/).withMessage('Birthday date must be in DD-MM format'),
        check('sign').notEmpty().withMessage('Sign is required'),
        check('quote.en').notEmpty().withMessage('Original quote is required'),
        check('islander').isBoolean().withMessage('Islander must be a boolean'),
        check('debut').notEmpty().withMessage('Debut is required'),
        check('popularity_rank').optional().isIn(['S+', 'S', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'unranked']).withMessage('Popularity rank must be one of: S+, S, A, B, C, D, E, F, G, unranked')
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const villager = await createVillager(req.body);
            
            res.status(201).json({
                message: 'Villager created successfully',
                villager
            });
        } catch (error) {
            log(`Error creating villager: ${error.message}`, 'error');
            
            if (error.message === 'Villager already exists') {
                return res.status(409).json({ message: error.message });
            }
            
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.put('/:id',
    authMiddleware(['villager:write']),
    [
        check('title_color').optional().matches(/^[0-9a-fA-F]{6}$/).withMessage('Title color must be a valid hex color'),
        check('text_color').optional().matches(/^[0-9a-fA-F]{6}$/).withMessage('Text color must be a valid hex color'),
        check('gender').optional().isIn(['male', 'female']).withMessage('Gender must be male or female'),
        check('birthday_date').optional().matches(/^\d{2}-\d{2}$/).withMessage('Birthday date must be in DD-MM format'),
        check('islander').optional().isBoolean().withMessage('Islander must be a boolean'),
        check('popularity_rank').optional().isIn(['S+', 'S', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'unranked']).withMessage('Popularity rank must be one of: S+, S, A, B, C, D, E, F, G, unranked')
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const { id } = req.params;
            const villager = await updateVillager(id, req.body);
            
            res.status(200).json({
                message: 'Villager updated successfully',
                villager
            });
        } catch (error) {
            log(`Error updating villager: ${error.message}`, 'error');
            
            if (error.message === 'Villager not found') {
                return res.status(404).json({ message: error.message });
            }
            
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.delete('/:id',
    authMiddleware(['villager:admin']),
    async (req, res) => {
        try {
            const { id } = req.params;
            const result = await deleteVillager(id);
            
            res.status(200).json(result);
        } catch (error) {
            log(`Error deleting villager: ${error.message}`, 'error');
            
            if (error.message === 'Villager not found') {
                return res.status(404).json({ message: error.message });
            }
            
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.get('/:id/img/:type', async (req, res) => {
    try {
        const { id, type } = req.params;

        if (!['full', 'small', 'interior', 'exterior', 'shape', 'roof', 'siding', 'door'].includes(type)) {
            return res.status(400).json({
                message: 'Type must be one of: full, small, interior, exterior, shape, roof, siding, door'
            });
        }

        const image = await getVillagerImage(id, type);

        res.status(200).json({
            message: 'Villager image retrieved successfully',
            image
        });
    } catch (error) {
        log(`Error retrieving villager image: ${error.message}`, 'error');

        if (error.message === 'Villager not found' || error.message === 'Image not found') {
            return res.status(404).json({ message: error.message });
        }

        res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/:id/img/:type',
    authMiddleware(['villager:write']),
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

            if (!['full', 'small', 'interior', 'exterior', 'shape', 'roof', 'siding', 'door'].includes(type)) {
                return res.status(400).json({
                    message: 'Type must be one of: full, small, interior, exterior, shape, roof, siding, door'
                });
            }

            const image = await uploadVillagerImage(id, type, image_data);

            res.status(200).json({
                message: 'Villager image uploaded successfully',
                image
            });
        } catch (error) {
            log(`Error uploading villager image: ${error.message}`, 'error');

            if (error.message === 'Villager not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.delete('/:id/img/:type',
    authMiddleware(['villager:admin']),
    async (req, res) => {
        try {
            const { id, type } = req.params;

            if (!['full', 'small', 'interior', 'exterior', 'shape', 'roof', 'siding', 'door'].includes(type)) {
                return res.status(400).json({
                    message: 'Type must be one of: full, small, interior, exterior, shape, roof, siding, door'
                });
            }

            const result = await deleteVillagerImage(id, type);

            res.status(200).json(result);
        } catch (error) {
            log(`Error deleting villager image: ${error.message}`, 'error');

            if (error.message === 'Villager not found' || error.message === 'Image not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

module.exports = router;
