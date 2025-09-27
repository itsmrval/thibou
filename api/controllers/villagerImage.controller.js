const VillagerImage = require('../models/villagerImage.model');
const Villager = require('../models/villager.model');
const { log } = require('../utils/logger.util');
const { getRedisClient } = require('../utils/redis.util');
const mongoose = require('mongoose');

const IMAGE_CACHE_TTL = 3600;

const getVillagerImage = async (villagerId, imageType) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(villagerId)) {
            throw new Error('Image not found');
        }

        const redis = getRedisClient();
        const cacheKey = `villager_image:${villagerId}:${imageType}`;

        const cachedImage = await redis.get(cacheKey);
        if (cachedImage) {
            return JSON.parse(cachedImage);
        }

        const image = await VillagerImage.findOne({
            villager_id: villagerId,
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

const uploadVillagerImage = async (villagerId, imageType, imageData) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(villagerId)) {
            throw new Error('Villager not found');
        }

        const villager = await Villager.findById(villagerId);
        if (!villager) {
            throw new Error('Villager not found');
        }

        const sizeInBytes = Math.floor((imageData.length - 'data:image/png;base64,'.length) * 0.75);

        const image = await VillagerImage.findOneAndUpdate(
            { villager_id: villagerId, image_type: imageType },
            {
                villager_id: villagerId,
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
        const cacheKey = `villager_image:${villagerId}:${imageType}`;
        await redis.del(cacheKey);

        log(`Villager image uploaded: ${villager.name.en} - ${imageType} (${image._id})`, 'info');
        return image;
    } catch (error) {
        throw error;
    }
};

const deleteVillagerImage = async (villagerId, imageType) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(villagerId)) {
            throw new Error('Villager not found');
        }

        const villager = await Villager.findById(villagerId);
        if (!villager) {
            throw new Error('Villager not found');
        }

        const image = await VillagerImage.findOneAndDelete({
            villager_id: villagerId,
            image_type: imageType
        });

        if (!image) {
            throw new Error('Image not found');
        }

        const redis = getRedisClient();
        const cacheKey = `villager_image:${villagerId}:${imageType}`;
        await redis.del(cacheKey);

        log(`Villager image deleted: ${villager.name.en} - ${imageType} (${image._id})`, 'info');
        return { message: 'Image deleted successfully' };
    } catch (error) {
        throw error;
    }
};

const getVillagerImages = async (villagerId) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(villagerId)) {
            throw new Error('Villager not found');
        }

        const villager = await Villager.findById(villagerId);
        if (!villager) {
            throw new Error('Villager not found');
        }

        const images = await VillagerImage.find({ villager_id: villagerId }).lean();
        return images;
    } catch (error) {
        throw error;
    }
};

module.exports = {
    getVillagerImage,
    uploadVillagerImage,
    deleteVillagerImage,
    getVillagerImages
};