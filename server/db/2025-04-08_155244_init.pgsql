CREATE TYPE album_type_enum AS ENUM ('album', 'single', 'compilation');
CREATE TYPE artist_role_enum AS ENUM ('main', 'featured');
CREATE TYPE friendship_status_enum AS ENUM ('accepted', 'pending', 'declined', 'blocked');
CREATE TYPE subscription_type_enum AS ENUM ('monthly', 'quarterly', 'semiannual', 'annual', 'lifetime');
CREATE TYPE subscription_status_enum AS ENUM ('active', 'expired', 'cancelled');
CREATE TYPE cancellation_reason_enum AS ENUM ('user_cancelled', 'payment_failed', 'expired_naturally', 'admin_cancelled', 'fraud_suspected', 'account_deleted', 'other');
CREATE TYPE release_date_precision_enum AS ENUM ('year', 'month', 'day');

CREATE TABLE users (
    user_id SERIAL,
    username VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    password_salt TEXT NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id)
);
CREATE INDEX idx_users_is_verified ON users (is_verified);

CREATE TABLE user_subscriptions (
    subscription_id SERIAL,
    user_id INTEGER,
    subscription_type subscription_type_enum NOT NULL,
        CHECK (
            (subscription_type = 'lifetime' AND subscription_ends IS NULL)
            OR
            (subscription_type IN ('monthly', 'quarterly', 'semiannual', 'annual') AND subscription_ends IS NOT NULL)
        ),
    subscription_status subscription_status_enum NOT NULL DEFAULT 'active',
    auto_renewal BOOLEAN NOT NULL DEFAULT TRUE,
    cancellation_reason cancellation_reason_enum DEFAULT NULL,
    next_billing_date TIMESTAMPTZ,
    subscribed_at TIMESTAMPTZ NOT NULL,
    subscription_ends TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE SET NULL,
    PRIMARY KEY (subscription_id)
);
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions (user_id);
CREATE INDEX idx_user_subscriptions_subscription_ends ON user_subscriptions (subscription_ends);

CREATE TABLE user_spotify_data (
    user_id INTEGER NOT NULL,    
    spotify_user_id TEXT UNIQUE DEFAULT NULL,
    spotify_display_name TEXT DEFAULT NULL,
    access_token TEXT NOT NULL, -- encrypted :)
    refresh_token TEXT NOT NULL, -- encrypted :)
    full_history_imported BOOLEAN NOT NULL DEFAULT FALSE,
    history_imported_at TIMESTAMPTZ DEFAULT NULL,
    token_expires_at TIMESTAMPTZ DEFAULT NULL,
    last_fetched_at TIMESTAMPTZ DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE,
    PRIMARY KEY (user_id)
);

CREATE TABLE user_profiles (
    user_id INTEGER NOT NULL,
    bio TEXT,
    avatar_uri TEXT,
    location VARCHAR(255),
    timezone TEXT DEFAULT 'UTC',
    timezone_updated_at TIMESTAMPTZ DEFAULT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE,
    PRIMARY KEY (user_id)
);

CREATE TABLE user_privacy_settings (
    user_id INTEGER NOT NULL,
    is_private BOOLEAN NOT NULL DEFAULT FALSE,
    currently_playing BOOLEAN NOT NULL DEFAULT TRUE,
    recently_played BOOLEAN NOT NULL DEFAULT TRUE,
    top_tracks BOOLEAN NOT NULL DEFAULT TRUE,
    top_artists BOOLEAN NOT NULL DEFAULT TRUE,
    top_albums BOOLEAN NOT NULL DEFAULT TRUE,
    top_genres BOOLEAN NOT NULL DEFAULT TRUE,
    streams BOOLEAN NOT NULL DEFAULT TRUE,
    stream_stats BOOLEAN NOT NULL DEFAULT TRUE,
    friends BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE,
    PRIMARY KEY (user_id)
);

