#!/usr/bin/env bash

set -e

DB_NAME="fortnite_festival"

sudo -n runuser -u postgres -- psql -d "${DB_NAME}" -c "
SELECT 'tracks' AS table_name, COUNT(*) FROM tracks
UNION ALL SELECT 'artists', COUNT(*) FROM artists
UNION ALL SELECT 'genres', COUNT(*) FROM genres
UNION ALL SELECT 'tags', COUNT(*) FROM tags
UNION ALL SELECT 'track_intensities', COUNT(*) FROM track_intensities
UNION ALL SELECT 'track_artists', COUNT(*) FROM track_artists
UNION ALL SELECT 'track_genres', COUNT(*) FROM track_genres
UNION ALL SELECT 'track_tags', COUNT(*) FROM track_tags
UNION ALL SELECT 'sync_runs', COUNT(*) FROM sync_runs;
"