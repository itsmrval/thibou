const mongoose = require('mongoose');

const FishSchema = new mongoose.Schema({
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
        enum: ['river', 'pond', 'sea', 'pier'],
        trim: true
    },
    price: {
        cj: {
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
        enum: ['common', 'uncommon', 'rare'],
        trim: true
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

FishSchema.pre('save', function(next) {
    this.updatedAt = new Date();
    next();
});
FishSchema.index({ 'name.en': 1 });
FishSchema.index({ location: 1 });
FishSchema.index({ rarity: 1 });
FishSchema.index({ 'price.shop': 1 });

FishSchema.set('toJSON', {
    virtuals: true,
    transform: function(doc, ret) {
        return {
            _id: ret._id,
            name: ret.name,
            location: ret.location,
            price: ret.price,
            availability: ret.availability,
            rarity: ret.rarity,
            createdAt: ret.createdAt,
            updatedAt: ret.updatedAt
        };
    }
});

module.exports = mongoose.model('Fish', FishSchema);