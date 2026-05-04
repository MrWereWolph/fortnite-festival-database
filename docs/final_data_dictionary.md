# Fortnite Festival Database Final Data Dictionary

## Overview

This document describes the final physical database schema for the Fortnite Festival Database Project.

The database is implemented in PostgreSQL and stores metadata for Fortnite Festival Jam Tracks, including track details, artists, genres, tags, and instrument intensity values. The schema uses normalized relational tables with primary keys, foreign keys, unique constraints, check constraints, and junction tables for many-to-many relationships.

---

# Table: tracks

## Purpose

Stores the main metadata for each Fortnite Festival Jam Track.

| Column Name | Data Type | Key / Constraint | Description |
|---|---|---|---|
| track_id | SERIAL / INTEGER | Primary Key, NOT NULL | Unique database-generated identifier for each track. |
| epic_slug | VARCHAR(100) | UNIQUE, NOT NULL | Unique Epic/Fortnite-style slug used to identify the track. |
| title | VARCHAR(200) | NOT NULL | Name/title of the song. |
| release_year | INTEGER | CHECK: 1900 through current year, nullable | Original release year of the song. |
| bpm | INTEGER | NOT NULL, CHECK: 80-180 | Beats per minute of the track. |
| musical_key | VARCHAR(5) | NOT NULL, CHECK: valid key value | Musical key of the track, such as C, F#, Bb, or E. |
| mode | VARCHAR(10) | NOT NULL, CHECK: Major or Minor | Musical mode of the track. |
| album_title | VARCHAR(200) | Nullable | Album or release title associated with the song. |
| isrc | TEXT | Nullable | ISRC or ISRC-like value from the Fortnite API. Stored as metadata only; not enforced as unique because duplicate and irregular values were found in the source data. |
| cover_art_url | TEXT | Nullable | URL for the track's cover art. |
| audio_url | TEXT | Nullable | URL or reference to audio asset metadata. |
| lad_url | TEXT | Nullable | URL or reference to LAD asset metadata. |
| jam_code | VARCHAR(50) | Nullable | Fortnite Jam Track code, if available. |
| active_date | TIMESTAMP | Nullable | Date/time when the track became active or available. |
| last_modified | TIMESTAMP | Nullable | Date/time when the track metadata was last modified. |
| qi_json | JSONB | Nullable | Raw or semi-structured Fortnite API metadata. |

## Notes

The `tracks` table is the central table of the database. It stores one record per track. Fields such as `epic_slug` and `isrc` are unique to prevent duplicate track records. The `bpm`, `musical_key`, `mode`, and `release_year` columns use check constraints to enforce valid data.

---

# Table: artists

## Purpose

Stores artist names separately from tracks to reduce repeated artist data.

| Column Name | Data Type | Key / Constraint | Description |
|---|---|---|---|
| artist_id | SERIAL / INTEGER | Primary Key, NOT NULL | Unique database-generated identifier for each artist. |
| artist_name | VARCHAR(150) | UNIQUE, NOT NULL | Name of the artist. |

## Notes

Artists are stored separately because one artist can have many tracks, and one track may have multiple artists. This table connects to `tracks` through the `track_artists` junction table.

---

# Table: genres

## Purpose

Stores genre names that can be assigned to tracks.

| Column Name | Data Type | Key / Constraint | Description |
|---|---|---|---|
| genre_id | SERIAL / INTEGER | Primary Key, NOT NULL | Unique database-generated identifier for each genre. |
| genre_name | VARCHAR(100) | UNIQUE, NOT NULL | Name of the genre, such as Pop, Rock, or Rap/Hip-Hop. |

## Notes

Genres are stored separately to avoid repeating genre names across multiple track records. Tracks and genres are connected through the `track_genres` junction table.

---

# Table: tags

## Purpose

Stores flexible descriptive labels that can be assigned to tracks.

| Column Name | Data Type | Key / Constraint | Description |
|---|---|---|---|
| tag_id | SERIAL / INTEGER | Primary Key, NOT NULL | Unique database-generated identifier for each tag. |
| tag_name | VARCHAR(100) | UNIQUE, NOT NULL | Name of the tag, such as High Energy, Good For Mashups, or Guitar Focused. |

## Notes

Tags allow the database to support gameplay-focused categories that may not fit cleanly into a genre. Tracks and tags are connected through the `track_tags` junction table.

---

# Table: track_intensities

## Purpose

Stores instrument intensity ratings for each track.

