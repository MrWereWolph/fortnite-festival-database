-- ============================================================
-- Fortnite Festival Database
-- Milestone 5: Security Roles and Permissions
-- ============================================================
-- This script creates controlled database roles for the Python
-- application instead of relying on the postgres superuser.
--
-- Roles:
-- festival_readonly  = can view/search data and run reports
-- festival_app       = can view/search data and insert/update app data
-- ============================================================


-- ============================================================
-- Create roles if they do not already exist.
-- PostgreSQL does not support CREATE ROLE IF NOT EXISTS directly,
-- so we use DO blocks.
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles
        WHERE rolname = 'festival_sync'
    ) THEN
        CREATE ROLE festival_sync WITH LOGIN PASSWORD 'sync_password';
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles
        WHERE rolname = 'festival_readonly'
    ) THEN
        CREATE ROLE festival_readonly WITH LOGIN PASSWORD 'readonly_password';
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles
        WHERE rolname = 'festival_app'
    ) THEN
        CREATE ROLE festival_app WITH LOGIN PASSWORD 'password';
    END IF;
END
$$;

-- ============================================================
-- Sync role
-- This user is used by the API sync script. It can refresh the
-- API-managed data tables and record sync history.
-- ============================================================

GRANT CONNECT ON DATABASE fortnite_festival TO festival_sync;
GRANT USAGE ON SCHEMA public TO festival_sync;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON
    tracks,
    artists,
    genres,
    tags,
    track_intensities,
    track_artists,
    track_genres,
    track_tags
TO festival_sync;

GRANT SELECT, INSERT, UPDATE ON
    sync_runs
TO festival_sync;

GRANT USAGE, SELECT ON SEQUENCE
    tracks_track_id_seq,
    artists_artist_id_seq,
    genres_genre_id_seq,
    tags_tag_id_seq,
    sync_runs_sync_id_seq
TO festival_sync;

-- ============================================================
-- Database connection permissions
-- ============================================================

GRANT CONNECT ON DATABASE fortnite_festival TO festival_readonly;
GRANT CONNECT ON DATABASE fortnite_festival TO festival_app;


-- ============================================================
-- Schema usage permissions
-- ============================================================

GRANT USAGE ON SCHEMA public TO festival_readonly;
GRANT USAGE ON SCHEMA public TO festival_app;


-- ============================================================
-- Read-only role
-- This user can search tracks and view reports, but cannot
-- insert, update, or delete records.
-- ============================================================

GRANT SELECT ON
    tracks,
    artists,
    genres,
    tags,
    track_intensities,
    track_artists,
    track_genres,
    track_tags,
    sync_runs
TO festival_readonly;


-- ============================================================
-- Application role
-- This user can read, insert, and update data.
-- DELETE is intentionally not granted so accidental data loss
-- is prevented through the normal application login.
-- ============================================================

GRANT SELECT, INSERT, UPDATE ON
    tracks,
    artists,
    genres,
    tags,
    track_intensities,
    track_artists,
    track_genres,
    track_tags,
    sync_runs
TO festival_app;


-- ============================================================
-- Sequence permissions
-- SERIAL primary keys use sequences. The app role needs access
-- to use nextval() when inserting new tracks, artists, genres,
-- or tags.
-- ============================================================

GRANT USAGE, SELECT ON SEQUENCE
    tracks_track_id_seq,
    artists_artist_id_seq,
    genres_genre_id_seq,
    tags_tag_id_seq,
    sync_runs_sync_id_seq
TO festival_app;


-- ============================================================
-- Optional: allow read-only user to inspect sequence values.
-- This is not required for reports, but it is harmless.
-- ============================================================

GRANT SELECT ON SEQUENCE
    tracks_track_id_seq,
    artists_artist_id_seq,
    genres_genre_id_seq,
    tags_tag_id_seq,
    sync_runs_sync_id_seq
TO festival_readonly;


-- ============================================================
-- Security notes:
-- 1. The application should connect as festival_app, not postgres.
-- 2. Report-only views could connect as festival_readonly.
-- 3. The application should use parameterized SQL queries.
-- 4. DELETE is not granted to festival_app by default.
-- 5. Schema modification permissions are not granted to either role.
-- ============================================================