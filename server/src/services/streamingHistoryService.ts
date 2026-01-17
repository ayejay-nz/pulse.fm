import { Readable } from 'node:stream';
import { parseStreamingHistoryZip } from '../parsers/streamingHistoryParser';
import { UploadError, UploadSummary } from '../types/streamingHistoryTypes';
import { addListeningHistory } from '../db/queries/listeningHistory';

const DEFAULT_BATCH_SIZE = 1000;

export async function handleStreamingHistoryUpload(
    zipStream: Readable,
    filename: string,
): Promise<UploadSummary> {
    if (!filename.toLowerCase().endsWith('.zip')) {
        throw new UploadError(400, 'Only .zip files are supported');
    }

    // Temporary user id, will get user id from a users session
    const userId = Number(process.env.PULSEFM_USER_ID);
    if (!Number.isFinite(userId)) {
        throw new UploadError(500, 'Missing PULSEFM_USER_ID');
    }

    return parseStreamingHistoryZip(zipStream, {
        onRecords: async (records) => {
            for (let i = 0; i < records.length; i += DEFAULT_BATCH_SIZE) {
                const batch = records.slice(i, i + DEFAULT_BATCH_SIZE);
                await addListeningHistory(
                    batch.map((record) => ({
                        endedAt: new Date(record.endTime),
                        msPlayed: record.msPlayed,
                        trackId: 1, // TODO:  resolve trackId from tracks table/spotify API
                        userId: userId,
                    })),
                );
            }
        },
    });
}
