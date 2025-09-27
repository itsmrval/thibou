const { getRedisClient } = require('../utils/redis.util');
const { log } = require('../utils/logger.util');

const ratelimitMiddleware = (ratelimitCount = 10) => {
    return async (req, res, next) => {
        try {
            if (!process.env.RATE_LIMIT_WINDOW) {
                throw new Error('Rate limit window configuration is not defined');
            }

            const redisClient = getRedisClient();
            const key = `ratelimit:${req.ip}:${req.originalUrl}`;
            const windowMs = parseInt(process.env.RATE_LIMIT_WINDOW, 10);

            const requestCount = await redisClient.incr(key);

            if (requestCount === 1) {
                await redisClient.expire(key, windowMs / 1000);
            }

            if (requestCount > ratelimitCount) {
                log(`Rate limit exceed for ${req.ip} on ${req.originalUrl}`, 'warn');
                return res.status(429).json({ message: 'Rate limit exceed for that endpoint', requestCount, ratelimitCount });
            }

            res.setHeader('X-RateLimit-Limit', ratelimitCount);
            res.setHeader('X-RateLimit-Remaining', Math.max(ratelimitCount - requestCount, 0));

            next();
        } catch (error) {
            throw error;
        }
    };
};

module.exports = { ratelimitMiddleware };
