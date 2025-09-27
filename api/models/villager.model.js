const mongoose = require('mongoose');

const VillagerSchema = new mongoose.Schema({
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
    title_color: {
        type: String,
        required: true,
        match: /^[0-9a-fA-F]{6}$/
    },
    text_color: {
        type: String,
        required: true,
        match: /^[0-9a-fA-F]{6}$/
    },
    species: {
        type: String,
        required: true,
        enum: [
            'alligator', 'anteater', 'bear', 'bear cub', 'bird', 'bull', 'cat',
            'chicken', 'cow', 'deer', 'dog', 'duck', 'eagle', 'elephant', 'frog',
            'goat', 'gorilla', 'hamster', 'hippo', 'horse', 'kangaroo', 'koala',
            'lion', 'monkey', 'mouse', 'octopus', 'ostrich', 'penguin', 'pig',
            'rabbit', 'rhinoceros', 'sheep', 'squirrel', 'tiger', 'wolf'
        ]
    },
    personality: {
        type: String,
        required: true,
        enum: ['normal', 'peppy', 'snooty', 'uchi', 'lazy', 'jock', 'cranky', 'smug']
    },
    gender: {
        type: String,
        required: true,
        enum: ['male', 'female']
    },
    birthday_date: {
        type: String,
        required: true,
        match: /^\d{2}-\d{2}$/
    },
    sign: {
        type: String,
        required: true,
        enum: ['aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo', 'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces']
    },
    quote: {
        en: {
            type: String,
            required: true,
            trim: true
        },
    },
    house: {
        roof: {
            type: String,
            trim: true,
            minlength: 3
        },
        siding: {
            type: String,
            trim: true,
            minlength: 3
        },
        door: {
            type: String,
            trim: true,
            minlength: 3
        }
    },
    islander: {
        type: Boolean,
        required: true,
        default: false
    },
    debut: {
        type: String,
        required: true,
    },
    appearances: {
        DNM: String,
        AC: String,
        E_PLUS: String,
        CF: String,
        NL: String,
        NH: String,
        PC: String
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



VillagerSchema.pre('save', function(next) {
    this.updatedAt = new Date();
    next();
});

VillagerSchema.index({ 'name.en': 1 });
VillagerSchema.index({ species: 1 });
VillagerSchema.index({ personality: 1 });
VillagerSchema.index({ gender: 1 });

VillagerSchema.set('toJSON', {
    virtuals: true,
    transform: function(doc, ret) {
        return {
            _id: ret._id,
            name: ret.name,
            title_color: ret.title_color,
            text_color: ret.text_color,
            species: ret.species,
            personality: ret.personality,
            gender: ret.gender,
            birthday_date: ret.birthday_date,
            sign: ret.sign,
            quote: ret.quote,
            house: ret.house,
            islander: ret.islander,
            debut: ret.debut,
            appearances: ret.appearances,
            createdAt: ret.createdAt,
            updatedAt: ret.updatedAt
        };
    }
});

module.exports = mongoose.model('Villager', VillagerSchema);