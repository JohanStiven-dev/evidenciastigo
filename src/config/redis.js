const Redis = require('ioredis');
const { REDIS_URL } = require('./env');

const redisClient = new Redis(REDIS_URL || 'redis://localhost:6379');

redisClient.on('connect', () => {
  console.log('Connected to Redis!');
});

redisClient.on('error', (err) => {
  console.error('Redis connection error:', err);
});

module.exports = redisClient;
