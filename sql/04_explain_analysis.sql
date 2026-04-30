-- ============================================================
-- Fortnite Festival Database
-- Milestone 4: EXPLAIN ANALYZE Testing
-- ============================================================
-- This script is used to record query execution plans and costs.
--
-- Recommended testing process:
-- 1. Run sql/01_schema.sql
-- 2. Run sql/02_insert_sample_data.sql
-- 3. Run this file before sql/04_indexes.sql
-- 4. Run sql/04_indexes.sql
-- 5. Run this file again after indexes are created
--
-- The before/after output can be compared for the optimization
-- report.
-- ============================================================


-- ============================================================
-- Query A:
-- Search tracks by key, mode, and BPM range.
-- This supports Jam Stage compatibility searches.
-- ============================================================

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


-- ============================================================
-- Query B:
-- Search by artist name using partial text matching.
-- This supports common user searches.
-- ============================================================

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


-- ============================================================
-- Query C:
-- Genre report with aggregation.
-- This supports database reporting and analytics.
-- ============================================================

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


-- ============================================================
-- Query D:
-- Find tracks faster than the database average BPM.
-- This uses a subquery.
-- ============================================================

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