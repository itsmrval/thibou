const FossilImage = require('../models/fossilImage.model');
const Fossil = require('../models/fossil.model');
const { log } = require('../utils/logger.util');

const getFossilImage = async (fossilId, partName) => {
    try {
        const fossil = await Fossil.findById(fossilId);
        if (!fossil) {
            throw new Error('Fossil not found');
        }

        const image = await FossilImage.findOne({
            fossil_id: fossilId,
            part_name: partName
        });

        if (!image) {
            throw new Error('Image not found');
        }

        return image;
    } catch (error) {
        throw error;
    }
};

const uploadFossilImage = async (fossilId, partName, imageData) => {
    try {
        const fossil = await Fossil.findById(fossilId);
        if (!fossil) {
            throw new Error('Fossil not found');
        }

        const partExists = fossil.parts.some(part => part.name === partName);
        if (!partExists) {
            throw new Error('Part not found in fossil');
        }

        const base64Data = imageData.replace(/^data:image\/png;base64,/, '');
        const imageSize = Buffer.from(base64Data, 'base64').length;

        const existingImage = await FossilImage.findOne({
            fossil_id: fossilId,
            part_name: partName
        });

        if (existingImage) {
            existingImage.image_data = imageData;
            existingImage.size = imageSize;
            await existingImage.save();

            log(`Fossil image updated: ${fossilId} - ${partName}`, 'info');
            return existingImage;
        }

        const newImage = new FossilImage({
            fossil_id: fossilId,
            part_name: partName,
            image_data: imageData,
            size: imageSize
        });

        await newImage.save();

        log(`Fossil image uploaded: ${fossilId} - ${partName}`, 'info');
        return newImage;
    } catch (error) {
        throw error;
    }
};

const deleteFossilImage = async (fossilId, partName) => {
    try {
        const fossil = await Fossil.findById(fossilId);
        if (!fossil) {
            throw new Error('Fossil not found');
        }

        const image = await FossilImage.findOneAndDelete({
            fossil_id: fossilId,
            part_name: partName
        });

        if (!image) {
            throw new Error('Image not found');
        }

        log(`Fossil image deleted: ${fossilId} - ${partName}`, 'info');
        return { message: 'Fossil image deleted successfully' };
    } catch (error) {
        throw error;
    }
};

module.exports = {
    getFossilImage,
    uploadFossilImage,
    deleteFossilImage,
};
