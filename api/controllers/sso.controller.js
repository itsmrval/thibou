const User = require('../models/user.model');
const authUtil = require('../utils/auth.util');
const ssoUtil = require('../utils/sso.util');
const { log } = require('../utils/logger.util');

const ssoAuth = async ({ token, provider, name }) => {
    try {
        const ssoData = await ssoUtil.verifySSOToken(token, provider);
        
        let userBySSO = await User.findOne({
            'ssoProviders.providerId': ssoData.providerId,
            'ssoProviders.provider': provider
        });

        if (userBySSO) {
            const existingProvider = userBySSO.ssoProviders.find(p => 
                p.provider === provider && p.providerId === ssoData.providerId
            );
            existingProvider.lastLogin = new Date();
            await userBySSO.save();
            
            log(`SSO login successful for user ${userBySSO._id} via ${provider}`, 'info');
            

            const userWithPassword = await User.findById(userBySSO._id).select('+password');
            const userObj = userWithPassword.toFullJSON();
            console.log("DEBUG: SSO response user object:", JSON.stringify(userObj, null, 2));
            const authToken = authUtil.generateJWT(userObj);
            return { user: userObj, token: authToken };
        }

        const userByEmail = await User.findOne({ email: ssoData.email });
        
        if (userByEmail) {
            throw new Error('User already registered with other sign in method');
        }
        
        const user = new User({
            name: name,
            email: ssoData.email,
            ssoProviders: [{
                provider: ssoData.provider,
                providerId: ssoData.providerId,
                connectedAt: new Date(),
                lastLogin: new Date()
            }]
        });
        await user.save();
        
        log(`New user created via ${provider}: ${user._id}`, 'info');
        
        const userWithPassword = await User.findById(user._id).select('+password');
        const userObj = userWithPassword.toFullJSON();
        const authToken = authUtil.generateJWT(userObj);
        return { user: userObj, token: authToken };
        
    } catch (error) {
        log(`SSO authentication failed: ${error.message}`, 'error');
        throw error;
    }
};

const linkSSOProvider = async (userId, { token, provider }) => {
    try {
        const ssoData = await ssoUtil.verifySSOToken(token, provider);
        
        const user = await User.findById(userId);
        if (!user) {
            throw new Error('User not found');
        }

        const existingProvider = user.ssoProviders.find(p => p.provider === provider);
        if (existingProvider) {
            throw new Error('Provider already linked');
        }

        const existingSSOUser = await User.findOne({
            'ssoProviders.providerId': ssoData.providerId,
            'ssoProviders.provider': provider
        });
        if (existingSSOUser && existingSSOUser._id.toString() !== userId) {
            log(`Link SSO provider failed for user ${userId}: account already linked`, 'error');
            throw new Error('SSO account already linked to another user');
        }

        user.ssoProviders.push({
            provider: ssoData.provider,
            providerId: ssoData.providerId,
            connectedAt: new Date(),
            lastLogin: new Date()
        });
        await user.save();

        log(`Linked ${provider} SSO provider to user ${userId}`, 'info');
        return { message: 'SSO provider linked successfully' };
    } catch (error) {
        log(`Link SSO provider failed for user ${userId}: ${error.message}`, 'error');
        throw error;
    }
};

const unlinkSSOProvider = async (userId, provider) => {
    try {
        const user = await User.findById(userId).select('+password');
        if (!user) {
            throw new Error('User not found');
        }

        const providerIndex = user.ssoProviders.findIndex(p => p.provider === provider);
        if (providerIndex === -1) {
            throw new Error('Provider not linked');
        }

        if (!user.password && user.ssoProviders.length === 1) {
            throw new Error('Cannot unlink last authentication method');
        }

        user.ssoProviders.splice(providerIndex, 1);
        await user.save();

        return { message: 'SSO provider unlinked successfully' };
    } catch (error) {
        log(`Unlink SSO provider failed for user ${userId}: ${error.message}`, 'error');
        throw error;
    }
};

module.exports = { 
    ssoAuth, 
    linkSSOProvider, 
    unlinkSSOProvider 
};