-- ============================================================
-- Fortnite Festival Database
-- Milestone 4: Index Creation Script
-- ============================================================
-- This script creates indexes that support common search,
-- filtering, sorting, and reporting needs.
--
-- This file is safe to run during database setup/reset because
-- it only creates indexes and does not print EXPLAIN plans.
-- ============================================================


-- ============================================================
-- PostgreSQL Extension
-- ============================================================
-- pg_trgm supports trigram indexes for faster partial text search
-- with patterns such as ILIKE '%weeknd%'.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;


-- ============================================================
-- Trigram Indexes for Partial Text Search
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_tracks_title_trgm
ON tracks USING GIN (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_artists_artist_name_trgm
ON artists USING GIN (artist_name gin_trgm_ops);


-- ============================================================
-- Track Search and Filtering Indexes
-- ============================================================

-- Supports common Jam Stage compatibility search:
-- musical key + mode + BPM range.
CREATE INDEX IF NOT EXISTS idx_tracks_key_mode_bpm
ON tracks (musical_key, mode, bpm);

-- Supports BPM sorting and high-BPM reports.
CREATE INDEX IF NOT EXISTS idx_tracks_bpm_desc
ON tracks (bpm DESC);


-- ============================================================
-- Junction Table Indexes
-- ============================================================
-- Primary keys already help one direction of the join.
-- These composite indexes help when searching from a lookup table
-- back to matching tracks.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_track_artists_artist_track
ON track_artists (artist_id, track_id);

CREATE INDEX IF NOT EXISTS idx_track_genres_genre_track
ON track_genres (genre_id, track_id);

CREATE INDEX IF NOT EXISTS idx_track_tags_tag_track
ON track_tags (tag_id, track_id);