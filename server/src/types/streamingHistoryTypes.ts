export type UploadSummary = {
    totalEntries: number;
    entriesSeen: number;
    jsonFilesProcessed: number;
    totalUnzippedBytes: number;
    recordsParsed: number;
};

export type StreamingHistoryRecord = {
    backfilled?: boolean;
    endTime: string;
    incognito: boolean;
    msPlayed: number;
    skipped: boolean;
    spotifyTrackUri: string; // The rest of the track data can be gathered via the Spotify API
    offline: boolean;
};

export class UploadError extends Error {
    statusCode: number;

    constructor(statusCode: number, message: string) {
        super(message);
        this.statusCode = statusCode;
    }
}
