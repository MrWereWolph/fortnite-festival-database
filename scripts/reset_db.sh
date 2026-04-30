#!/usr/bin/env bash

set -e

DB_NAME="fortnite_festival"

echo "======================================"
echo " Fortnite Festival Database Reset"
echo "======================================"
echo

echo "Starting PostgreSQL..."
sudo service postgresql start

echo
echo "Dropping existing database if it exists..."
sudo -n runuser -u postgres -- psql -c "DROP DATABASE IF EXISTS ${DB_NAME};"

echo
echo "Creating database..."
sudo -n runuser -u postgres -- createdb "${DB_NAME}"

echo
echo "Running schema script..."
sudo -n runuser -u postgres -- psql -d "${DB_NAME}" -f sql/01_schema.sql

echo
echo "Loading sample data..."
sudo -n runuser -u postgres -- psql -d "${DB_NAME}" -f sql/02_insert_sample_data.sql

echo
echo "Applying roles and permissions..."
sudo -n runuser -u postgres -- psql -d "${DB_NAME}" -f sql/05_roles_permissions.sql

echo
echo "Applying optimization indexes..."
sudo -n runuser -u postgres -- psql -d "${DB_NAME}" -f sql/04_indexes.sql

echo
echo "Verifying table counts..."
sudo -n runuser -u postgres -- psql -d "${DB_NAME}" -c "
SELECT 'tracks' AS table_name, COUNT(*) FROM tracks
UNION ALL SELECT 'artists', COUNT(*) FROM artists
UNION ALL SELECT 'genres', COUNT(*) FROM genres
UNION ALL SELECT 'tags', COUNT(*) FROM tags
UNION ALL SELECT 'track_intensities', COUNT(*) FROM track_intensities
UNION ALL SELECT 'track_artists', COUNT(*) FROM track_artists
UNION ALL SELECT 'track_genres', COUNT(*) FROM track_genres
UNION ALL SELECT 'track_tags', COUNT(*) FROM track_tags;
"

echo
echo "Testing festival_app login..."
PGPASSWORD=password psql -h localhost -U festival_app -d "${DB_NAME}" -c "SELECT title, bpm, musical_key, mode FROM tracks LIMIT 5;"

echo
echo "Database reset complete."
echo
echo "Run the CLI with:"
echo "python3 -m app.cli"