| Column Name | Data Type | Key / Constraint | Description |
|---|---|---|---|
| track_id | INTEGER | Primary Key, Foreign Key, REFERENCES tracks(track_id), ON DELETE CASCADE | Track associated with these intensity values. |
| vocals | INTEGER | CHECK: 0-6, nullable | Standard vocals intensity rating. |
| lead | INTEGER | CHECK: 0-6, nullable | Standard lead intensity rating. |
| bass | INTEGER | CHECK: 0-6, nullable | Standard bass intensity rating. |
| drums | INTEGER | CHECK: 0-6, nullable | Standard drums intensity rating. |
| pro_vocals | INTEGER | CHECK: 0-6, nullable | Pro vocals intensity rating. |
| pro_lead | INTEGER | CHECK: 0-6, nullable | Pro lead intensity rating. |
| pro_bass | INTEGER | CHECK: 0-6, nullable | Pro bass intensity rating. |
| pro_drums | INTEGER | CHECK: 0-6, nullable | Pro drums intensity rating. |

## Notes

This table has a one-to-one relationship with `tracks`. The `track_id` column is both the primary key and a foreign key. If a track is deleted, its intensity record is deleted automatically because of `ON DELETE CASCADE`.

The table is slightly denormalized for convenience because all instrument intensity values are stored in one row instead of being split into a separate row per instrument.

---

# Table: track_artists

## Purpose

Junction table that connects tracks and artists.

| Column Name | Data Type | Key / Constraint | Description |
|---|---|---|---|
| track_id | INTEGER | Composite Primary Key, Foreign Key, REFERENCES tracks(track_id), ON DELETE CASCADE | Track connected to an artist. |
| artist_id | INTEGER | Composite Primary Key, Foreign Key, REFERENCES artists(artist_id), ON DELETE RESTRICT | Artist connected to a track. |

## Notes

This table resolves the many-to-many relationship between tracks and artists.

A track can have multiple artists, and an artist can appear on multiple tracks. The composite primary key prevents duplicate track/artist pairings.

---

# Table: track_genres

## Purpose

Junction table that connects tracks and genres.

| Column Name | Data Type | Key / Constraint | Description |
|---|---|---|---|
| track_id | INTEGER | Composite Primary Key, Foreign Key, REFERENCES tracks(track_id), ON DELETE CASCADE | Track connected to a genre. |
| genre_id | INTEGER | Composite Primary Key, Foreign Key, REFERENCES genres(genre_id), ON DELETE RESTRICT | Genre connected to a track. |

## Notes

This table resolves the many-to-many relationship between tracks and genres.

A track can have multiple genres, and a genre can apply to multiple tracks. The composite primary key prevents duplicate track/genre pairings.

---

# Table: track_tags

## Purpose

Junction table that connects tracks and tags.

| Column Name | Data Type | Key / Constraint | Description |
|---|---|---|---|
| track_id | INTEGER | Composite Primary Key, Foreign Key, REFERENCES tracks(track_id), ON DELETE CASCADE | Track connected to a tag. |
| tag_id | INTEGER | Composite Primary Key, Foreign Key, REFERENCES tags(tag_id), ON DELETE RESTRICT | Tag connected to a track. |

## Notes

This table resolves the many-to-many relationship between tracks and tags.

A track can have multiple tags, and a tag can apply to multiple tracks. The composite primary key prevents duplicate track/tag pairings.

---

# Table: sync_runs

## Purpose

Records each attempt to populate or refresh the database from an external data source such as the Fortnite Festival Spark Tracks API.

| Column Name | Data Type | Key / Constraint | Description |
|---|---|---|---|
| sync_id | SERIAL / INTEGER | Primary Key, NOT NULL | Unique database-generated identifier for each sync run. |
| source_name | VARCHAR(100) | NOT NULL | Name of the external source used for the sync, such as Epic Games Spark Tracks API. |
| source_url | TEXT | NOT NULL | URL of the external source used for the sync. |
| synced_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Date and time when the sync attempt was recorded. |
| tracks_imported | INTEGER | NOT NULL, CHECK: greater than or equal to 0 | Number of tracks imported during the sync attempt. |
| status | VARCHAR(20) | NOT NULL, CHECK: success or failed | Indicates whether the sync attempt succeeded or failed. |
| notes | TEXT | Nullable | Optional notes about the sync attempt, such as skipped records or error messages. |

## Notes

The `sync_runs` table supports database maintainability by recording when the database was refreshed from the Fortnite Festival API and how many tracks were imported.

This table does not change the core track, artist, genre, or tag relationships. It exists only to track import history and sync status.

---

# Indexes

## Basic Indexes