CREATE TABLE artists (
    artist_id SERIAL,
    artist_name TEXT NOT NULL,
    spotify_id TEXT NOT NULL UNIQUE,
    spotify_uri TEXT NOT NULL UNIQUE,
    external_url TEXT NOT NULL,
    image_uri TEXT,
    followers INTEGER NOT NULL DEFAULT 0
        CHECK (followers >= 0),
    popularity INTEGER NOT NULL
        CHECK (popularity BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (artist_id)
);
CREATE INDEX idx_artists_spotify_id ON artists (spotify_id);

CREATE TABLE genres (
    genre_id SERIAL,
    genre_name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (genre_id)
);

CREATE TABLE artist_genres (
    artist_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    FOREIGN KEY (artist_id) REFERENCES artists (artist_id)
        ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres (genre_id)
        ON DELETE RESTRICT,
    PRIMARY KEY (artist_id, genre_id)
);
CREATE INDEX idx_artist_genres_genre_id ON artist_genres (genre_id);

CREATE TABLE albums (
    album_id SERIAL,
    album_name TEXT NOT NULL,
    spotify_id TEXT NOT NULL UNIQUE,
    spotify_uri TEXT NOT NULL UNIQUE,
    external_url TEXT NOT NULL,
    image_uri TEXT,
    album_type album_type_enum NOT NULL,
    total_tracks INTEGER NOT NULL
        CHECK (total_tracks > 0),
    release_date DATE NOT NULL,
    release_date_precision release_date_precision_enum NOT NULL,
    popularity INTEGER NOT NULL,
        CHECK (popularity BETWEEN 0 AND 100),
    explicit BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (album_id)
);
CREATE INDEX idx_albums_spotify_id ON albums (spotify_id);
CREATE INDEX idx_albums_album_type ON albums (album_type);

CREATE TABLE album_artists (
    album_id INTEGER NOT NULL,
    artist_id INTEGER NOT NULL,
    artist_role artist_role_enum NOT NULL DEFAULT 'main',
    FOREIGN KEY (album_id) REFERENCES albums (album_id)
        ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES artists (artist_id)
        ON DELETE RESTRICT,
    PRIMARY KEY (album_id, artist_id)
);
CREATE INDEX idx_album_artists_artist_id ON album_artists (artist_id);

CREATE TABLE tracks (
    track_id SERIAL,
    track_name TEXT NOT NULL,
    spotify_id TEXT UNIQUE,    
    spotify_uri TEXT UNIQUE,
    external_url TEXT,
    image_uri TEXT,
    disc_number INTEGER NOT NULL
        CHECK (disc_number > 0),
    track_number INTEGER NOT NULL
        CHECK (track_number > 0),
    duration_ms INTEGER NOT NULL
        CHECK (duration_ms >= 0),
    popularity INTEGER NOT NULL,
        CHECK (popularity BETWEEN 0 AND 100),
    explicit BOOLEAN NOT NULL,
    album_id INTEGER NOT NULL,
    is_local BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (album_id) REFERENCES albums (album_id)
        ON DELETE RESTRICT,
    PRIMARY KEY (track_id)
);
CREATE INDEX idx_tracks_album_id ON tracks (album_id);
CREATE INDEX idx_tracks_is_local ON tracks (is_local);

CREATE TABLE track_artists (
    track_id INTEGER NOT NULL,
    artist_id INTEGER NOT NULL,
    artist_role artist_role_enum NOT NULL DEFAULT 'main',
    FOREIGN KEY (track_id) REFERENCES tracks (track_id)
        ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES artists (artist_id)
        ON DELETE RESTRICT,
    PRIMARY KEY (track_id, artist_id)
);
CREATE INDEX idx_track_artists_artist_id ON track_artists (artist_id);

CREATE TABLE track_audio_features (
    track_id INTEGER NOT NULL,
    acousticness NUMERIC NOT NULL
        CHECK (acousticness BETWEEN 0 AND 1),
    danceability NUMERIC NOT NULL
        CHECK (danceability BETWEEN 0 AND 1),
    energy NUMERIC NOT NULL
        CHECK (energy BETWEEN 0 AND 1),
    instrumentalness NUMERIC NOT NULL
        CHECK (instrumentalness BETWEEN 0 AND 1),
    key INTEGER NOT NULL
        CHECK (key BETWEEN -1 AND 11),
    liveness NUMERIC NOT NULL
        CHECK (liveness BETWEEN 0 AND 1),
    loudness NUMERIC NOT NULL,
    mode INTEGER NOT NULL
        CHECK (mode IN (0, 1)),
    speechiness NUMERIC NOT NULL
        CHECK (speechiness BETWEEN 0 AND 1),
    tempo NUMERIC NOT NULL
        CHECK (tempo > 0),
    time_signature INTEGER NOT NULL
        CHECK (time_signature BETWEEN 3 AND 7),
    valence NUMERIC NOT NULL
        CHECK (valence BETWEEN 0 AND 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (track_id) REFERENCES tracks (track_id)
        ON DELETE CASCADE,
    PRIMARY KEY (track_id)
);

CREATE TABLE listening_history (
    history_id BIGSERIAL,
    user_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    ms_played INTEGER NOT NULL
        CHECK (ms_played >= 0),
    played_at TIMESTAMPTZ NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks (track_id)
        ON DELETE RESTRICT,
    PRIMARY KEY (history_id)
);
CREATE INDEX idx_listening_history_user_played_at ON listening_history (user_id, played_at DESC);
CREATE INDEX idx_listening_history_user_id_track_id_played_at ON listening_history (user_id, track_id, played_at DESC);
CREATE INDEX idx_listening_history_track_id_played_at ON listening_history (track_id, played_at DESC);

CREATE TABLE friendships (
    friendship_id SERIAL,
    user_id1 INTEGER NOT NULL,
    user_id2 INTEGER NOT NULL,
    status friendship_status_enum NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL,
    CHECK (user_id1 <> user_id2),
    FOREIGN KEY (user_id1) REFERENCES users (user_id)
        ON DELETE CASCADE,
    FOREIGN KEY (user_id2) REFERENCES users (user_id)
        ON DELETE CASCADE,
    PRIMARY KEY (friendship_id)
);
CREATE UNIQUE INDEX ON friendships (LEAST(user_id1, user_id2), GREATEST(user_id1, user_id2));
CREATE INDEX idx_friendships_user_id1 ON friendships (user_id1);
CREATE INDEX idx_friendships_user_id2 ON friendships (user_id2);
CREATE INDEX idx_friendships_status ON friendships (status);

-- Triggers --

CREATE OR REPLACE FUNCTION TRIGGER set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_updated_at_users
BEFORE UPDATE ON users
FOR EACH ROW
WHEN (OLD IS DISTINCT FROM NEW)
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trigger_set_updated_at_user_profiles
BEFORE UPDATE ON user_profiles
FOR EACH ROW
WHEN (OLD IS DISTINCT FROM NEW)
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trigger_set_updated_at_user_privacy_settings
BEFORE UPDATE ON user_privacy_settings
FOR EACH ROW
WHEN (OLD IS DISTINCT FROM NEW)
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trigger_set_updated_at_friendships
BEFORE UPDATE ON friendships
FOR EACH ROW
WHEN (OLD IS DISTINCT FROM NEW)
EXECUTE FUNCTION set_updated_at();
