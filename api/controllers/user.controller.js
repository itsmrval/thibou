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

const getIslandResidents = async (userId) => {
    try {
        const user = await User.findById(userId);
        if (!user) {
            throw new Error('User not found');
        }

        const Villager = require('../models/villager.model');
        const residents = user.island?.residents || [];

        const residentNames = residents.map(r => r.name);
        const villagers = await Villager.find({ 'name.en': { $in: residentNames } });

        const residentsWithId = residents.map(r => {
            const villager = villagers.find(v => v.name.en === r.name);
            return {
                id: villager?.id,
                name: r.name,
                favorite: r.favorite
            };
        });

        return residentsWithId;
    } catch (error) {
        throw error;
    }
};

const getLikes = async (userId) => {
    try {
        const user = await User.findById(userId);
        if (!user) {
            throw new Error('User not found');
        }

        const Villager = require('../models/villager.model');
        const likeNames = user.island?.likes || [];

        const villagers = await Villager.find({ 'name.en': { $in: likeNames } });

        return villagers;
    } catch (error) {
        throw error;
    }
};

const updateResidents = async (userId, residents) => {
    try {
        if (!Array.isArray(residents)) {
            throw new Error('Residents must be an array');
        }

        if (residents.length > 10) {
            throw new Error('Maximum 10 residents');
        }

        const favoriteCount = residents.filter(r => r.favorite).length;
        if (favoriteCount > 3) {
            throw new Error('Maximum 3 favorites');
        }

        const names = residents.map(r => r.name);
        const uniqueNames = [...new Set(names)];
        if (uniqueNames.length !== names.length) {
            throw new Error('Duplicate villager names are not allowed');
        }

        const user = await User.findById(userId);
        if (!user) {
            throw new Error('User not found');
        }

        if (!user.island) {
            user.island = { residents: [], likes: [], updatedAt: new Date() };
        }

        user.island.residents = residents;
        user.island.updatedAt = new Date();
        await user.save();

        const Villager = require('../models/villager.model');
        const residentNames = residents.map(r => r.name);
        const villagers = await Villager.find({ 'name.en': { $in: residentNames } });

        const residentsWithId = residents.map(r => {
            const villager = villagers.find(v => v.name.en === r.name);
            return {
                id: villager?.id,
                name: r.name,
                favorite: r.favorite
            };
        });

        log(`Island residents updated for user ${userId}: ${residents.length} residents, ${favoriteCount} favorites`, 'info');

        return {
            residents: residentsWithId,
            likes: user.island.likes || [],
            updatedAt: user.island.updatedAt
        };
    } catch (error) {
        log(`Island residents update error for user ${userId}: ${error.message}`, 'error');
        throw error;
    }
};


const addLike = async (userId, villagerName) => {
    try {
        const user = await User.findById(userId);
        if (!user) {
            throw new Error('User not found');
        }

        if (!user.island) {
            user.island = { residents: [], likes: [], updatedAt: new Date() };
        }

        if (user.island.likes.includes(villagerName)) {
            throw new Error('Villager already liked');
        }

        user.island.likes.push(villagerName);
        user.island.updatedAt = new Date();
        await user.save();

        const Villager = require('../models/villager.model');
        const villagers = await Villager.find({ 'name.en': { $in: user.island.likes } });

        log(`Like added for user ${userId}: ${villagerName}`, 'info');

        return villagers;
    } catch (error) {
        log(`Add like error for user ${userId}: ${error.message}`, 'error');
        throw error;
    }
};

const removeLike = async (userId, villagerName) => {
    try {
        const user = await User.findById(userId);
        if (!user) {
            throw new Error('User not found');
        }

        if (!user.island) {
            user.island = { residents: [], likes: [], updatedAt: new Date() };
        }

        user.island.likes = user.island.likes.filter(name => name !== villagerName);
        user.island.updatedAt = new Date();
        await user.save();

        const Villager = require('../models/villager.model');
        const villagers = await Villager.find({ 'name.en': { $in: user.island.likes } });

        log(`Like removed for user ${userId}: ${villagerName}`, 'info');

        return villagers;
    } catch (error) {
        log(`Remove like error for user ${userId}: ${error.message}`, 'error');
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
    getIslandResidents,
    getLikes,
    updateResidents,
    addLike,
    removeLike,
};