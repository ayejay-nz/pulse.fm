import { db } from '../index';
import { ListeningHistory } from '../types';
import { Insertable } from 'kysely';

export async function addListeningHistory(history: Insertable<ListeningHistory>[]) {
    return await db.insertInto('listeningHistory').values(history).execute();
}
