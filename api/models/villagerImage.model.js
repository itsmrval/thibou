const mongoose = require('mongoose');

const VillagerImageSchema = new mongoose.Schema({
    villager_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Villager',
        required: true
    },
    image_type: {
        type: String,
        required: true,
        enum: ['full', 'small', 'interior', 'exterior', 'shape', 'roof', 'siding', 'door']
    },
    image_data: {
        type: String,
        required: true,
        validate: {
            validator: function(v) {
                return /^data:image\/png;base64,[A-Za-z0-9+/]+={0,2}$/.test(v);
            },
            message: 'Image must be a valid Base64 PNG format'
        }
    },
    size: {
        type: Number,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

VillagerImageSchema.index({ villager_id: 1, image_type: 1 }, { unique: true });

VillagerImageSchema.pre('save', function(next) {
    this.updatedAt = new Date();
    next();
});

VillagerImageSchema.set('toJSON', {
    transform: function(doc, ret) {
        return {
            _id: ret._id,
            villager_id: ret.villager_id,
            image_type: ret.image_type,
            image_data: ret.image_data,
            size: ret.size,
            createdAt: ret.createdAt,
            updatedAt: ret.updatedAt
        };
    }
});

module.exports = mongoose.model('VillagerImage', VillagerImageSchema);