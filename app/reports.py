from tabulate import tabulate

from app.db import get_connection
from app.errors import handle_db_error


def get_result_limit(default_limit=25, max_limit=100):
    raw_value = input(f"Result limit, default {default_limit}, max {max_limit}: ").strip()

    if raw_value == "":
        return default_limit

    try:
        limit = int(raw_value)
    except ValueError:
        print(f"\nInvalid limit. Using default limit of {default_limit}.")
        return default_limit

    if limit < 1:
        print(f"\nLimit must be at least 1. Using default limit of {default_limit}.")
        return default_limit

    if limit > max_limit:
        print(f"\nLimit too high. Using max limit of {max_limit}.")
        return max_limit

    return limit


def print_rows(headers, rows):
    if not rows:
        print("\nNo results found.")
        return

    print()
    print(tabulate(rows, headers=headers, tablefmt="grid"))


def search_tracks_by_title():
    search_text = input("Enter part of the song title: ").strip()
    limit = get_result_limit()

    query = """
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
        WHERE t.title ILIKE %s
        GROUP BY
            t.track_id,
            t.title,
            t.bpm,
            t.musical_key,
            t.mode,
            t.release_year
        ORDER BY t.title
        LIMIT %s;
    """

    conn = None

    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, (f"%{search_text}%", limit))
            rows = cur.fetchall()

        print_rows(
            ["Title", "Artist(s)", "BPM", "Key", "Mode", "Year"],
            rows
        )

    except Exception as err:
        handle_db_error(conn, err)

    finally:
        if conn:
            conn.close()


def search_tracks_by_artist():
    search_text = input("Enter part of the artist name: ").strip()
    limit = get_result_limit()

    query = """
        SELECT
            t.title,
            a.artist_name,
            t.bpm,
            t.musical_key,
            t.mode,
            t.release_year
        FROM tracks t
        JOIN track_artists ta
            ON t.track_id = ta.track_id
        JOIN artists a
            ON ta.artist_id = a.artist_id
        WHERE a.artist_name ILIKE %s
        ORDER BY a.artist_name, t.title
        LIMIT %s;
    """

    conn = None

    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, (f"%{search_text}%", limit))
            rows = cur.fetchall()

        print_rows(
            ["Title", "Artist", "BPM", "Key", "Mode", "Year"],
            rows
        )

    except Exception as err:
        handle_db_error(conn, err)

    finally:
        if conn:
            conn.close()


def find_compatible_tracks():
    musical_key = input("Enter musical key, example E, F#, Bb: ").strip()
    mode = input("Enter mode, Major or Minor: ").strip().title()

    try:
        min_bpm = int(input("Enter minimum BPM: ").strip())
        max_bpm = int(input("Enter maximum BPM: ").strip())
        target_bpm = int(input("Enter target BPM for sorting: ").strip())
        limit = get_result_limit()
    except ValueError:
        print("\nError: BPM values must be whole numbers.")
        return

    query = """
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
        WHERE t.musical_key = %s
          AND t.mode = %s
          AND t.bpm BETWEEN %s AND %s
        GROUP BY
            t.track_id,
            t.title,
            t.bpm,
            t.musical_key,
            t.mode,
            t.release_year
        ORDER BY
            ABS(t.bpm - %s),
            t.title
        LIMIT %s;
    """

    conn = None

    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, (musical_key, mode, min_bpm, max_bpm, target_bpm, limit))
            rows = cur.fetchall()

        print_rows(
            ["Title", "Artist(s)", "BPM", "Key", "Mode", "Year"],
            rows
        )

    except Exception as err:
        handle_db_error(conn, err)

    finally:
        if conn:
            conn.close()


def genre_report():
    limit = get_result_limit()
    query = """
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
            average_bpm DESC
        LIMIT %s;
    """

    conn = None

    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, (limit,))
            rows = cur.fetchall()

        print_rows(
            ["Genre", "Track Count", "Average BPM", "Slowest BPM", "Fastest BPM"],
            rows
        )

    except Exception as err:
        handle_db_error(conn, err)

    finally:
        if conn:
            conn.close()


def artist_report():
    limit = get_result_limit()
    query = """
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
        HAVING COUNT(t.track_id) >= 1
        ORDER BY
            track_count DESC,
            a.artist_name
        LIMIT %s;
    """

    conn = None

    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, (limit,))
            rows = cur.fetchall()

        print_rows(
            ["Artist", "Track Count", "Average BPM", "Earliest Year", "Latest Year"],
            rows
        )

    except Exception as err:
        handle_db_error(conn, err)

    finally:
        if conn:
            conn.close()


def intensity_report():
    limit = get_result_limit()
    query = """
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
            t.bpm DESC
        LIMIT %s;
    """

    conn = None

    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, (limit,))
            rows = cur.fetchall()

        print_rows(
            ["Title", "Artist(s)", "BPM", "Key", "Mode", "Vocals", "Lead", "Bass", "Drums", "Total"],
            rows
        )

    except Exception as err:
        handle_db_error(conn, err)

    finally:
        if conn:
            conn.close()

    
def api_sync_status():
        query = """
            SELECT
                sync_id,
                source_name,
                tracks_imported,
                status,
                synced_at,
                notes
            FROM sync_runs
            ORDER BY synced_at DESC
            LIMIT 5;
        """

        conn = None

        try:
            conn = get_connection()
            with conn.cursor() as cur:
                cur.execute(query)
                rows = cur.fetchall()

            print_rows(
                ["Sync ID", "Source", "Tracks Imported", "Status", "Synced At", "Notes"],
                rows
            )

        except Exception as err:
            handle_db_error(conn, err)

        finally:
            if conn:
                conn.close()