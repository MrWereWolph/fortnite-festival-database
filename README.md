# Fortnite Festival Database Project

## Project Overview

This project is a PostgreSQL and Python database application for managing and analyzing Fortnite Festival Jam Tracks.

The database stores track metadata such as title, artist, BPM, musical key, mode, release year, genre, tags, ISRC metadata, asset URLs, and instrument intensity values. The purpose of the project is to help Fortnite Festival Jam Stage players search for compatible songs more efficiently and to demonstrate database design, normalization, SQL optimization, security, and Python application integration.

The project supports both sample data and real Fortnite Festival API data. The sample data is useful for predictable testing, while the API sync script refreshes the database with current real track metadata.

---

## Main Features

- PostgreSQL relational database
- Normalized schema using separate tables for tracks, artists, genres, tags, and junction relationships
- Sample data population script
- Real Fortnite Festival API sync script
- Sync history tracking with `sync_runs`
- Advanced SQL reporting queries
- SQL indexing and optimization examples using `EXPLAIN ANALYZE`
- Database roles and permissions
- Python CLI application
- Safe parameterized SQL queries
- User-friendly database error handling
- App-side input validation
- One-command reset scripts for sample data or real API data

---

## Project Structure

```text
fortnite-festival-database/
│
├── app/
│   ├── __init__.py
│   ├── cli.py
│   ├── db.py
│   ├── errors.py
│   ├── reports.py
│   └── tracks.py
│
├── docs/
│   ├── explain_outputs/
│   │   └── explain_after_api_sync.txt
│   ├── final_data_dictionary.md
│   └── optimization_report.md
│
├── scripts/
│   ├── reset_db.sh
│   ├── reset_and_sync_api.sh
│   └── sync_fortnite_api.py
│
├── sql/
│   ├── 01_schema.sql
│   ├── 02_insert_sample_data.sql
│   ├── 03_reports.sql
│   ├── 04_indexes.sql
│   ├── 04_explain_analysis.sql
│   └── 05_roles_permissions.sql
│
├── .env.example
├── README.md
└── requirements.txt
```

---

## Database Platform

This project uses **PostgreSQL**.

PostgreSQL was selected because it supports:

- strong relational constraints
- primary keys and foreign keys
- `CHECK`, `UNIQUE`, and `NOT NULL` constraints
- user roles and permissions
- `EXPLAIN ANALYZE`
- B-tree indexes
- GIN/trigram indexes for partial text searching
- Python and Django integration

---

## Required Software

In GitHub Codespaces, most tools are already available. The project requires:

- Python 3
- PostgreSQL
- pip
- Git

Python packages are listed in `requirements.txt`:

```txt
psycopg2-binary
python-dotenv
tabulate
requests
```

Install Python dependencies:

```bash
pip install -r requirements.txt
```

---

## Environment Setup

Create a `.env` file from the example file:

```bash
cp .env.example .env
```

The `.env` file should contain:

```env
DB_NAME=fortnite_festival
DB_USER=festival_app
DB_PASSWORD=password
DB_HOST=localhost
DB_PORT=5432

SYNC_DB_USER=festival_sync
SYNC_DB_PASSWORD=sync_password

FORTNITE_SPARK_TRACKS_URL=https://fortnitecontent-website-prod07.ol.epicgames.com/content/api/pages/fortnite-game/spark-tracks
```

The normal CLI connects as `festival_app`. The API sync script connects as `festival_sync`, which has broader refresh permissions.

---

## Starting PostgreSQL in Codespaces

Start the PostgreSQL service:

```bash
sudo service postgresql start
```

Verify that PostgreSQL is accepting connections:

```bash
pg_isready -h localhost -p 5432
```

Expected output:

```text
localhost:5432 - accepting connections
```

---

## Quick Setup Option 1: Sample/Test Data

Use this script when you want a predictable test database with the 10-record sample dataset:

```bash
./scripts/reset_db.sh
```

This script:

1. Starts PostgreSQL.
2. Drops and recreates the `fortnite_festival` database.
3. Runs the schema script.
4. Loads sample data.
5. Applies roles and permissions.
6. Applies indexes.
7. Verifies table counts.
8. Tests the `festival_app` login.

---

## Quick Setup Option 2: Real Fortnite API Data

Use this script when you want the database populated with real Fortnite Festival API data:

```bash
./scripts/reset_and_sync_api.sh
```

This script:

1. Runs `scripts/reset_db.sh`.
2. Runs `scripts/sync_fortnite_api.py`.
3. Replaces the sample track data with current API data.
4. Shows final table counts.
5. Shows the latest API sync status.

During testing, the API sync imported:

```text
654 tracks
387 artists
6 genres
5 tags
```

These numbers may change over time as Epic updates Fortnite Festival metadata.

---

## Manual Database Setup

If you do not use the reset scripts, the database can be created manually.

Create the database:

```bash
sudo -n runuser -u postgres -- createdb fortnite_festival
```

Verify the database exists:

```bash
sudo -n runuser -u postgres -- psql -l
```

Run the schema script:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/01_schema.sql
```

Run the sample data script:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/02_insert_sample_data.sql
```

Run the roles and permissions script:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/05_roles_permissions.sql
```

Run the index script:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/04_indexes.sql
```

