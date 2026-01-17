import fastify from 'fastify';
import multipart from '@fastify/multipart';
import 'dotenv/config';
import { UPLOAD_LIMITS } from './constants/uploadLimits';
import { streamingHistoryRoutes } from './routes/streamingHistoryRoutes';

const server = fastify({ logger: true });

await server.register(multipart, {
    limits: { fileSize: UPLOAD_LIMITS.maxZipBytes },
});

await server.register(streamingHistoryRoutes);

const port = Number(process.env.PORT ?? 3000);

try {
    await server.listen({ port: port });
} catch (err) {
    server.log.error(err);
    process.exit(1);
}
