import { db } from '../index';
import { Insertable } from 'kysely';
import { Tracks } from '../types';

export async function getTrackIdsFromSpotifyIds(spotifyIds: string[]) {
    if (spotifyIds.length === 0) {
        return new Map<string, number>();
    }

    const rows = await db
        .selectFrom('tracks')
        .select(['trackId', 'spotifyId'])
        .where('spotifyId', 'in', spotifyIds)
        .execute();

    return new Map(
        rows.filter((row) => row.spotifyId).map((row) => [row.spotifyId as string, row.trackId]),
    );
}

export async function insertTracks(tracks: Insertable<Tracks>[]) {
    if (tracks.length === 0) {
        return;
    }

    await db
        .insertInto('tracks')
        .values(tracks)
        .onConflict((oc) => oc.column('spotifyId').doNothing())
        .execute();
}
