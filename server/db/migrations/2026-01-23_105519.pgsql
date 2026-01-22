BEGIN;

ALTER TABLE listening_history DROP COLUMN offline_synced_at;

COMMIT;
