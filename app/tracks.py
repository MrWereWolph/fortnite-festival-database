from app.db import get_connection
from app.errors import handle_db_error
from datetime import date

VALID_KEYS = {
    "C", "C#", "Db",
    "D", "D#", "Eb",
    "E",
    "F", "F#", "Gb",
    "G", "G#", "Ab",
    "A", "A#", "Bb",
    "B",
}


def get_int_input(prompt, required=True):
    raw_value = input(prompt).strip()

    if raw_value == "" and not required:
        return None

    try:
        return int(raw_value)
    except ValueError:
        raise ValueError("Expected a whole number.")


def get_optional_text(prompt):
    value = input(prompt).strip()
    return value if value else None


def add_new_track():
    """
    Adds a basic track record safely using parameterized SQL.
    This demonstrates application-level safe data entry.
    """

    print("\nAdd New Track")
    print("Required fields: epic slug, title, BPM, key, mode, artist")
    print("Optional fields can be left blank.\n")

    try:
        epic_slug = input("Epic slug: ").strip()
        title = input("Title: ").strip()
        artist_name = input("Artist name: ").strip()

        release_year = get_int_input("Release year, optional: ", required=False)
        bpm = get_int_input("BPM, 80-180: ")

        musical_key = input("Musical key, example C, F#, Bb: ").strip()
        mode = input("Mode, Major or Minor: ").strip().title()

        album_title = get_optional_text("Album title, optional: ")
        isrc = get_optional_text("ISRC, optional and unique: ")
        jam_code = get_optional_text("Jam code, optional: ")

        if not epic_slug or not title or not artist_name:
            print("\nError: Epic slug, title, and artist name are required.")
            return
        
        if bpm < 80 or bpm > 180:
            print("\nError: BPM must be between 80 and 180.")
            return

        current_year = date.today().year #Initialize variable to get the current year, future-proof feature

        if release_year is not None and (release_year < 1900 or release_year > current_year):
            print(f"\nError: Release year must be between 1900 and {current_year}.")
            return

        if musical_key not in VALID_KEYS:
            print("\nError: Invalid musical key.")
            return

        if mode not in {"Major", "Minor"}:
            print("\nError: Mode must be Major or Minor.")
            return

    except ValueError as err:
        print(f"\nInput error: {err}")
        return

    conn = None

    try:
        conn = get_connection()

        with conn.cursor() as cur:
            # Insert track.
            cur.execute(
                """
                INSERT INTO tracks
                    (epic_slug, title, release_year, bpm, musical_key, mode, album_title, isrc, jam_code)
                VALUES
                    (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING track_id;
                """,
                (
                    epic_slug,
                    title,
                    release_year,
                    bpm,
                    musical_key,
                    mode,
                    album_title,
                    isrc,
                    jam_code,
                ),
            )

            track_id = cur.fetchone()[0]

            # Insert artist if missing.
            cur.execute(
                """
                INSERT INTO artists (artist_name)
                VALUES (%s)
                ON CONFLICT (artist_name)
                DO UPDATE SET artist_name = EXCLUDED.artist_name
                RETURNING artist_id;
                """,
                (artist_name,),
            )

            artist_id = cur.fetchone()[0]

            # Link track and artist.
            cur.execute(
                """
                INSERT INTO track_artists (track_id, artist_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING;
                """,
                (track_id, artist_id),
            )

            # Add empty/default intensity row.
            cur.execute(
                """
                INSERT INTO track_intensities
                    (track_id, vocals, lead, bass, drums, pro_vocals, pro_lead, pro_bass, pro_drums)
                VALUES
                    (%s, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
                """,
                (track_id,),
            )

        conn.commit()
        print(f"\nTrack added successfully: {title}")

    except Exception as err:
        handle_db_error(conn, err)

    finally:
        if conn:
            conn.close()