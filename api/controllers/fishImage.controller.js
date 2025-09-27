const FishImage = require('../models/fishImage.model');
const Fish = require('../models/fish.model');
const { log } = require('../utils/logger.util');
const { getRedisClient } = require('../utils/redis.util');
const mongoose = require('mongoose');

const IMAGE_CACHE_TTL = 3600;

const getFishImage = async (fishId, imageType) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(fishId)) {
            throw new Error('Image not found');
        }

        const redis = getRedisClient();
        const cacheKey = `fish_image:${fishId}:${imageType}`;

        const cachedImage = await redis.get(cacheKey);
        if (cachedImage) {
            return JSON.parse(cachedImage);
        }

        const image = await FishImage.findOne({
            fish_id: fishId,
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

const uploadFishImage = async (fishId, imageType, imageData) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(fishId)) {
            throw new Error('Fish not found');
        }

        const fish = await Fish.findById(fishId);
        if (!fish) {
            throw new Error('Fish not found');
        }

        const sizeInBytes = Math.floor((imageData.length - 'data:image/png;base64,'.length) * 0.75);

        const image = await FishImage.findOneAndUpdate(
            { fish_id: fishId, image_type: imageType },
            {
                fish_id: fishId,
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
        const cacheKey = `fish_image:${fishId}:${imageType}`;
        await redis.del(cacheKey);

        log(`Fish image uploaded: ${fish.name.en} - ${imageType} (${image._id})`, 'info');
        return image;
    } catch (error) {
        throw error;
    }
};

const deleteFishImage = async (fishId, imageType) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(fishId)) {
            throw new Error('Fish not found');
        }

        const fish = await Fish.findById(fishId);
        if (!fish) {
            throw new Error('Fish not found');
        }

        const image = await FishImage.findOneAndDelete({
            fish_id: fishId,
            image_type: imageType
        });

        if (!image) {
            throw new Error('Image not found');
        }

        const redis = getRedisClient();
        const cacheKey = `fish_image:${fishId}:${imageType}`;
        await redis.del(cacheKey);

        log(`Fish image deleted: ${fish.name.en} - ${imageType} (${image._id})`, 'info');
        return { message: 'Image deleted successfully' };
    } catch (error) {
        throw error;
    }
};

const getFishImages = async (fishId) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(fishId)) {
            throw new Error('Fish not found');
        }

        const fish = await Fish.findById(fishId);
        if (!fish) {
            throw new Error('Fish not found');
        }

        const images = await FishImage.find({ fish_id: fishId }).lean();
        return images;
    } catch (error) {
        throw error;
    }
};

module.exports = {
    getFishImage,
    uploadFishImage,
    deleteFishImage,
    getFishImages
};