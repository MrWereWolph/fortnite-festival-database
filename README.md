# Fortnite Festival Database Project

## Project Overview

This project is a PostgreSQL and Python database application for managing and analyzing Fortnite Festival Jam Tracks.

The database stores track metadata such as title, artist, BPM, musical key, mode, release year, genre, tags, and instrument intensity values. The purpose of the project is to help Fortnite Festival Jam Stage players search for compatible songs more efficiently and to demonstrate database design, normalization, SQL optimization, security, and Python application integration.

## Main Features

- PostgreSQL relational database
- Normalized schema using separate tables for tracks, artists, genres, tags, and junction relationships
- Sample data population script
- Advanced SQL reporting queries
- SQL indexing and optimization examples using `EXPLAIN ANALYZE`
- Database roles and permissions
- Python CLI application
- Safe parameterized SQL queries
- User-friendly database error handling
- App-side input validation

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
│   ├── final_data_dictionary.md
│   └── optimization_report.md
│
├── sql/
│   ├── 01_schema.sql
│   ├── 02_insert_sample_data.sql
│   ├── 03_reports.sql
│   ├── 04_indexes.sql
│   └── 05_roles_permissions.sql
│
├── .env.example
├── README.md
└── requirements.txt
```

## Database Platform

This project uses **PostgreSQL**.

PostgreSQL was selected because it supports:

- Strong relational constraints
- Primary keys and foreign keys
- `CHECK`, `UNIQUE`, and `NOT NULL` constraints
- User roles and permissions
- `EXPLAIN ANALYZE`
- B-tree indexes
- GIN/trigram indexes for partial text searching
- Python and Django integration

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
```

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
```

Install Python dependencies:

```bash
pip install -r requirements.txt
```

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

## Creating the Database

Create the database:

```bash
sudo -n runuser -u postgres -- createdb fortnite_festival
```

Verify the database exists:

```bash
sudo -n runuser -u postgres -- psql -l
```

## Creating the Application Role

Open PostgreSQL as the `postgres` user:

```bash
sudo -n runuser -u postgres -- psql
```

Inside the PostgreSQL prompt, run:

```sql
CREATE ROLE festival_app WITH LOGIN PASSWORD 'password';
GRANT CONNECT ON DATABASE fortnite_festival TO festival_app;
\q
```

Test the login:

```bash
psql -h localhost -U festival_app -d fortnite_festival
```

Password:

```text
password
```

Exit with:

```sql
\q
```

## Running the SQL Scripts

Run the schema script:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/01_schema.sql
```

Run the sample data script:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/02_insert_sample_data.sql
```

Run the report queries:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/03_reports.sql
```

Run the optimization/indexing script:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/04_indexes.sql
```

Run the roles and permissions script:

```bash
sudo -n runuser -u postgres -- psql -d fortnite_festival -f sql/05_roles_permissions.sql
```

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
UNION ALL SELECT 'track_tags', COUNT(*) FROM track_tags;
"
```

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
8. Exit
```

## Example CLI Searches

Search by title:

```text
Option: 1
Search: sand
```

Search by artist:

```text
Option: 2
Search: weeknd
```

Find compatible tracks:

```text
Option: 3
Key: E
Mode: Minor
Minimum BPM: 115
Maximum BPM: 140
Target BPM: 124
```

## Security Implementation

The project uses SQL-level and application-level security.

SQL-level security:

- The application connects as `festival_app`, not as the PostgreSQL superuser.
- `festival_app` is granted `SELECT`, `INSERT`, and `UPDATE`.
- `festival_app` is not granted `DELETE`.
- Schema modification permissions are not granted to the application user.
- A separate `festival_readonly` role is included for report-only access.

Application-level security:

- Python database operations use parameterized SQL queries.
- User input is passed through placeholders such as `%s`.
- Input is not directly concatenated into SQL strings.
- The application validates BPM, release year, key, mode, and required fields before inserting a new track.

## Error Handling

The CLI catches common database errors and displays user-friendly messages.

Handled errors include:

- Duplicate values
- Foreign key violations
- Check constraint violations
- Missing required fields
- Insufficient permissions

This prevents the application from crashing when invalid data is entered.

## Optimization Notes

The project includes indexes for common search and reporting needs.

Basic indexes include:

- Track title
- BPM
- Musical key and mode
- Release year
- Artist name
- Genre name
- Tag name
- Junction table foreign keys

Advanced indexes include:

- Trigram index on track title
- Trigram index on artist name
- Composite index on musical key, mode, and BPM
- Descending BPM index
- Composite junction-table indexes

Because the sample database is small, PostgreSQL may still choose sequential scans in some `EXPLAIN ANALYZE` outputs. This is expected. With only a few records, scanning the whole table can be cheaper than using an index. The indexes become more useful as the dataset grows to hundreds or thousands of tracks and relationship rows.

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

## Future Improvements

Possible future improvements include:

- Django web interface
- Track editing forms
- Genre and tag management
- Importing track data from the Fortnite Festival API
- More advanced compatibility scoring
- User-owned track library support
- Additional indexing tests with larger sample data
