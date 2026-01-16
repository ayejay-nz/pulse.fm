export type UploadSummary = {
    entriesSeen: number;
    jsonFilesProcessed: number;
    totalUnzippedBytes: number;
    recordsParsed: number;
};

export type StreamingHistoryRecord = {
    endTime: string;
    msPlayed: number;
    trackUri: string; // The rest of the track data can be gathered via the Spotify API
};

export class UploadError extends Error {
    statusCode: number;

    constructor(statusCode: number, message: string) {
        super(message);
        this.statusCode = statusCode;
    }
}
