import { db } from '../index';
import { Insertable } from 'kysely';
import { Albums } from '../types';

export async function getAlbumIdsBySpotifyIds(spotifyIds: string[]) {
    if (spotifyIds.length === 0) {
        return new Map<string, number>();
    }

    const rows = await db
        .selectFrom('albums')
        .select(['albumId', 'spotifyId'])
        .where('spotifyId', 'in', spotifyIds)
        .execute();

    return new Map(rows.map((row) => [row.spotifyId, row.albumId]));
}

export async function insertAlbums(albums: Insertable<Albums>[]) {
    if (albums.length === 0) {
        return;
    }

    await db
        .insertInto('albums')
        .values(albums)
        .onConflict((oc) => oc.column('spotifyId').doNothing())
        .execute();
}
