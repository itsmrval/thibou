const Villager = require('../models/villager.model');
const VillagerImage = require('../models/villagerImage.model');
const { log } = require('../utils/logger.util');


const getVillagerList = async (filters = {}) => {
    try {
        let query = {};
        
        if (filters.species) {
            query.species = filters.species;
        }
        if (filters.personality) {
            query.personality = filters.personality;
        }
        if (filters.gender) {
            query.gender = filters.gender;
        }
        if (filters.islander !== undefined) {
            query.islander = filters.islander;
        }

        const villagers = await Villager.find(query).sort({ 'name.en': 1 });

        const simplifiedVillagers = villagers.map(villager => ({
            _id: villager._id,
            name: villager.name,
            title_color: villager.title_color,
            text_color: villager.text_color,
            species: villager.species,
            gender: villager.gender,
            birthday_date: villager.birthday_date,
            popularity_rank: villager.popularity_rank,
            ready: villager.ready,
            createdAt: villager.createdAt,
            updatedAt: villager.updatedAt
        }));

        return simplifiedVillagers;
    } catch (error) {
        throw error;
    }
};

const getVillager = async (id) => {
    try {
        const villager = await Villager.findOne({ _id: id });

        if (!villager) {
            throw new Error('Villager not found');
        }

        return villager.toJSON();
    } catch (error) {
        throw error;
    }
};

const createVillager = async (villagerData) => {
    try {
        const existingVillager = await Villager.findOne({ 'name.en': villagerData.name.en });
        if (existingVillager) {
            throw new Error('Villager already exists');
        }

        const villager = new Villager(villagerData);
        await villager.save();

        log(`Villager created: ${villagerData.name.en} (${villager._id})`, 'info');
        return villager;
    } catch (error) {
        throw error;
    }
};

const updateVillager = async (id, updateData) => {
    try {
        const villager = await Villager.findOneAndUpdate(
            { _id: id },
            updateData,
            { new: true, runValidators: true }
        );

        if (!villager) {
            throw new Error('Villager not found');
        }

        log(`Villager updated: ${villager.name.en} (${id})`, 'info');
        return villager;
    } catch (error) {
        throw error;
    }
};

const deleteVillager = async (id) => {
    try {
        const villager = await Villager.findOneAndDelete({ _id: id });
        
        if (!villager) {
            throw new Error('Villager not found');
        }

        log(`Villager deleted: ${villager.name.en} (${id})`, 'info');
        return { message: 'Villager deleted successfully' };
    } catch (error) {
        throw error;
    }
};

module.exports = {
    getVillagerList,
    getVillager,
    createVillager,
    updateVillager,
    deleteVillager,
};
