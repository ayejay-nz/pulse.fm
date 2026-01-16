import type { Entry } from 'unzipper';
import unzipper from 'unzipper';
import { UPLOAD_LIMITS } from '../constants/uploadLimits';
import { StreamingHistoryRecord, UploadSummary, UploadError } from '../types/streamingHistoryTypes';
import { Readable } from 'node:stream';

type RawStreamingHistoryRecord = {
    ts: string;
    ms_played: number;
    spotify_track_uri: string;
};

function isJsonEntry(entry: Entry) {
    return entry.type === 'File' && entry.path.toLowerCase().endsWith('.json');
}

function isAudioStreamingHistory(entry: Entry) {
    const filename = entry.path.split('/').pop()?.toLowerCase() ?? '';
    return (
        filename.startsWith('streaming_history_audio_') &&
        filename.endsWith('.json')
    );
}

function isRawRecord(value: unknown): value is RawStreamingHistoryRecord {
    if (typeof value !== 'object' || value === null) {
        return false;
    }

    const record = value as Record<string, unknown>;

    return (
        typeof record.ts === 'string' &&
        typeof record.ms_played === 'number' &&
        typeof record.spotify_track_uri === 'string'
    );
}

function mapRawToRecord(raw: RawStreamingHistoryRecord): StreamingHistoryRecord {
    return {
        endTime: raw.ts,
        msPlayed: raw.ms_played,
        spotifyTrackUri: raw.spotify_track_uri,
    };
}

async function readStreamWithLimit(stream: Readable, maxBytes: number) {
    const chunks: Buffer[] = [];
    let totalBytes = 0;

    for await (const chunk of stream) {
        const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
        totalBytes += buffer.length;

        if (totalBytes > maxBytes) {
            stream.destroy(new Error('Zip entry too large'));
            throw new UploadError(413, 'Zip entry too large');
        }

        chunks.push(buffer);
    }

    return { buffer: Buffer.concat(chunks), bytesRead: totalBytes };
}

function parseStreamingHistoryJson(buffer: Buffer): StreamingHistoryRecord[] {
    let parsed: unknown;

    try {
        parsed = JSON.parse(buffer.toString('utf8'));
    } catch (err) {
        throw new UploadError(400, 'Invalid JSON in zip');
    }

    if (!Array.isArray(parsed)) {
        return [];
    }

    return parsed.filter(isRawRecord).map(mapRawToRecord);
}

export async function parseStreamingHistoryZip(zipStream: Readable) {
    const summary: UploadSummary = {
        totalEntries: 0,
        entriesSeen: 0,
        jsonFilesProcessed: 0,
        totalUnzippedBytes: 0,
        recordsParsed: 0,
    };

    const parser = zipStream.pipe(unzipper.Parse({ forceStream: true }));
    for await (const entry of parser) {
        summary.totalEntries += 1;

        if (summary.totalEntries > UPLOAD_LIMITS.maxTotalEntries) {
            entry.autodrain();
            throw new UploadError(413, 'Too many entries in zip');
        }

        if (process.env.LOG_STREAMING_HISTORY_ENTRIES === 'true') {
            console.log(`[streaming-history] entry: ${entry.path}`);
        }

        if (entry.type !== 'File') {
            entry.autodrain();
            continue;
        }

        summary.entriesSeen += 1;

        if (summary.entriesSeen > UPLOAD_LIMITS.maxEntries) {
            entry.autodrain();
            throw new UploadError(413, 'Too many files in zip');
        }

        if (!isJsonEntry(entry)) {
            entry.autodrain();
            continue;
        }

        if (!isAudioStreamingHistory(entry)) {
            entry.autodrain();
            continue;
        }

        summary.jsonFilesProcessed += 1;

        const { buffer, bytesRead } = await readStreamWithLimit(entry, UPLOAD_LIMITS.maxEntryBytes);

        summary.totalUnzippedBytes += bytesRead;
        if (summary.totalUnzippedBytes > UPLOAD_LIMITS.maxUnzippedBytes) {
            throw new UploadError(413, 'Zip contents too large');
        }

        const records = parseStreamingHistoryJson(buffer);

        summary.recordsParsed += records.length;
    }

    return summary;
}
