const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: {
        type: String,
        trim: true,
    },
    email: {
        type: String,
        required: true,
        trim: true
    },
    password: {
        type: String,
        required: false,
        select: false
    },
    ssoProviders: [{
        provider: {
            type: String,
            enum: ['apple'],
            required: true
        },
        providerId: {
            type: String,
            required: true
        },
        connectedAt: {
            type: Date,
            default: Date.now
        },
        lastLogin: {
            type: Date,
            default: Date.now
        }
    }],
    role: {
        type: String,
        required: true,
        enum: ['user', 'admin'],
        default: 'user'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});


UserSchema.virtual('hasPassword').get(function() {
    return this.password && this.password.length > 0;
});

UserSchema.set('toJSON', {
    transform: function(doc, ret) {
        return {
            _id: ret._id,
            name: ret.name,
            hasPassword: this.hasPassword,
            ...(ret._includeAllFields && {
                email: ret.email,
                role: ret.role,
                ssoProviders: ret.ssoProviders,
                createdAt: ret.createdAt,
            })
        };
    },
    virtuals: true
});

UserSchema.methods.toFullJSON = function() {
    const obj = this.toObject();

    const hasPasswordValue = obj.password && obj.password.length > 0;

    return {
        _id: obj._id,
        name: obj.name || 'Tom Nook',
        hasPassword: hasPasswordValue,
        email: obj.email,
        role: obj.role,
        ssoProviders: obj.ssoProviders,
        createdAt: obj.createdAt,
    };
};

module.exports = mongoose.model('User', UserSchema);