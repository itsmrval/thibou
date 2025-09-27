const { log } = require('./logger.util');

const requiredEnvVars = [
    'JWT_SECRET',
    'MONGO_URI',
    'REDIS_URI',
    'APPLE_CLIENT_ID',
    'APPLE_TEAM_ID',
    'APPLE_KEY_ID',
    'APPLE_P8_KEY_PATH'
];


const optionalEnvVars = [
    'PORT',
    'APPLE_CLIENT_ID_IOS',
    'SYSTEM_KEY'
];

const validateEnvironment = () => {
    const missing = [];
    const warnings = [];

    for (const envVar of requiredEnvVars) {
        if (!process.env[envVar]) {
            missing.push(envVar);
        }
    }

    for (const envVar of optionalEnvVars) {
        if (!process.env[envVar]) {
            warnings.push(envVar);
        }
    }

    if (missing.length > 0) {
        log(`Missing required environment variables: ${missing.join(', ')}`, 'error');
        log('Please check your .env file and ensure all required variables are set', 'error');
        process.exit(1);
    }

    if (warnings.length > 0) {
        log(`Optional environment variables not set: ${warnings.join(', ')}`, 'warn');
        
        if (!process.env.PORT) {
            log('Using default port 3010', 'info');
        }
    }

    log('Environment validation completed successfully', 'info');
};

const checkSSOProvider = (provider) => {
    if (provider !== 'apple') {
        throw new Error(`Provider '${provider}' is not supported. Only Apple SSO is currently supported.`);
    }
    
    if (!process.env.APPLE_CLIENT_ID) {
        throw new Error(`Apple SSO is not configured. Missing APPLE_CLIENT_ID.`);
    }
    
    return true;
};

module.exports = {
    validateEnvironment,
    checkSSOProvider
};