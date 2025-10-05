const router = require('express').Router();
const { check, validationResult } = require('express-validator');
const { ratelimitMiddleware } = require('../middlewares/ratelimit.middleware');
const { authMiddleware } = require('../middlewares/auth.middleware');
const {
    getFossilList,
    getFossil,
    createFossil,
    updateFossil,
    deleteFossil,
} = require('../controllers/fossil.controller');
const {
    getFossilImage,
    uploadFossilImage,
    deleteFossilImage,
} = require('../controllers/fossilImage.controller');
const { log } = require('../utils/logger.util');

router.get('/', async (req, res) => {
        try {
            const filters = {
                room: req.query.room
            };

            const fossils = await getFossilList(filters);

            res.status(200).json({
                message: 'Fossils retrieved successfully',
                count: fossils.length,
                fossils
            });
        } catch (error) {
            log(`Error retrieving fossils: ${error.message}`, 'error');
            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.get('/:id', async (req, res) => {
        try {
            const { id } = req.params;
            const fossil = await getFossil(id);

            res.status(200).json({
                message: 'Fossil retrieved successfully',
                fossil
            });
        } catch (error) {
            log(`Error retrieving fossil: ${error.message}`, 'error');

            if (error.message === 'Fossil not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.post('/',
    authMiddleware(['fossil:write']),
    [
        check('name.en').notEmpty().withMessage('Fossil name is required'),
        check('room').isInt({ min: 1, max: 3 }).withMessage('Room must be 1, 2, or 3'),
        check('parts').isArray({ min: 1 }).withMessage('Parts array is required with at least one part'),
        check('parts.*.name').notEmpty().withMessage('Part name is required'),
        check('parts.*.full_name').notEmpty().withMessage('Part full name is required'),
        check('parts.*.sell').isNumeric().withMessage('Part sell price must be a number'),
        check('parts.*.width').isNumeric().withMessage('Part width must be a number'),
        check('parts.*.length').isNumeric().withMessage('Part length must be a number'),
        check('total_price').isNumeric().withMessage('Total price must be a number'),
        check('parts_count').isInt({ min: 1 }).withMessage('Parts count must be at least 1')
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const fossil = await createFossil(req.body);

            res.status(201).json({
                message: 'Fossil created successfully',
                fossil
            });
        } catch (error) {
            log(`Error creating fossil: ${error.message}`, 'error');

            if (error.message === 'Fossil already exists') {
                return res.status(409).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.put('/:id',
    authMiddleware(['fossil:write']),
    [
        check('room').optional().isInt({ min: 1, max: 3 }).withMessage('Room must be 1, 2, or 3'),
        check('parts').optional().isArray({ min: 1 }).withMessage('Parts must be an array with at least one part'),
        check('total_price').optional().isNumeric().withMessage('Total price must be a number'),
        check('parts_count').optional().isInt({ min: 1 }).withMessage('Parts count must be at least 1')
    ],
    async (req, res) => {
        const bodyError = validationResult(req);
        if (!bodyError.isEmpty()) {
            return res.status(400).json({ errors: bodyError.array() });
        }

        try {
            const { id } = req.params;
            const fossil = await updateFossil(id, req.body);

            res.status(200).json({
                message: 'Fossil updated successfully',
                fossil
            });
        } catch (error) {
            log(`Error updating fossil: ${error.message}`, 'error');

            if (error.message === 'Fossil not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.delete('/:id',
    authMiddleware(['fossil:admin']),
    async (req, res) => {
        try {
            const { id } = req.params;
            const result = await deleteFossil(id);

            res.status(200).json(result);
        } catch (error) {
            log(`Error deleting fossil: ${error.message}`, 'error');

            if (error.message === 'Fossil not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.get('/:id/img/:partName', async (req, res) => {
    try {
        const { id, partName } = req.params;

        const image = await getFossilImage(id, partName);

        res.status(200).json({
            message: 'Fossil image retrieved successfully',
            image
        });
    } catch (error) {
        log(`Error retrieving fossil image: ${error.message}`, 'error');

        if (error.message === 'Fossil not found' || error.message === 'Image not found') {
            return res.status(404).json({ message: error.message });
        }

        res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/:id/img/:partName',
    authMiddleware(['fossil:write']),
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
            const { id, partName } = req.params;
            const { image_data } = req.body;

            const image = await uploadFossilImage(id, partName, image_data);

            res.status(200).json({
                message: 'Fossil image uploaded successfully',
                image
            });
        } catch (error) {
            log(`Error uploading fossil image: ${error.message}`, 'error');

            if (error.message === 'Fossil not found') {
                return res.status(404).json({ message: error.message });
            }

            if (error.message === 'Part not found in fossil') {
                return res.status(400).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

router.delete('/:id/img/:partName',
    authMiddleware(['fossil:admin']),
    async (req, res) => {
        try {
            const { id, partName } = req.params;

            const result = await deleteFossilImage(id, partName);

            res.status(200).json(result);
        } catch (error) {
            log(`Error deleting fossil image: ${error.message}`, 'error');

            if (error.message === 'Fossil not found' || error.message === 'Image not found') {
                return res.status(404).json({ message: error.message });
            }

            res.status(500).json({ message: 'Internal server error' });
        }
    }
);

module.exports = router;
