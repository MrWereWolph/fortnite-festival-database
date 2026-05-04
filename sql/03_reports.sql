-- ============================================================
-- Fortnite Festival Database
-- Milestone 4: Advanced Business-Logic Reports
-- ============================================================
-- These queries represent common reporting/search needs for
-- Fortnite Festival Jam Stage users and database maintainers.
-- ============================================================


-- ============================================================
-- Query 1:
-- Find tracks compatible with a Jam Stage session by key, mode,
-- and BPM range. This helps a player quickly find songs that
-- should mix well together during live Jam Stage play.
-- ============================================================

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
-- Query 2:
-- Report the number of tracks and average BPM per genre.
-- Only show genres with at least one track. This helps users
-- understand the musical profile of the database.
-- ============================================================

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
-- Query 3:
-- Find artists with multiple tracks in the database and show
-- their average BPM. This is useful for identifying artists
-- who have enough songs to support themed Jam Stage sessions.
-- ============================================================

SELECT
    a.artist_name,
    COUNT(t.track_id) AS track_count,
    ROUND(AVG(t.bpm), 2) AS average_bpm,
    MIN(t.release_year) AS earliest_release_year,
    MAX(t.release_year) AS latest_release_year
FROM artists a
JOIN track_artists ta
    ON a.artist_id = ta.artist_id
JOIN tracks t
    ON ta.track_id = t.track_id
GROUP BY
    a.artist_id,
    a.artist_name
HAVING COUNT(t.track_id) > 1
ORDER BY
    track_count DESC,
    a.artist_name;


-- ============================================================
-- Query 4:
-- Rank tracks by total instrument intensity. This helps players
-- find songs that are more difficult, energetic, or stem-heavy.
-- The COALESCE function treats missing intensity values as 0.
-- ============================================================

SELECT
    t.title,
    STRING_AGG(a.artist_name, ', ') AS artists,
    t.bpm,
    t.musical_key,
    t.mode,
    COALESCE(ti.vocals, 0) AS vocals,
    COALESCE(ti.lead, 0) AS lead,
    COALESCE(ti.bass, 0) AS bass,
    COALESCE(ti.drums, 0) AS drums,
    (
        COALESCE(ti.vocals, 0)
        + COALESCE(ti.lead, 0)
        + COALESCE(ti.bass, 0)
        + COALESCE(ti.drums, 0)
    ) AS total_standard_intensity
FROM tracks t
JOIN track_intensities ti
    ON t.track_id = ti.track_id
JOIN track_artists ta
    ON t.track_id = ta.track_id
JOIN artists a
    ON ta.artist_id = a.artist_id
GROUP BY
    t.track_id,
    t.title,
    t.bpm,
    t.musical_key,
    t.mode,
    ti.vocals,
    ti.lead,
    ti.bass,
    ti.drums
ORDER BY
    total_standard_intensity DESC,
    t.bpm DESC;


-- ============================================================
-- Query 5:
-- Find tracks that are faster than the average BPM of the whole
-- database. This uses a subquery and helps identify high-tempo
-- songs for energetic Jam Stage sessions.
-- ============================================================

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
-- Query 6:
-- Find tracks by genre and tag combination. This helps users
-- search for practical gameplay categories, such as Rock tracks
-- that are Guitar Focused or Pop tracks that are Good For Mashups.
-- ============================================================

SELECT
    t.title,
    STRING_AGG(DISTINCT a.artist_name, ', ') AS artists,
    STRING_AGG(DISTINCT g.genre_name, ', ') AS genres,
    STRING_AGG(DISTINCT tag.tag_name, ', ') AS tags,
    t.bpm,
    t.musical_key,
    t.mode
FROM tracks t
JOIN track_artists ta
    ON t.track_id = ta.track_id
JOIN artists a
    ON ta.artist_id = a.artist_id
JOIN track_genres tg
    ON t.track_id = tg.track_id
JOIN genres g
    ON tg.genre_id = g.genre_id
JOIN track_tags tt
    ON t.track_id = tt.track_id
JOIN tags tag
    ON tt.tag_id = tag.tag_id
WHERE g.genre_name = 'Rock'
  AND tag.tag_name = 'Guitar Focused'
GROUP BY
    t.track_id,
    t.title,
    t.bpm,
    t.musical_key,
    t.mode
ORDER BY
    t.title;

    -- ============================================================
-- Query 7:
-- Identify suspicious or problematic ISRC values from the API.
-- This report flags ISRC values that are duplicated across
-- multiple tracks or do not match the normal 12-character ISRC
-- pattern. This helps the database maintainer understand why
-- ISRC is stored as metadata instead of being used as a unique key.
-- ============================================================

WITH isrc_summary AS (
    SELECT
        isrc,
        COUNT(*) AS track_count
    FROM tracks
    WHERE isrc IS NOT NULL
      AND TRIM(isrc) <> ''
    GROUP BY isrc
)
SELECT
    t.isrc,
    COUNT(*) OVER (PARTITION BY t.isrc) AS tracks_with_same_isrc,
    LENGTH(t.isrc) AS isrc_length,
    CASE
        WHEN LENGTH(t.isrc) <> 12 THEN 'Length is not 12 characters'
        WHEN t.isrc !~ '^[A-Z0-9]{12}$' THEN 'Contains non-standard ISRC characters'
        WHEN COUNT(*) OVER (PARTITION BY t.isrc) > 1 THEN 'Duplicate ISRC'
        ELSE 'Looks valid'
    END AS issue_type,
    t.epic_slug,
    t.title,
    STRING_AGG(a.artist_name, ', ') AS artists
FROM tracks t
JOIN track_artists ta
    ON t.track_id = ta.track_id
JOIN artists a
    ON ta.artist_id = a.artist_id
JOIN isrc_summary s
    ON t.isrc = s.isrc
WHERE t.isrc IS NOT NULL
  AND TRIM(t.isrc) <> ''
  AND (
        s.track_count > 1
        OR LENGTH(t.isrc) <> 12
        OR t.isrc !~ '^[A-Z0-9]{12}$'
      )
GROUP BY
    t.track_id,
    t.isrc,
    t.epic_slug,
    t.title
ORDER BY
    issue_type,
    t.isrc,
    t.title;