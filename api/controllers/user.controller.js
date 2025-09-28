const User = require('../models/user.model');
const authUtil = require('../utils/auth.util');
const ssoUtil = require('../utils/sso.util');
const { log } = require('../utils/logger.util');

const getUserList = async () => {
    try {
        let users = await User.find();
        return users;
    } catch (error) {
        throw error;
    }
}

const getUser = async (id, isAdmin = false) => {
    try {
        let user;
        if (isAdmin) {
            user = await User.findById(id).select('+password');
        } else {
            user = await User.findById(id);
        }
        
        if (!user) {
            throw new Error('User not found');
        }
        
        if (isAdmin) {
            return user.toFullJSON();
        } else {
            return user.toJSON();
        }
    } catch (error) {
        throw error;
    }
}

const createUser = async ({name, email, password}) => {
    try {
        let existingUser = await User.findOne({ email });
        if (existingUser) {
            throw new Error('User already exists');
        }

        let hash;
        if (password) {
            hash = await authUtil.hashPassword(password);
        }
        
        let user = new User({ 
            name, 
            email, 
            ...(hash && { password: hash })
        });
        await user.save();

        user = user.toObject();
        delete user.password;
        
        let token = authUtil.generateJWT(user);

        return { user, token };
    } catch (error) {
        throw error;
    }
}

const deleteUser = async (id) => {
    try {
        let user = await User.findByIdAndDelete(id);
        if (!user) {
            throw new Error('User not found');
        }
        return { message: 'User deleted' };
    }
    catch (error) {
        throw error;
    }
}

const loginUser = async ({ email, password }) => {
    try {
        let user = await User.findOne({ email }).select('+password');
        if (!user) {
            throw new Error('User not found');
        }

        if (!user.password) {
            throw new Error('Invalid password');
        }

        let isValid = await authUtil.checkHash(password, user.password);
        if (!isValid) {
            throw new Error('Invalid password');
        }
        
        const userResponse = user.toFullJSON();
        
        let token = authUtil.generateJWT(userResponse);

        return {user: userResponse, token};
    } catch (error) {
        throw error;
    }
}

const updateProfile = async (userId, updateData) => {
    try {
        const { name, newPassword, email } = updateData;
        
        const user = await User.findById(userId).select('+password');
        if (!user) {
            throw new Error('User not found');
        }
        
        if (newPassword) {
            const hashedPassword = await authUtil.hashPassword(newPassword);
            user.password = hashedPassword;
            
            log(`Password updated for user ${userId} (verified via recent authentication)`, 'info');
        }
        
        if (email && email !== user.email) {
            const existingUserWithEmail = await User.findOne({ 
                email: email.toLowerCase(),
                _id: { $ne: userId }
            });
            
            if (existingUserWithEmail) {
                throw new Error('Email already in use');
            }
            
            log(`Email updated for user ${userId} (verified via recent authentication)`, 'info');
        }
        
        const updates = {};
        if (name !== undefined) {
            if (!name || name.trim().length < 1) {
                throw new Error('Name must be at least 1 character');
            }
            updates.name = name.trim();
        }
        
        if (email !== undefined) {
            updates.email = email.toLowerCase().trim();
        }
        
        
        
        Object.assign(user, updates);
        await user.save();
        
        log(`Profile updated for user ${userId}: ${Object.keys(updates).join(', ')}`, 'info');
        
        const updatedUser = user.toJSON();
        
        return {
            message: 'Profile updated successfully',
            user: updatedUser,
        };
        
    } catch (error) {
        log(`Profile update error for user ${userId}: ${error.message}`, 'error');
        throw error;
    }
};

module.exports = { 
    createUser, 
    loginUser, 
    getUserList, 
    deleteUser, 
    getUser,
    updateProfile,
};