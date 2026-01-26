BEGIN;

ALTER TABLE listening_history 
    DROP COLUMN created_at,
    ADD COLUMN skipped BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN incognito BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN backfilled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE TABLE listening_history_raw (
    history_id BIGINT,
    raw_ts TIMESTAMPTZ,
    offline_timestamp BIGINT,
    platform TEXT,
    conn_country TEXT,
    reason_start TEXT,
    reason_end TEXT,
    shuffle BOOLEAN,
    FOREIGN KEY (history_id) REFERENCES listening_history (history_id)
        ON DELETE CASCADE,
    PRIMARY KEY (history_id)
);

COMMIT;
