#!/usr/bin/env bash

set -e

DB_NAME="fortnite_festival"

echo "======================================"
echo " Fortnite Festival Real API Setup"
echo "======================================"
echo

echo "Step 1: Resetting database with schema, sample data, roles, and indexes..."
./scripts/reset_db.sh

echo
echo "Step 2: Syncing real Fortnite Festival API data..."
python3 scripts/sync_fortnite_api.py

echo
echo "Step 3: Verifying final table counts..."
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

echo
echo "Step 4: Showing latest sync status..."
PGPASSWORD=password psql -h localhost -U festival_app -d "${DB_NAME}" -c "
SELECT sync_id, source_name, tracks_imported, status, synced_at
FROM sync_runs
ORDER BY synced_at DESC
LIMIT 5;
"

echo
echo "Real API setup complete."
echo
echo "Run the CLI with:"
echo "python3 -m app.cli"