import { db } from '../index.js';
import { ListeningHistory } from '../types.js';
import { Insertable } from 'kysely';

export async function addListeningHistory(history: Insertable<ListeningHistory>[]) {
    return await db.insertInto('listeningHistory').values(history).execute();
}
