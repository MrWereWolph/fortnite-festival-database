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
```

The execution plan showed a `Bitmap Index Scan` on `idx_tracks_key_mode_bpm` with the following index condition:

```sql
musical_key = 'E'
mode = 'Minor'
bpm BETWEEN 115 AND 140
```

This is a strong result because this query represents one of the main goals of the project: helping Fortnite Festival Jam Stage users quickly find songs that are close in BPM and share the same key and mode. The query returned 14 matching rows and completed in approximately 0.360 ms during testing.

Because the query pattern matches the composite index order, PostgreSQL was able to use the index to narrow the matching tracks before performing the joins and aggregation.

### Query B: Artist Search

The artist search used partial text matching:

```sql
artist_name ILIKE '%weeknd%'
```

Even though a trigram index exists on `artists.artist_name`, PostgreSQL still chose a sequential scan on the `artists` table. The execution plan showed that PostgreSQL scanned 387 artist rows and removed 384 by filter.

This is acceptable because 387 rows is still small enough that PostgreSQL may estimate a sequential scan as cheaper than using the trigram index. The query still executed quickly, completing in approximately 0.325 ms during testing.

As the number of artists grows, the trigram index would become more useful for partial artist-name searches.

### Query C: Genre Report

The genre report used joins, grouping, and aggregation to calculate track counts and average BPM by genre.

The query used a sequential scan on `track_genres`, which makes sense because the real API data only contained 53 track/genre relationships. Since the table is small, scanning it directly is efficient.

The query also used primary key index lookups on related tables, including `tracks` and `genres`. The query completed in approximately 0.204 ms during testing and produced the genre-level reporting data needed for the project.

### Query D: Tracks Faster Than Average BPM

The faster-than-average query used a subquery to calculate the average BPM across all tracks, then selected tracks with BPM values above that average.

This query used sequential scans on `tracks`, which is expected because calculating the average BPM requires reading all BPM values. The query also returned a large portion of the database: 340 rows out of 654 tracks. In this situation, using an index would not necessarily be cheaper because the database must process a large part of the table anyway.

This query completed in approximately 1.175 ms during testing.

---

## Why Sequential Scans Still Appear

Some queries still used sequential scans even after indexes were created.

This does not mean the indexes are wrong. PostgreSQL chooses query plans based on estimated cost. If a table is small or if a query needs to read a large portion of the table, a sequential scan can be faster than using an index.

Sequential scans appeared for:

- artist searches over 387 artists
- genre relationship scans over 53 rows
- average BPM calculation over all tracks
- queries that returned or processed a large portion of the available rows

This is expected behavior. Indexes are most useful when they allow PostgreSQL to ignore a large amount of irrelevant data. If most of the table needs to be read anyway, a sequential scan can be the better plan.

---

## Optimization Benefits

The most important optimization success was the compatibility search using the `idx_tracks_key_mode_bpm` index. This index directly supports the project's main use case: finding tracks by musical key, mode, and BPM range.

The trigram indexes are still useful for future growth. They may not always be chosen with the current dataset, but they support partial text searches for song titles and artist names as the database grows.

The junction-table indexes also support future scalability. As more relationship rows are added, indexes on artist, genre, and tag relationship tables will help PostgreSQL find matching tracks more efficiently.

---

## Optimization Conclusion

The optimization results show that the database is structured well for the application's search and reporting needs. After syncing real Fortnite Festival API data, PostgreSQL used the composite key/mode/BPM index for the compatibility search, proving that the indexing strategy supports the project's core feature.

Other queries still used sequential scans where appropriate. This is expected because some tables are still relatively small, and some reports require reading most or all records. Overall, the indexes provide a strong foundation for faster searching and reporting as the database continues to grow.
