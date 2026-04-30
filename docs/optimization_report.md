# Fortnite Festival Database Optimization Report

## Overview

This report documents the optimization strategy used for the Fortnite Festival Database Project. The database is designed to support common Fortnite Festival Jam Stage search and reporting needs, including searching by title, artist, BPM, musical key, mode, genre, tag, and instrument intensity.

The optimization process focused on identifying columns that are frequently used in `WHERE` clauses, `JOIN` conditions, `ORDER BY` clauses, and reporting queries. Indexes were created to support those access patterns, and `EXPLAIN ANALYZE` was used to compare query execution plans.

---

## Queries Tested

The project includes several advanced business-logic queries in `sql/03_reports.sql` and `sql/04_indexes.sql`.

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

PostgreSQL's `pg_trgm` extension was also enabled so the database can use trigram indexes for partial text searches such as `ILIKE '%weeknd%'`.

---

## EXPLAIN ANALYZE Results

When running `EXPLAIN ANALYZE`, PostgreSQL produced valid execution plans for each query. The plans showed a mix of sequential scans, hash joins, nested loops, bitmap scans, sorts, and aggregate operations.

For the artist search query, PostgreSQL used a sequential scan on the `artists` table even after the trigram index was created. The plan showed that only 10 artist rows existed, and PostgreSQL removed 9 rows by filter while finding the matching artist. This is expected because the table is extremely small. With only 10 rows, scanning the entire table is cheaper than using an index.

For the genre report query, PostgreSQL also used sequential scans and hash joins. This makes sense because the report aggregates across most of the available records. When a query needs to read most or all rows in a table, indexes are often less useful because the database has to process nearly the entire table anyway.

For the compatible track search query, the database filtered tracks by musical key, mode, and BPM range. Although a composite index exists on `(musical_key, mode, bpm)`, PostgreSQL still chose a sequential scan in the small sample dataset. Again, this is expected because the `tracks` table only has 10 rows. In a larger real-world dataset, this index would become more valuable because it would allow PostgreSQL to narrow down matching tracks without scanning the full table.

---

## Why Sequential Scans Still Appear

The sample database contains only 10 tracks, 10 artists, 10 genres, 10 tags, and a small number of junction-table rows. Because of this, PostgreSQL often chooses sequential scans instead of indexes.

This does not mean the indexes are wrong. It means the database optimizer has determined that reading a few rows directly is faster than loading and traversing an index. Indexes have overhead, and for very small tables, that overhead can cost more than a simple table scan.

This is an important part of query optimization: indexes are not automatically used just because they exist. PostgreSQL chooses the plan it estimates will be cheapest.

---

## Expected Benefits With Larger Data

The indexes would become more useful as the database grows.

In a real Fortnite Festival database with hundreds or thousands of tracks, artists, tags, and relationship rows, the indexes would improve performance for:

- title searches
- artist searches
- BPM range filters
- key and mode filters
- genre and tag joins
- compatibility searches
- high-BPM reports
- repeated application queries

The trigram indexes would be especially useful for partial text searches. For example, a user searching for part of an artist name or song title would benefit from the GIN trigram indexes as the number of records grows.

The composite index on `(musical_key, mode, bpm)` is also important because it matches one of the application's main search patterns: finding songs that share a key, mode, and nearby BPM range for Jam Stage mixing.

---

## Optimization Conclusion

The optimization results show that the database is correctly structured for future growth, even though the current sample dataset is too small to show dramatic performance gains. PostgreSQL often chose sequential scans because the tables contain very few rows. This is expected behavior and does not indicate a problem with the indexing strategy.

The indexes created in this project are still useful because they support the application's intended real-world workload. As the dataset grows, these indexes would help reduce query cost, improve search speed, and make the application more responsive for users searching tracks by title, artist, BPM, key, mode, genre, and tag.