| Index Name | Table | Column(s) | Purpose |
|---|---|---|---|
| idx_tracks_title | tracks | title | Supports searching and sorting tracks by title. |
| idx_tracks_bpm | tracks | bpm | Supports BPM filtering. |
| idx_tracks_key_mode | tracks | musical_key, mode | Supports key and mode filtering. |
| idx_tracks_release_year | tracks | release_year | Supports release year filtering and reporting. |
| idx_artists_artist_name | artists | artist_name | Supports artist name search. |
| idx_genres_genre_name | genres | genre_name | Supports genre lookup. |
| idx_tags_tag_name | tags | tag_name | Supports tag lookup. |
| idx_track_artists_artist_id | track_artists | artist_id | Supports joining from artists to tracks. |
| idx_track_genres_genre_id | track_genres | genre_id | Supports joining from genres to tracks. |
| idx_track_tags_tag_id | track_tags | tag_id | Supports joining from tags to tracks. |

## Advanced Indexes

| Index Name | Table | Column(s) | Purpose |
|---|---|---|---|
| idx_tracks_title_trgm | tracks | title | Supports faster partial title searches using PostgreSQL trigram indexing. |
| idx_artists_artist_name_trgm | artists | artist_name | Supports faster partial artist searches using PostgreSQL trigram indexing. |
| idx_tracks_key_mode_bpm | tracks | musical_key, mode, bpm | Supports common Jam Stage compatibility searches. |
| idx_tracks_bpm_desc | tracks | bpm DESC | Supports BPM sorting and high-BPM reports. |
| idx_track_artists_artist_track | track_artists | artist_id, track_id | Supports artist-to-track joins. |
| idx_track_genres_genre_track | track_genres | genre_id, track_id | Supports genre-to-track joins. |
| idx_track_tags_tag_track | track_tags | tag_id, track_id | Supports tag-to-track joins. |

---

# Main Relationships

| Relationship | Type | Explanation |
|---|---|---|
| tracks to track_intensities | 1:1 | Each track can have one intensity record. |
| tracks to artists | M:N | A track can have multiple artists, and an artist can have multiple tracks. Resolved by `track_artists`. |
| tracks to genres | M:N | A track can have multiple genres, and a genre can apply to multiple tracks. Resolved by `track_genres`. |
| tracks to tags | M:N | A track can have multiple tags, and a tag can apply to multiple tracks. Resolved by `track_tags`. |
| sync_runs to tracks | No direct relationship | Sync runs record import history but do not directly reference individual tracks. |

---

# Constraint Summary

| Constraint Type | Table(s) | Purpose |
|---|---|---|
| Primary Keys | All main and junction tables | Ensures each record or relationship is uniquely identifiable. |
| Foreign Keys | Junction tables, track_intensities | Enforces valid relationships between tables. |
| UNIQUE | tracks, artists, genres, tags | Prevents duplicate slugs, artist names, genre names, and tag names. ISRC is not unique because duplicate values were found in the API source data. |
| NOT NULL | Required columns | Ensures required data is provided. |
| CHECK | tracks, track_intensities, sync_runs | Enforces valid BPM, key, mode, release year, intensity values, sync status values, and non-negative imported track counts. |
| ON DELETE CASCADE | track_intensities and junction tables referencing tracks | Removes dependent records when a track is deleted. |
| ON DELETE RESTRICT | junction tables referencing artists, genres, and tags | Prevents deleting lookup values while they are still connected to tracks. |

---

# Normalization Summary

## First Normal Form (1NF)

Each table stores atomic values. Columns do not contain repeating groups or multiple values in a single field. Many-to-many relationships are handled through junction tables.

## Second Normal Form (2NF)

Tables with single-column primary keys have all non-key attributes dependent on the full primary key. Junction tables use composite primary keys and do not contain non-key attributes, so they do not contain partial dependencies.

## Third Normal Form (3NF)

Non-key attributes depend on the key, the whole key, and nothing but the key. Artist, genre, and tag names are stored in separate lookup tables instead of being repeated directly in the `tracks` table. Junction tables are used to connect related entities without duplicating data.

## Design Note

The `track_intensities` table is intentionally kept as one row per track with separate columns for vocals, lead, bass, drums, and pro instrument values. This is slightly denormalized compared to a fully generic instrument-rating table, but it improves readability and makes common reports easier to write.

The `isrc` column was originally considered as a possible unique field, but testing against the real Fortnite Festival API showed duplicate and irregular ISRC values. Because of this, the database stores ISRC as flexible text metadata. The `epic_slug` column is used as the unique external track identifier instead.

The `sync_runs` table was added to record API refresh history. It stores when a sync occurred, which source was used, how many tracks were imported, whether the sync succeeded or failed, and any notes about the import.