Optional: run the API sync script:

```bash
python3 scripts/sync_fortnite_api.py
```

---

## SQL Scripts

| File | Purpose |
|---|---|
| `sql/01_schema.sql` | Creates the database tables, primary keys, foreign keys, check constraints, and basic indexes. |
| `sql/02_insert_sample_data.sql` | Loads sample data for predictable testing. |
| `sql/03_reports.sql` | Contains advanced business-logic report queries. |
| `sql/04_indexes.sql` | Creates advanced indexes for optimization. |
| `sql/04_explain_analysis.sql` | Runs `EXPLAIN ANALYZE` on important report/search queries. |
| `sql/05_roles_permissions.sql` | Creates and grants database roles and permissions. |

---

## Scripts

| File | Purpose |
|---|---|
| `scripts/reset_db.sh` | Rebuilds the database with schema, sample data, roles, and indexes. |
| `scripts/sync_fortnite_api.py` | Fetches Fortnite Festival Spark Tracks API data and imports it into PostgreSQL. |
| `scripts/reset_and_sync_api.sh` | Rebuilds the database and then syncs real Fortnite API data. |

---

## Verifying the Tables

To list tables:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -c "\dt"
```

To inspect the `tracks` table:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -c "\d tracks"
```

To verify row counts:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -c "
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
```

To view sync history:

```bash
psql -h localhost -U festival_app -d fortnite_festival -c "
SELECT sync_id, source_name, tracks_imported, status, synced_at, notes
FROM sync_runs
ORDER BY synced_at DESC
LIMIT 5;
"
```

---

## Running the Python CLI

Run the CLI from the project root:

```bash
python3 -m app.cli
```

The CLI menu includes:

```text
1. Search tracks by title
2. Search tracks by artist
3. Find compatible tracks by key/mode/BPM
4. View genre report
5. View artist report
6. View highest intensity tracks
7. Add a new track
8. View latest API sync status
9. Exit
```

---

## Example CLI Searches

Search by title:

```text
Option: 1
Search: sand
Result limit: press Enter for default
```

Search by artist:

```text
Option: 2
Search: weeknd
Result limit: press Enter for default
```

Find compatible tracks:

```text
Option: 3
Key: E
Mode: Minor
Minimum BPM: 115
Maximum BPM: 140
Target BPM: 124
Result limit: press Enter for default
```

View sync status:

```text
Option: 8
```

---

## Security Implementation

The project uses SQL-level and application-level security.

SQL-level security:

- The application connects as `festival_app`, not as the PostgreSQL superuser.
- `festival_app` is granted `SELECT`, `INSERT`, and `UPDATE`.
- `festival_app` is not granted `DELETE` or `TRUNCATE`.
- Schema modification permissions are not granted to the application user.
- A separate `festival_readonly` role is included for report-only access.
- A separate `festival_sync` role is included for API refresh operations.

Application-level security:

- Python database operations use parameterized SQL queries.
- User input is passed through placeholders such as `%s`.
- Input is not directly concatenated into SQL strings.
- The application validates BPM, release year, key, mode, and required fields before inserting a new track.
- The CLI applies result limits so large reports do not flood the terminal.

---

## Error Handling

The CLI catches common database errors and displays user-friendly messages.

Handled errors include:

- duplicate values
- foreign key violations
- check constraint violations
- missing required fields
- insufficient permissions

This prevents the application from crashing when invalid data is entered.

---

## Optimization Notes

The project includes indexes for common search and reporting needs.

Basic indexes include:

- track title
- BPM
- musical key and mode
- release year
- artist name
- genre name
- tag name
- junction table foreign keys

Advanced indexes include:

- trigram index on track title
- trigram index on artist name
- composite index on musical key, mode, and BPM
- descending BPM index
- composite junction-table indexes

After syncing real API data, the compatibility search query used the `idx_tracks_key_mode_bpm` index through a `Bitmap Index Scan`. This shows that the composite index supports one of the main application search patterns: finding tracks by key, mode, and BPM range.

Some queries still use sequential scans because the tables are relatively small or because the query needs to read most of the table. This is expected behavior in PostgreSQL.

Run the explain analysis script with:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/04_explain_analysis.sql
```

---

## Real API Data Notes

The API sync script uses the Fortnite Festival Spark Tracks endpoint stored in the `.env` file.

The sync process performs a full refresh of the track-related tables instead of comparing every field row by row. This design was chosen because Epic may update metadata such as BPM, key, mode, artist names, release year, tags, and asset URLs.

The `epic_slug` field is treated as the unique external identifier for each track. The `isrc` field is stored as metadata only. It is not enforced as unique because duplicate and irregular ISRC values were found in the API source data.

The `sync_runs` table records API refresh history, including the source, number of tracks imported, sync status, timestamp, and notes.

---

## Git Commands

Check changed files:

```bash
git status
```

Stage files:

```bash
git add .
```

Commit changes:

```bash
git commit -m "Update project documentation"
```

Push to GitHub:

```bash
git push
```

---

## Future Improvements

Possible future improvements include:

- Django web interface
- track editing forms
- genre and tag management
- more advanced compatibility scoring
- user-owned track library support
- additional indexing tests with a larger dataset
- API import logs with more detailed skipped-record reporting
