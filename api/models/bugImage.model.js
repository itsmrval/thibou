const mongoose = require('mongoose');

const BugImageSchema = new mongoose.Schema({
    bug_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Bug',
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

BugImageSchema.index({ bug_id: 1, image_type: 1 }, { unique: true });

BugImageSchema.pre('save', function(next) {
    this.updatedAt = new Date();
    next();
});

BugImageSchema.set('toJSON', {
    transform: function(doc, ret) {
        return {
            _id: ret._id,
            bug_id: ret.bug_id,
            image_type: ret.image_type,
            image_data: ret.image_data,
            size: ret.size,
            createdAt: ret.createdAt,
            updatedAt: ret.updatedAt
        };
    }
});

module.exports = mongoose.model('BugImage', BugImageSchema);