import { Insertable } from 'kysely';
import { getAlbumIdsBySpotifyIds, insertAlbums } from '../db/queries/albums';
import { getArtistIdsBySpotifyIds, insertArtists } from '../db/queries/artists';
import { getTrackIdsFromSpotifyIds, insertTracks } from '../db/queries/tracks';
import { SpotifyAlbum, SpotifyArtist, SpotifyTrack } from '../types/spotifyApiTypes';
import { getAlbums, getArtists, getTracks } from './spotifyClient';
import { Albums, Artists, Tracks, ReleaseDatePrecisionEnum } from '../db/types';
import { TrackIngestResult } from '../types/trackIngestionTypes';

function extractSpotifyTrackId(uri: string) {
    return uri.split(':')[2] ?? null;
}

function toReleaseDate(releaseDate: string) {
    const parts = releaseDate.split('-');

    const year = parts[0] || '1970';
    const month = parts[1] || '01';
    const day = parts[2] || '01';

    return `${year.padStart(4, '0')}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
}

function mapAlbums(albums: SpotifyAlbum[]): Insertable<Albums>[] {
    return albums.map((album) => ({
        albumName: album.name,
        albumType: album.albumType,
        explicit: album.restrictions.reason === 'explicit',
        externalUrl: album.externalUrls.spotify,
        imageUri: album.images[0]?.url ?? null,
        popularity: album.popularity,
        releaseDate: toReleaseDate(album.releaseDate),
        releaseDatePrecision: album.releaseDatePrecision as ReleaseDatePrecisionEnum,
        spotifyId: album.id,
        spotifyUri: album.uri,
        totalTracks: album.totalTracks,
    }));
}

function mapArtists(artists: SpotifyArtist[]): Insertable<Artists>[] {
    return artists.map((artist) => ({
        artistName: artist.name,
        externalUrl: artist.externalUrls.spotify,
        followers: artist.followers.total,
        imageUri: artist.images[0]?.url ?? null,
        popularity: artist.popularity,
        spotifyId: artist.id,
        spotifyUri: artist.uri,
    }));
}

function mapTracks(tracks: SpotifyTrack[], albumIds: Map<string, number>): Insertable<Tracks>[] {
    return tracks
        .map((track) => {
            const albumId = albumIds.get(track.album.id);
            if (!albumId) return null;

            return {
                albumId,
                discNumber: track.discNumber,
                durationMs: track.durationMs,
                explicit: track.explicit,
                externalUrl: track.externalUrls.spotify,
                imageUri: track.album.images[0]?.url ?? null,
                isLocal: track.isLocal,
                popularity: track.popularity,
                spotifyId: track.id,
                spotifyUri: track.uri,
                trackName: track.name,
                trackNumber: track.trackNumber,
            };
        })
        .filter((row) => !!row);
}

export async function ingestTracksFromSpotify(trackUris: string[]): Promise<TrackIngestResult> {
    const spotifyIds = Array.from(
        new Set(trackUris.map(extractSpotifyTrackId).filter(Boolean) as string[]),
    );

    const existingTrackIds = await getTrackIdsFromSpotifyIds(spotifyIds);
    const missingTrackIds = spotifyIds.filter((id) => !existingTrackIds.has(id));

    if (missingTrackIds.length === 0) {
        return {
            trackIdsBySpotifyId: existingTrackIds,
            missingTrackIds: [],
        };
    }

    const tracks = await getTracks(missingTrackIds);

    const albumIdsToFetch = Array.from(
        new Set(tracks.map((track) => track.album.id).filter(Boolean)),
    );
    const artistIdsToFetch = Array.from(
        new Set(tracks.flatMap((track) => track.artists.map((artist) => artist.id))),
    );

    const existingAlbumsIds = await getAlbumIdsBySpotifyIds(albumIdsToFetch);
    const existingArtistIds = await getArtistIdsBySpotifyIds(artistIdsToFetch);

    const missingAlbumIds = albumIdsToFetch.filter((id) => !existingAlbumsIds.has(id));
    const missingArtistIds = artistIdsToFetch.filter((id) => !existingArtistIds.has(id));

    const [albums, artists] = await Promise.all([
        missingAlbumIds.length ? getAlbums(missingAlbumIds) : Promise.resolve([]),
        missingArtistIds.length ? getArtists(missingArtistIds) : Promise.resolve([]),
    ]);

    await insertAlbums(mapAlbums(albums));
    await insertArtists(mapArtists(artists));
    await insertTracks(mapTracks(tracks, existingAlbumsIds));

    return {
        trackIdsBySpotifyId: existingTrackIds,
        missingTrackIds,
    };
}
