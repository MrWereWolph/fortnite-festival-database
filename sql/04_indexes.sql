-- ============================================================
-- Fortnite Festival Database
-- Milestone 4: Optimization and Indexing
-- ============================================================
-- This script documents optimization testing for the advanced
-- report/search queries in sql/03_reports.sql.
--
-- NOTE:
-- Some basic indexes already exist from 01_schema.sql.
-- This file adds stronger search-focused indexes and includes
-- EXPLAIN ANALYZE statements to compare execution plans.
-- ============================================================


-- ============================================================
-- PART 1: EXPLAIN ANALYZE BEFORE ADVANCED INDEXES
-- ============================================================

-- Query A:
-- Search tracks by key, mode, and BPM range.
-- This supports Jam Stage compatibility searches.

EXPLAIN ANALYZE
SELECT
    t.track_id,
    t.title,
    STRING_AGG(a.artist_name, ', ') AS artists,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
FROM tracks t
JOIN track_artists ta
    ON t.track_id = ta.track_id
JOIN artists a
    ON ta.artist_id = a.artist_id
WHERE t.musical_key = 'E'
  AND t.mode = 'Minor'
  AND t.bpm BETWEEN 115 AND 140
GROUP BY
    t.track_id,
    t.title,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
ORDER BY
    ABS(t.bpm - 124),
    t.title;


-- Query B:
-- Search by artist name and return track metadata.
-- This supports a common user search pattern.

EXPLAIN ANALYZE
SELECT
    t.title,
    a.artist_name,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
FROM tracks t
JOIN track_artists ta
    ON t.track_id = ta.track_id
JOIN artists a
    ON ta.artist_id = a.artist_id
WHERE a.artist_name ILIKE '%weeknd%'
ORDER BY t.title;


-- Query C:
-- Genre report with aggregation.
-- This supports database reporting and analytics.

EXPLAIN ANALYZE
SELECT
    g.genre_name,
    COUNT(t.track_id) AS track_count,
    ROUND(AVG(t.bpm), 2) AS average_bpm,
    MIN(t.bpm) AS slowest_bpm,
    MAX(t.bpm) AS fastest_bpm
FROM genres g
JOIN track_genres tg
    ON g.genre_id = tg.genre_id
JOIN tracks t
    ON tg.track_id = t.track_id
GROUP BY
    g.genre_id,
    g.genre_name
HAVING COUNT(t.track_id) >= 1
ORDER BY
    track_count DESC,
    average_bpm DESC;


-- Query D:
-- Find tracks faster than the database average BPM.
-- This uses a subquery.

EXPLAIN ANALYZE
SELECT
    t.title,
    STRING_AGG(a.artist_name, ', ') AS artists,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
FROM tracks t
JOIN track_artists ta
    ON t.track_id = ta.track_id
JOIN artists a
    ON ta.artist_id = a.artist_id
WHERE t.bpm > (
    SELECT AVG(bpm)
    FROM tracks
)
GROUP BY
    t.track_id,
    t.title,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
ORDER BY
    t.bpm DESC;


-- ============================================================
-- PART 2: ADVANCED INDEXES
-- ============================================================
-- These indexes support the most common search patterns:
-- title search, artist search, BPM filtering, key/mode filtering,
-- and many-to-many join performance.
-- ============================================================

-- Enable trigram search support for faster partial text searches.
-- This helps ILIKE searches such as '%weeknd%' or '%sand%'.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Trigram indexes for flexible partial text search.
CREATE INDEX IF NOT EXISTS idx_tracks_title_trgm
ON tracks USING GIN (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_artists_artist_name_trgm
ON artists USING GIN (artist_name gin_trgm_ops);

-- Composite index for the most common Jam Stage compatibility search:
-- key + mode + BPM range.
CREATE INDEX IF NOT EXISTS idx_tracks_key_mode_bpm
ON tracks (musical_key, mode, bpm);

-- Index for BPM-only filtering and sorting.
CREATE INDEX IF NOT EXISTS idx_tracks_bpm_desc
ON tracks (bpm DESC);

-- Join support indexes.
-- Primary keys already help one direction of joins, but these help
-- when filtering from artist/genre/tag back to matching tracks.
CREATE INDEX IF NOT EXISTS idx_track_artists_artist_track
ON track_artists (artist_id, track_id);

CREATE INDEX IF NOT EXISTS idx_track_genres_genre_track
ON track_genres (genre_id, track_id);

CREATE INDEX IF NOT EXISTS idx_track_tags_tag_track
ON track_tags (tag_id, track_id);


-- ============================================================
-- PART 3: EXPLAIN ANALYZE AFTER ADVANCED INDEXES
-- ============================================================

-- Query A after indexes.

EXPLAIN ANALYZE
SELECT
    t.track_id,
    t.title,
    STRING_AGG(a.artist_name, ', ') AS artists,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
FROM tracks t
JOIN track_artists ta
    ON t.track_id = ta.track_id
JOIN artists a
    ON ta.artist_id = a.artist_id
WHERE t.musical_key = 'E'
  AND t.mode = 'Minor'
  AND t.bpm BETWEEN 115 AND 140
GROUP BY
    t.track_id,
    t.title,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
ORDER BY
    ABS(t.bpm - 124),
    t.title;


-- Query B after indexes.

EXPLAIN ANALYZE
SELECT
    t.title,
    a.artist_name,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
FROM tracks t
JOIN track_artists ta
    ON t.track_id = ta.track_id
JOIN artists a
    ON ta.artist_id = a.artist_id
WHERE a.artist_name ILIKE '%weeknd%'
ORDER BY t.title;


-- Query C after indexes.

EXPLAIN ANALYZE
SELECT
    g.genre_name,
    COUNT(t.track_id) AS track_count,
    ROUND(AVG(t.bpm), 2) AS average_bpm,
    MIN(t.bpm) AS slowest_bpm,
    MAX(t.bpm) AS fastest_bpm
FROM genres g
JOIN track_genres tg
    ON g.genre_id = tg.genre_id
JOIN tracks t
    ON tg.track_id = t.track_id
GROUP BY
    g.genre_id,
    g.genre_name
HAVING COUNT(t.track_id) >= 1
ORDER BY
    track_count DESC,
    average_bpm DESC;


-- Query D after indexes.

EXPLAIN ANALYZE
SELECT
    t.title,
    STRING_AGG(a.artist_name, ', ') AS artists,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
FROM tracks t
JOIN track_artists ta
    ON t.track_id = ta.track_id
JOIN artists a
    ON ta.artist_id = a.artist_id
WHERE t.bpm > (
    SELECT AVG(bpm)
    FROM tracks
)
GROUP BY
    t.track_id,
    t.title,
    t.bpm,
    t.musical_key,
    t.mode,
    t.release_year
ORDER BY
    t.bpm DESC;