const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');

const { log } = require('./utils/logger.util');
const { initMongo } = require('./utils/mongo.util');
const { initRedis } = require('./utils/redis.util');
const { validateEnvironment } = require('./utils/env.util');

dotenv.config();

validateEnvironment();

const app = express();
log('AUTH API app initialized');

app.use(cors());
log('CORS enabled for all origins');

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
(async () => {
    try {
        await initMongo();
        await initRedis();
        log('MongoDB and Redis initialized');
    } catch (error) {
        log('Initialization error: ' + error.message, 'error');
        process.exit(1);
    }
})();

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        service: 'auth_api',
        timestamp: new Date().toISOString()
    });
});
app.use('/auth', require('./routes/auth.route'));
app.use('/user', require('./routes/user.route'));
app.use('/sso', require('./routes/sso.route'));
app.use('/villager', require('./routes/villager.route'));
app.use('/fish', require('./routes/fish.route'));
app.use('/bug', require('./routes/bug.route'));
app.use('/fossil', require('./routes/fossil.route'));
log('Routes imported');
app.listen(process.env.PORT || 3010, () => {
    log('Server running on port ' + process.env.PORT || 3010);
});