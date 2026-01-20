import { db } from '../index';
import { Insertable } from 'kysely';
import { Artists } from '../types';

export async function getArtistIdsBySpotifyIds(spotifyIds: string[]) {
    if (spotifyIds.length === 0) {
        return new Map<string, number>();
    }

    const rows = await db
        .selectFrom('artists')
        .select(['artistId', 'spotifyId'])
        .where('spotifyId', 'in', spotifyIds)
        .execute();

    return new Map(rows.map((row) => [row.spotifyId, row.artistId]));
}

export async function insertArtists(artists: Insertable<Artists>[]) {
    if (artists.length === 0) {
        return;
    }

    await db
        .insertInto('artists')
        .values(artists)
        .onConflict((oc) => oc.column('spotifyId').doNothing())
        .execute();
}
