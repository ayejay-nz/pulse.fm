import type { FastifyInstance } from 'fastify';
import { handleStreamingHistoryUpload } from '../services/streamingHistoryService';
import { UploadError } from '../types/streamingHistoryTypes';

export async function streamingHistoryRoutes(fastify: FastifyInstance) {
    fastify.post('/upload/streaming-history', async (request, reply) => {
        const part = await request.file();

        if (!part) {
            return reply.code(400).send({ error: 'Missing zip file' });
        }

        try {
            const summary = await handleStreamingHistoryUpload(part.file, part.filename);

            return reply.send({ ok: true, summary });
        } catch (err) {
            if (err instanceof UploadError) {
                return reply.code(err.statusCode).send({ error: err.message });
            }

            request.log.error({ error: err }, 'Streaming history upload failed');
            return reply.code(400).send({ error: 'Invalid zip file' });
        }
    });
}
