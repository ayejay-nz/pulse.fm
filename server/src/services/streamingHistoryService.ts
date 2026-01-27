import { Readable } from 'node:stream';
import { parseStreamingHistoryZip } from '../parsers/streamingHistoryParser';
import { StreamingHistoryRecord, UploadError, UploadSummary } from '../types/streamingHistoryTypes';
import { addListeningHistory } from '../db/queries/listeningHistory';
import { ingestTracksFromSpotify } from './trackIngestService';
import { extractSpotifyTrackId } from '../utils/spotifyUtils';

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

    const byEndTime = new Map<string, StreamingHistoryRecord | StreamingHistoryRecord[]>();

    const summary = await parseStreamingHistoryZip(zipStream, {
        onRecords: async (records) => {
            // Collect duplicates across the whole upload
            for (const record of records) {
                const existing = byEndTime.get(record.endTime);

                if (!existing) {
                    byEndTime.set(record.endTime, record);
                } else if (Array.isArray(existing)) {
                    existing.push(record);
                } else {
                    byEndTime.set(record.endTime, [existing, record]);
                }
            }

            const uniqueTrackUris = Array.from(
                new Set(records.map((record) => record.spotifyTrackUri)),
            );
            const trackIdFromSpotifyId = (await ingestTracksFromSpotify(uniqueTrackUris))
                .trackIdsBySpotifyId;

            for (let i = 0; i < records.length; i += DEFAULT_BATCH_SIZE) {
                const batch = records.slice(i, i + DEFAULT_BATCH_SIZE);

                await addListeningHistory(
                    batch.flatMap((record) => {
                        const spotifyId = extractSpotifyTrackId(record.spotifyTrackUri);
                        if (!spotifyId) return [];

                        const trackId = trackIdFromSpotifyId.get(spotifyId);
                        if (!trackId) return [];

                        return [
                            {
                                endedAt: new Date(record.endTime),
                                msPlayed: record.msPlayed,
                                trackId,
                                userId,
                                offline: record.offline,
                                skipped: record.skipped,
                                incognito: record.incognito,
                                backfilled: record.backfilled,
                            },
                        ];
                    }),
                );
            }
        },
    });

    return summary;
}
