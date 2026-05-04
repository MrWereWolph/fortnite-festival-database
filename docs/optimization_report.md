# Fortnite Festival Database Optimization Report

## Overview

This report documents the optimization strategy used for the Fortnite Festival Database Project. The database is designed to support common Fortnite Festival Jam Stage search and reporting needs, including searching by title, artist, BPM, musical key, mode, genre, tag, and instrument intensity.

The database was first tested with sample data, then later populated with real Fortnite Festival API data using the API sync script. After the API sync, the database contained 654 tracks, 387 artists, 654 track/artist relationships, and 53 track/genre relationships. This made the optimization testing more realistic than testing with only the original 10 sample records.

The optimization process focused on identifying columns that are frequently used in `WHERE` clauses, `JOIN` conditions, `ORDER BY` clauses, and reporting queries. Indexes were created to support those access patterns, and `EXPLAIN ANALYZE` was used to inspect the query plans and execution times.

---

## Queries Tested

The project includes several advanced business-logic queries in `sql/03_reports.sql` and `sql/04_explain_analysis.sql`.

The main queries tested for optimization were:

1. Search compatible tracks by musical key, mode, and BPM range.
2. Search tracks by artist name using partial text matching.
3. Report track count and average BPM by genre.
4. Find tracks faster than the database average BPM.

These queries represent common user and reporting needs for the application.

---

## Indexing Strategy

The database uses both basic and advanced indexes.

Basic indexes were added to support common filtering and lookup columns:

- `tracks.title`
- `tracks.bpm`
- `tracks.musical_key, tracks.mode`
- `tracks.release_year`
- `artists.artist_name`
- `genres.genre_name`
- `tags.tag_name`
- foreign key columns in junction tables

Advanced indexes were added in `sql/04_indexes.sql`:

| Index Name | Table | Purpose |
|---|---|---|
| `idx_tracks_title_trgm` | `tracks` | Supports faster partial title searches. |
| `idx_artists_artist_name_trgm` | `artists` | Supports faster partial artist searches. |
| `idx_tracks_key_mode_bpm` | `tracks` | Supports key, mode, and BPM compatibility searches. |
| `idx_tracks_bpm_desc` | `tracks` | Supports high-BPM sorting and filtering. |
| `idx_track_artists_artist_track` | `track_artists` | Supports joins from artist to track. |
| `idx_track_genres_genre_track` | `track_genres` | Supports joins from genre to track. |
| `idx_track_tags_tag_track` | `track_tags` | Supports joins from tag to track. |

PostgreSQL's `pg_trgm` extension was enabled so the database can use trigram indexes for partial text searches such as `ILIKE '%weeknd%'`.

---

## EXPLAIN ANALYZE Results After API Sync

After syncing real Fortnite Festival API data, the database contained hundreds of rows instead of only the original sample records. This made the query plans more meaningful.

### Query A: Compatible Track Search

The compatible track search filters by musical key, mode, and BPM range.

This query used the composite index:

```sql
idx_tracks_key_mode_bpm