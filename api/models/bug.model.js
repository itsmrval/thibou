const mongoose = require('mongoose');

const BugSchema = new mongoose.Schema({
    name: {
        en: {
            type: String,
            required: true,
            trim: true
        },
        jp: {
            type: String,
            trim: true
        },
        fr: {
            type: String,
            trim: true
        },
        es: {
            type: String,
            trim: true
        },
        de: {
            type: String,
            trim: true
        },
        it: {
            type: String,
            trim: true
        },
        ko: {
            type: String,
            trim: true
        },
        zh: {
            type: String,
            trim: true
        },
        nl: {
            type: String,
            trim: true
        },
        ru: {
            type: String,
            trim: true
        }
    },
    location: {
        type: String,
        required: true,
        enum: ['flying', 'trees', 'ground', 'flowers', 'water', 'rocks', 'stumps', 'villagers', 'special'],
        trim: true
    },
    weather: {
        type: String,
        required: true,
        enum: ['any', 'rain'],
        trim: true
    },
    price: {
        flick: {
            type: Number,
            required: true,
            min: 0
        },
        shop: {
            type: Number,
            required: true,
            min: 0
        }
    },
    availability: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    rarity: {
        type: String,
        required: true,
        enum: ['very_common', 'common', 'uncommon', 'rare'],
        trim: true,
        default: 'common'
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

BugSchema.pre('save', function(next) {
    this.updatedAt = new Date();
    next();
});

BugSchema.index({ 'name.en': 1 });
BugSchema.index({ location: 1 });
BugSchema.index({ weather: 1 });
BugSchema.index({ rarity: 1 });
BugSchema.index({ 'price.shop': 1 });

BugSchema.set('toJSON', {
    virtuals: true,
    transform: function(doc, ret) {
        return {
            _id: ret._id,
            name: ret.name,
            location: ret.location,
            weather: ret.weather,
            price: ret.price,
            availability: ret.availability,
            rarity: ret.rarity,
            createdAt: ret.createdAt,
            updatedAt: ret.updatedAt
        };
    }
});

module.exports = mongoose.model('Bug', BugSchema);