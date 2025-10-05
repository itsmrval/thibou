const mongoose = require('mongoose');

const FossilImageSchema = new mongoose.Schema({
    fossil_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Fossil',
        required: true
    },
    part_name: {
        type: String,
        required: true,
        trim: true
    },
    image_data: {
        type: String,
        required: true
    },
    size: {
        type: Number,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

FossilImageSchema.index({ fossil_id: 1, part_name: 1 }, { unique: true });

module.exports = mongoose.model('FossilImage', FossilImageSchema);
