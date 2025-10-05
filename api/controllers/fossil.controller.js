const Fossil = require('../models/fossil.model');
const { log } = require('../utils/logger.util');

const getFossilList = async (filters = {}) => {
    try {
        let query = {};

        if (filters.room) {
            query.room = parseInt(filters.room);
        }

        const fossils = await Fossil.find(query).sort({ 'name.en': 1 });

        const simplifiedFossils = fossils.map(fossil => ({
            _id: fossil._id,
            name: fossil.name,
            room: fossil.room,
            parts: fossil.parts,
            total_price: fossil.total_price,
            parts_count: fossil.parts_count,
            createdAt: fossil.createdAt,
            updatedAt: fossil.updatedAt
        }));

        return simplifiedFossils;
    } catch (error) {
        throw error;
    }
};

const getFossil = async (id) => {
    try {
        const fossil = await Fossil.findOne({ _id: id });

        if (!fossil) {
            throw new Error('Fossil not found');
        }

        return fossil.toJSON();
    } catch (error) {
        throw error;
    }
};

const createFossil = async (fossilData) => {
    try {
        const existingFossil = await Fossil.findOne({ 'name.en': fossilData.name.en });
        if (existingFossil) {
            throw new Error('Fossil already exists');
        }

        const fossil = new Fossil(fossilData);
        await fossil.save();

        log(`Fossil created: ${fossilData.name.en} (${fossil._id})`, 'info');
        return fossil;
    } catch (error) {
        throw error;
    }
};

const updateFossil = async (id, updateData) => {
    try {
        const fossil = await Fossil.findOneAndUpdate(
            { _id: id },
            updateData,
            { new: true, runValidators: true }
        );

        if (!fossil) {
            throw new Error('Fossil not found');
        }

        log(`Fossil updated: ${fossil.name.en} (${id})`, 'info');
        return fossil;
    } catch (error) {
        throw error;
    }
};

const deleteFossil = async (id) => {
    try {
        const fossil = await Fossil.findOneAndDelete({ _id: id });

        if (!fossil) {
            throw new Error('Fossil not found');
        }

        log(`Fossil deleted: ${fossil.name.en} (${id})`, 'info');
        return { message: 'Fossil deleted successfully' };
    } catch (error) {
        throw error;
    }
};

module.exports = {
    getFossilList,
    getFossil,
    createFossil,
    updateFossil,
    deleteFossil,
};
