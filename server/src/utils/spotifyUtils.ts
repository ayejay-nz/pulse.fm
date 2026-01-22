export function extractSpotifyTrackId(uri: string) {
    return uri.split(':')[2] ?? null;
}
