const mongoose = require('mongoose');

const FossilSchema = new mongoose.Schema({
    name: {
        en: {
            type: String,
            required: true,
            trim: true
        }
    },
    room: {
        type: Number,
        required: true,
        enum: [1, 2, 3],
        min: 1,
        max: 3
    },
    parts: [{
        name: {
            type: String,
            required: true,
            trim: true
        },
        full_name: {
            type: String,
            required: true,
            trim: true
        },
        sell: {
            type: Number,
            required: true,
            min: 0
        },
        width: {
            type: Number,
            required: true
        },
        length: {
            type: Number,
            required: true
        }
    }],
    total_price: {
        type: Number,
        required: true,
        min: 0
    },
    parts_count: {
        type: Number,
        required: true,
        min: 1
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

FossilSchema.pre('save', function(next) {
    this.updatedAt = new Date();
    next();
});

FossilSchema.index({ 'name.en': 1 });
FossilSchema.index({ room: 1 });
FossilSchema.index({ total_price: 1 });

FossilSchema.set('toJSON', {
    virtuals: true,
    transform: function(doc, ret) {
        return {
            _id: ret._id,
            name: ret.name,
            room: ret.room,
            parts: ret.parts,
            total_price: ret.total_price,
            parts_count: ret.parts_count,
            createdAt: ret.createdAt,
            updatedAt: ret.updatedAt
        };
    }
});

module.exports = mongoose.model('Fossil', FossilSchema);
