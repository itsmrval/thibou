const mongoose = require('mongoose');
const { log } = require('./logger.util');

const initMongo = async function () {
    try {
        if (!process.env.MONGO_URI) {
            throw new Error('MONGO_URI is not defined');
        }

        const options = {
            dbName: 'tb_api'
        };

        const conn = await mongoose.connect(process.env.MONGO_URI, options);
        log(`MongoDB connected: ${conn.connection.host}`, 'info');
    } catch (error) {
        log(error, 'error');
        process.exit(1);
    }
};

module.exports = { initMongo };
