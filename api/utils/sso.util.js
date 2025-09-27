const https = require('https');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const { checkSSOProvider } = require('./env.util');

const verifyAppleToken = async (identityToken) => {
    try {
        if (!process.env.APPLE_TEAM_ID || !process.env.APPLE_KEY_ID || !process.env.APPLE_P8_KEY_PATH) {
            throw new Error('Apple P8 configuration missing. Required: APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_P8_KEY_PATH');
        }
        
        checkSSOProvider('apple');

        const p8Path = process.env.APPLE_P8_KEY_PATH;
        if (!fs.existsSync(p8Path)) {
            throw new Error(`Apple P8 key file not found at: ${p8Path}`);
        }
        
        const p8Key = fs.readFileSync(p8Path, 'utf8');

        const [header, payload, signature] = identityToken.split('.');
        if (!header || !payload || !signature) {
            throw new Error('Invalid token structure');
        }
        
        const decodedHeader = JSON.parse(Buffer.from(header, 'base64url').toString());
        const decodedPayload = JSON.parse(Buffer.from(payload, 'base64url').toString());

        if (decodedPayload.iss !== 'https://appleid.apple.com') {
            throw new Error('Invalid issuer');
        }

        const allowedClientIds = getAppleClientIds();
        if (!allowedClientIds.includes(decodedPayload.aud)) {
            throw new Error(`Invalid audience. Expected one of: ${allowedClientIds.join(', ')}. Got: ${decodedPayload.aud}`);
        }

        if (Date.now() > decodedPayload.exp * 1000) {
            throw new Error('Token expired');
        }

        if ((Date.now() - decodedPayload.iat * 1000) > 600000) {
            throw new Error('Token too old');
        }

        if (!decodedPayload.sub) {
            throw new Error('Missing subject');
        }

        const now = Math.floor(Date.now() / 1000);
        const clientAssertion = jwt.sign({
            iss: process.env.APPLE_TEAM_ID,
            iat: now,
            exp: now + 3600,
            aud: 'https://appleid.apple.com',
            sub: process.env.APPLE_CLIENT_ID
        }, p8Key, {
            algorithm: 'ES256',
            header: {
                kid: process.env.APPLE_KEY_ID,
                typ: 'JWT'
            }
        });

        return {
            providerId: decodedPayload.sub,
            email: decodedPayload.email,
            emailVerified: decodedPayload.email_verified === 'true' || decodedPayload.email_verified === true,
            provider: 'apple',
            name: decodedPayload.name,
            clientId: decodedPayload.aud
        };
        
    } catch (error) {
        throw new Error('Apple P8 token validation failed: ' + error.message);
    }
};

const getAppleClientIds = () => {
    const clientIds = [];

    if (process.env.APPLE_CLIENT_ID) {
        clientIds.push(process.env.APPLE_CLIENT_ID);
    }

    if (process.env.APPLE_CLIENT_ID_IOS) {
        clientIds.push(process.env.APPLE_CLIENT_ID_IOS);
    }

    return [...new Set(clientIds)];
};



const verifySSOToken = async (token, provider) => {
    if (provider !== 'apple') {
        throw new Error('Only Apple SSO is currently supported');
    }
    return await verifyAppleToken(token);
};

const generateAppleLoginUrl = (redirectUri, state, platform = 'principal') => {
    checkSSOProvider('apple');
    
    let clientId;
    if (platform === 'ios') {
        clientId = process.env.APPLE_CLIENT_ID_IOS || process.env.APPLE_CLIENT_ID;
    } else {
        clientId = process.env.APPLE_CLIENT_ID;
    }
    
    const params = new URLSearchParams({
        client_id: clientId,
        redirect_uri: redirectUri,
        response_type: 'code id_token',
        scope: 'name email',
        response_mode: 'form_post',
        state: state || crypto.randomBytes(16).toString('hex')
    });
    
    return {
        url: `https://appleid.apple.com/auth/authorize?${params.toString()}`,
        state: params.get('state'),
        clientId: clientId
    };
};


const generateLoginUrl = (provider, redirectUri, state, platform = 'principal') => {
    if (provider !== 'apple') {
        throw new Error('Only Apple SSO is currently supported');
    }
    return generateAppleLoginUrl(redirectUri, state, platform);
};

module.exports = {
    verifySSOToken,
    generateLoginUrl
};