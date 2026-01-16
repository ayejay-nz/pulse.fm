import { Readable } from 'node:stream';
import { parseStreamingHistoryZip } from '../parsers/streamingHistoryParser';
import { UploadError, UploadSummary } from '../types/streamingHistoryTypes';

export async function handleStreamingHistoryUpload(
    zipStream: Readable,
    filename: string,
): Promise<UploadSummary> {
    if (!filename.toLowerCase().endsWith('.zip')) {
        throw new UploadError(400, 'Only .zip files are supported');
    }

    return parseStreamingHistoryZip(zipStream);
}
