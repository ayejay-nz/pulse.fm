import type { DB } from './types.d.ts';
import { Pool } from 'pg';
import { Kysely, PostgresDialect, CamelCasePlugin } from 'kysely';

const dialect = new PostgresDialect({
    pool: new Pool({
        connectionString: process.env.DATABASE_URL,
    }),
});

export const db = new Kysely<DB>({
    dialect,
    plugins: [new CamelCasePlugin()],
});
