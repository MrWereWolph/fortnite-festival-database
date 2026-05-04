-- ============================================================
-- Fortnite Festival Database
-- Milestone 3: Physical Schema / DDL
-- Database Platform: PostgreSQL
-- ============================================================

-- Drop tables in dependency order so the script can be rerun safely.
DROP TABLE IF EXISTS track_tags;
DROP TABLE IF EXISTS track_genres;
DROP TABLE IF EXISTS track_artists;
DROP TABLE IF EXISTS track_intensities;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS artists;
DROP TABLE IF EXISTS tracks;
DROP TABLE IF EXISTS sync_runs;

-- ============================================================
-- Core Track Table
-- ============================================================

CREATE TABLE tracks (
    track_id SERIAL PRIMARY KEY,

    epic_slug VARCHAR(100) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,

    release_year INTEGER
        CHECK (
            release_year IS NULL
            OR release_year BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER
        ),

    bpm INTEGER NOT NULL
        CHECK (bpm BETWEEN 80 AND 180),

    musical_key VARCHAR(5) NOT NULL
        CHECK (musical_key IN (
            'C', 'C#', 'Db',
            'D', 'D#', 'Eb',
            'E',
            'F', 'F#', 'Gb',
            'G', 'G#', 'Ab',
            'A', 'A#', 'Bb',
            'B'
        )),

    mode VARCHAR(10) NOT NULL
        CHECK (mode IN ('Major', 'Minor')),

    album_title VARCHAR(200),

    isrc TEXT, -- Unable to use VARCHAR(12) & UNIQUE due to inaccuracies and duplicate values with the official jamtrack endpoint 

    cover_art_url TEXT,
    audio_url TEXT,
    lad_url TEXT,

    jam_code VARCHAR(50),

    active_date TIMESTAMP,
    last_modified TIMESTAMP,

    qi_json JSONB
);

-- ============================================================
-- Lookup Tables
-- ============================================================

CREATE TABLE artists (
    artist_id SERIAL PRIMARY KEY,
    artist_name VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE genres (
    genre_id SERIAL PRIMARY KEY,
    genre_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE tags (
    tag_id SERIAL PRIMARY KEY,
    tag_name VARCHAR(100) NOT NULL UNIQUE
);

-- ============================================================
-- Track Intensity Table
-- One-to-one table connected to tracks.
-- Values are expected to be 0-6 based on Fortnite Festival style
-- difficulty/intensity ratings.
-- ============================================================

CREATE TABLE track_intensities (
    track_id INTEGER PRIMARY KEY
        REFERENCES tracks(track_id)
        ON DELETE CASCADE,

    vocals INTEGER CHECK (vocals IS NULL OR vocals BETWEEN 0 AND 6),
    lead INTEGER CHECK (lead IS NULL OR lead BETWEEN 0 AND 6),
    bass INTEGER CHECK (bass IS NULL OR bass BETWEEN 0 AND 6),
    drums INTEGER CHECK (drums IS NULL OR drums BETWEEN 0 AND 6),

    pro_vocals INTEGER CHECK (pro_vocals IS NULL OR pro_vocals BETWEEN 0 AND 6),
    pro_lead INTEGER CHECK (pro_lead IS NULL OR pro_lead BETWEEN 0 AND 6),
    pro_bass INTEGER CHECK (pro_bass IS NULL OR pro_bass BETWEEN 0 AND 6),
    pro_drums INTEGER CHECK (pro_drums IS NULL OR pro_drums BETWEEN 0 AND 6)
);

-- ============================================================
-- Junction Tables
-- These resolve many-to-many relationships.
-- ============================================================

CREATE TABLE track_artists (
    track_id INTEGER NOT NULL
        REFERENCES tracks(track_id)
        ON DELETE CASCADE,

    artist_id INTEGER NOT NULL
        REFERENCES artists(artist_id)
        ON DELETE RESTRICT,

    PRIMARY KEY (track_id, artist_id)
);

CREATE TABLE track_genres (
    track_id INTEGER NOT NULL
        REFERENCES tracks(track_id)
        ON DELETE CASCADE,

    genre_id INTEGER NOT NULL
        REFERENCES genres(genre_id)
        ON DELETE RESTRICT,

    PRIMARY KEY (track_id, genre_id)
);

CREATE TABLE track_tags (
    track_id INTEGER NOT NULL
        REFERENCES tracks(track_id)
        ON DELETE CASCADE,

    tag_id INTEGER NOT NULL
        REFERENCES tags(tag_id)
        ON DELETE RESTRICT,

    PRIMARY KEY (track_id, tag_id)
);

-- ============================================================
-- Sync Run Tracking
-- ============================================================
-- Records each attempt to populate or refresh the database from
-- an external source such as the Epic Games Spark Tracks API.
-- This table supports maintainability without changing the core
-- track/artist/genre/tag schema.
-- ============================================================

CREATE TABLE sync_runs (
    sync_id SERIAL PRIMARY KEY,

    source_name VARCHAR(100) NOT NULL,
    source_url TEXT NOT NULL,

    synced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    tracks_imported INTEGER NOT NULL
        CHECK (tracks_imported >= 0),

    status VARCHAR(20) NOT NULL
        CHECK (status IN ('success', 'failed')),

    notes TEXT
);

-- ============================================================
-- Basic Indexes
-- These support common searches and joins.
-- More advanced indexes will be added in Milestone 4.
-- ============================================================

CREATE INDEX idx_tracks_title ON tracks(title);
CREATE INDEX idx_tracks_bpm ON tracks(bpm);
CREATE INDEX idx_tracks_key_mode ON tracks(musical_key, mode);
CREATE INDEX idx_tracks_release_year ON tracks(release_year);

CREATE INDEX idx_artists_artist_name ON artists(artist_name);
CREATE INDEX idx_genres_genre_name ON genres(genre_name);
CREATE INDEX idx_tags_tag_name ON tags(tag_name);

CREATE INDEX idx_track_artists_artist_id ON track_artists(artist_id);
CREATE INDEX idx_track_genres_genre_id ON track_genres(genre_id);
CREATE INDEX idx_track_tags_tag_id ON track_tags(tag_id);