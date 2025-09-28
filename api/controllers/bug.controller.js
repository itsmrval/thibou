const Bug = require('../models/bug.model');
const { log } = require('../utils/logger.util');

const getBugList = async (filters = {}) => {
    try {
        let query = {};

        if (filters.location) {
            query.location = filters.location;
        }
        if (filters.weather) {
            query.weather = filters.weather;
        }
        if (filters.rarity) {
            query.rarity = filters.rarity;
        }

        const bugs = await Bug.find(query).sort({ 'name.en': 1 });

        const simplifiedBugs = bugs.map(bug => ({
            _id: bug._id,
            name: bug.name,
            location: bug.location,
            weather: bug.weather,
            price: bug.price,
            rarity: bug.rarity,
            createdAt: bug.createdAt,
            updatedAt: bug.updatedAt
        }));

        return simplifiedBugs;
    } catch (error) {
        throw error;
    }
};

const getBug = async (id) => {
    try {
        const bug = await Bug.findOne({ _id: id });

        if (!bug) {
            throw new Error('Bug not found');
        }

        return bug.toJSON();
    } catch (error) {
        throw error;
    }
};

const createBug = async (bugData) => {
    try {
        const existingBug = await Bug.findOne({ 'name.en': bugData.name.en });
        if (existingBug) {
            throw new Error('Bug already exists');
        }

        const bug = new Bug(bugData);
        await bug.save();

        log(`Bug created: ${bugData.name.en} (${bug._id})`, 'info');
        return bug;
    } catch (error) {
        throw error;
    }
};

const updateBug = async (id, updateData) => {
    try {
        const bug = await Bug.findOneAndUpdate(
            { _id: id },
            updateData,
            { new: true, runValidators: true }
        );

        if (!bug) {
            throw new Error('Bug not found');
        }

        log(`Bug updated: ${bug.name.en} (${id})`, 'info');
        return bug;
    } catch (error) {
        throw error;
    }
};

const deleteBug = async (id) => {
    try {
        const bug = await Bug.findOneAndDelete({ _id: id });

        if (!bug) {
            throw new Error('Bug not found');
        }

        log(`Bug deleted: ${bug.name.en} (${id})`, 'info');
        return { message: 'Bug deleted successfully' };
    } catch (error) {
        throw error;
    }
};

module.exports = {
    getBugList,
    getBug,
    createBug,
    updateBug,
    deleteBug,
};