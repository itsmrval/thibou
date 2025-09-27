const redis = require('redis');
const { log } = require('./logger.util');

let redisClient;

const initRedis = async function () {
    try {
        if (!process.env.REDIS_URI) {
            throw new Error('REDIS_URI is not defined');
        }

        redisClient = redis.createClient({
            url: process.env.REDIS_URI,
        });

        redisClient.on('error', (err) => {
            log('Redis client error: ' + err.message, 'error');
        });

        await redisClient.connect();
        log('Redis connected successfully', 'info');
    } catch (error) {
        log('Redis connection error: ' + error.message, 'error');
        throw error;
    }
};

const getRedisClient = () => {
    if (!redisClient) {
        throw new Error('Redis client is not initialized');
    }
    return redisClient;
};

module.exports = { initRedis, getRedisClient };
