import { createClient } from 'redis';

const redis = createClient({
    url: 'redis://localhost:6379'
});

redis.on('error', (error) => {
    console.error('Redis Error:', error);
});

await redis.connect();

console.log('Conectado a Redis');

export default redis;