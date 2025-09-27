const Fish = require('../models/fish.model');
const FishImage = require('../models/fishImage.model');
const { log } = require('../utils/logger.util');

const getFishList = async (filters = {}) => {
    try {
        let query = {};

        if (filters.location) {
            query.location = filters.location;
        }
        if (filters.rarity) {
            query.rarity = filters.rarity;
        }

        const fishes = await Fish.find(query).sort({ 'name.en': 1 });

        const simplifiedFishes = fishes.map(fish => ({
            _id: fish._id,
            name: fish.name,
            location: fish.location,
            price: fish.price,
            rarity: fish.rarity,
            createdAt: fish.createdAt,
            updatedAt: fish.updatedAt
        }));

        return simplifiedFishes;
    } catch (error) {
        throw error;
    }
};

const getFish = async (id) => {
    try {
        const fish = await Fish.findOne({ _id: id });

        if (!fish) {
            throw new Error('Fish not found');
        }

        return fish.toJSON();
    } catch (error) {
        throw error;
    }
};

const createFish = async (fishData) => {
    try {
        const existingFish = await Fish.findOne({ 'name.en': fishData.name.en });
        if (existingFish) {
            throw new Error('Fish already exists');
        }

        const fish = new Fish(fishData);
        await fish.save();

        log(`Fish created: ${fishData.name.en} (${fish._id})`, 'info');
        return fish;
    } catch (error) {
        throw error;
    }
};

const updateFish = async (id, updateData) => {
    try {
        const fish = await Fish.findOneAndUpdate(
            { _id: id },
            updateData,
            { new: true, runValidators: true }
        );

        if (!fish) {
            throw new Error('Fish not found');
        }

        log(`Fish updated: ${fish.name.en} (${id})`, 'info');
        return fish;
    } catch (error) {
        throw error;
    }
};

const deleteFish = async (id) => {
    try {
        const fish = await Fish.findOneAndDelete({ _id: id });

        if (!fish) {
            throw new Error('Fish not found');
        }

        log(`Fish deleted: ${fish.name.en} (${id})`, 'info');
        return { message: 'Fish deleted successfully' };
    } catch (error) {
        throw error;
    }
};

module.exports = {
    getFishList,
    getFish,
    createFish,
    updateFish,
    deleteFish,
};