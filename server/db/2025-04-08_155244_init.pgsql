CREATE TYPE album_type_enum AS ENUM ('album', 'single', 'compilation');
CREATE TYPE artist_role_enum AS ENUM ('main', 'featured');
CREATE TYPE friendship_status_enum AS ENUM ('accepted', 'pending', 'declined', 'blocked');
CREATE TYPE membership_status_enum AS ENUM ('subscription', 'lifetime');
CREATE TYPE release_date_precision_enum AS ENUM ('year', 'month', 'day');

CREATE TABLE users (
    user_id SERIAL,
    username VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    password_salt TEXT NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP DEFAULT NULL, -- hard delete user after 4 weeks
    PRIMARY KEY (user_id)
);

CREATE TABLE user_subscriptions (
    subscription_id SERIAL,
    user_id INTEGER,
    membership_status membership_status_enum NOT NULL,
    subscribed_at TIMESTAMP NOT NULL,
    subscription_ends TIMESTAMP,
        CHECK (
            (membership_status = 'lifetime' AND subscription_ends IS NULL)
            OR
            (membership_status = 'subscription' AND subscription_ends IS NOT NULL)
        )
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE SET NULL,
    PRIMARY KEY (subscription_id)
);

CREATE TABLE user_spotify_data (
    user_id INTEGER,    
    spotify_user_id TEXT UNIQUE DEFAULT NULL,
    spotify_display_name TEXT DEFAULT NULL,
    access_token TEXT DEFAULT NOT NULL, -- encrypted :)
    refresh_token TEXT DEFAULT NOT NULL, -- encrypted :)
    token_expires_at TIMESTAMP DEFAULT NULL,
    last_fetched_at TIMESTAMP DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE,
    PRIMARY KEY (user_id)
);

CREATE TABLE user_profiles (
    user_id INTEGER,
    bio TEXT,
    avatar_uri TEXT,
    location VARCHAR(255),
    updated_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE,
    PRIMARY KEY (user_id)
);

CREATE TABLE user_privacy_settings (
    user_id INTEGER,
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
    updated_at TIMESTAMP NOT NULL,
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
    followers INTEGER NOT NULL DEFAULT 0,
    popularity INTEGER NOT NULL
        CHECK (popularity BETWEEN 0 AND 100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (artist_id)
);
CREATE INDEX idx_artists_spotify_id ON artists (spotify_id);

CREATE TABLE genres (
    genre_id SERIAL,
    genre_name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
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
    album_type album_type_enum NOT NULL,
    total_tracks INTEGER NOT NULL,
    release_date DATE NOT NULL,
    release_date_precision release_date_precision_enum NOT NULL,
    popularity INTEGER NOT NULL,
        CHECK (popularity BETWEEN 0 AND 100),
    explicit BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (album_id)
);
CREATE INDEX idx_albums_spotify_id ON albums (spotify_id);

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
    spotify_id TEXT NOT NULL UNIQUE,    
    spotify_uri TEXT NOT NULL UNIQUE,
    external_url TEXT NOT NULL,
    disc_number INTEGER NOT NULL,
    track_number INTEGER NOT NULL,
    duration_ms INTEGER NOT NULL,
    popularity INTEGER NOT NULL,
        CHECK (popularity BETWEEN 0 AND 100),
    explicit BOOLEAN NOT NULL,
    album_id INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    FOREIGN KEY (album_id) REFERENCES albums (album_id)
        ON DELETE RESTRICT,
    PRIMARY KEY (track_id)
);
CREATE INDEX idx_tracks_album_id ON tracks (album_id);

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
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    FOREIGN KEY (track_id) REFERENCES tracks (track_id)
        ON DELETE CASCADE,
    PRIMARY KEY (track_id)
);

CREATE TABLE user_playlists (
    playlist_id BIGSERIAL,
    playlist_name VARCHAR(200) NOT NULL,
    playlist_description VARCHAR(512) NOT NULL,
    public_playlist BOOLEAN,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE,
    PRIMARY KEY (playlist_id)
);
CREATE INDEX idx_user_playlists_user_id_playlist_name ON user_playlists (user_id, playlist_name);
CREATE INDEX idx_user_playlists_public_playlist ON user_playlists (public_playlist);

CREATE TABLE playlist_tracks (
    playlist_track_id BIGSERIAL,
    playlist_id BIGINT NOT NULL,
    track_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    added_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (playlist_id, position),
    FOREIGN KEY (playlist_id) REFERENCES user_playlists (playlist_id)
        ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks (track_id)
        ON DELETE CASCADE,
    PRIMARY KEY (playlist_track_id)
);
CREATE INDEX idx_playlist_tracks_track_id ON playlist_tracks (track_id);
CREATE INDEX idx_playlist_tracks_playlist_id_track_id ON playlist_tracks (playlist_id, track_id);
CREATE INDEX idx_playlist_tracks_playlist_id_position ON playlist_tracks (playlist_id, position DESC);
CREATE INDEX idx_playlist_tracks_playlist_id_added_at ON playlist_tracks (playlist_id, added_at DESC);


CREATE TABLE listening_history (
    history_id BIGSERIAL,
    user_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    ms_played INTEGER NOT NULL,
    played_at TIMESTAMPTZ NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks (track_id)
        ON DELETE RESTRICT,
    PRIMARY KEY (history_id)
);
CREATE INDEX idx_listening_history_user_played_at ON listening_history (user_id, played_at DESC);
CREATE INDEX idx_listening_history_user_id_track_id ON listening_history (user_id, track_id);

CREATE TABLE friendships (
    friendship_id SERIAL,
    user_id1 INTEGER NOT NULL,
    user_id2 INTEGER NOT NULL,
    status friendship_status_enum NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL,
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

CREATE TRIGGER trigger_set_updated_at_user_playlists
BEFORE UPDATE ON user_playlists
FOR EACH ROW
WHEN (OLD IS DISTINCT FROM NEW)
EXECUTE FUNCTION set_updated_at();
