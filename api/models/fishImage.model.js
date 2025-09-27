const mongoose = require('mongoose');

const FishImageSchema = new mongoose.Schema({
    fish_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Fish',
        required: true
    },
    image_type: {
        type: String,
        required: true,
        enum: ['full', 'small']
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

FishImageSchema.index({ fish_id: 1, image_type: 1 }, { unique: true });

FishImageSchema.pre('save', function(next) {
    this.updatedAt = new Date();
    next();
});

FishImageSchema.set('toJSON', {
    transform: function(doc, ret) {
        return {
            _id: ret._id,
            fish_id: ret.fish_id,
            image_type: ret.image_type,
            image_data: ret.image_data,
            size: ret.size,
            createdAt: ret.createdAt,
            updatedAt: ret.updatedAt
        };
    }
});

module.exports = mongoose.model('FishImage', FishImageSchema);