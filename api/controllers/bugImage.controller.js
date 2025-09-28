const BugImage = require('../models/bugImage.model');
const Bug = require('../models/bug.model');
const { log } = require('../utils/logger.util');
const { getRedisClient } = require('../utils/redis.util');
const mongoose = require('mongoose');

const IMAGE_CACHE_TTL = 3600;

const getBugImage = async (bugId, imageType) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(bugId)) {
            throw new Error('Image not found');
        }

        const redis = getRedisClient();
        const cacheKey = `bug_image:${bugId}:${imageType}`;

        const cachedImage = await redis.get(cacheKey);
        if (cachedImage) {
            return JSON.parse(cachedImage);
        }

        const image = await BugImage.findOne({
            bug_id: bugId,
            image_type: imageType
        }).lean();

        if (!image) {
            throw new Error('Image not found');
        }

        await redis.setEx(cacheKey, IMAGE_CACHE_TTL, JSON.stringify(image));
        return image;
    } catch (error) {
        throw error;
    }
};

const uploadBugImage = async (bugId, imageType, imageData) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(bugId)) {
            throw new Error('Bug not found');
        }

        const bug = await Bug.findById(bugId);
        if (!bug) {
            throw new Error('Bug not found');
        }

        const sizeInBytes = Math.floor((imageData.length - 'data:image/png;base64,'.length) * 0.75);

        const image = await BugImage.findOneAndUpdate(
            { bug_id: bugId, image_type: imageType },
            {
                bug_id: bugId,
                image_type: imageType,
                image_data: imageData,
                size: sizeInBytes
            },
            {
                upsert: true,
                new: true,
                runValidators: true
            }
        );

        const redis = getRedisClient();
        const cacheKey = `bug_image:${bugId}:${imageType}`;
        await redis.del(cacheKey);

        log(`Bug image uploaded: ${bug.name.en} - ${imageType} (${image._id})`, 'info');
        return image;
    } catch (error) {
        throw error;
    }
};

const deleteBugImage = async (bugId, imageType) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(bugId)) {
            throw new Error('Bug not found');
        }

        const bug = await Bug.findById(bugId);
        if (!bug) {
            throw new Error('Bug not found');
        }

        const image = await BugImage.findOneAndDelete({
            bug_id: bugId,
            image_type: imageType
        });

        if (!image) {
            throw new Error('Image not found');
        }

        const redis = getRedisClient();
        const cacheKey = `bug_image:${bugId}:${imageType}`;
        await redis.del(cacheKey);

        log(`Bug image deleted: ${bug.name.en} - ${imageType} (${image._id})`, 'info');
        return { message: 'Image deleted successfully' };
    } catch (error) {
        throw error;
    }
};

const getBugImages = async (bugId) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(bugId)) {
            throw new Error('Bug not found');
        }

        const bug = await Bug.findById(bugId);
        if (!bug) {
            throw new Error('Bug not found');
        }

        const images = await BugImage.find({ bug_id: bugId }).lean();
        return images;
    } catch (error) {
        throw error;
    }
};

module.exports = {
    getBugImage,
    uploadBugImage,
    deleteBugImage,
    getBugImages
};