export type TrackIngestResult = {
    trackIdsBySpotifyId: Map<string, number>;
    missingTrackIds: string[];
};
