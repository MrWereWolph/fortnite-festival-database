import json
import os
from datetime import datetime
from typing import Any

import psycopg2
import requests
from dotenv import load_dotenv
from psycopg2.extras import Json


load_dotenv()

SOURCE_NAME = "Epic Games Spark Tracks API"
DEFAULT_SPARK_TRACKS_URL = (
    "https://fortnitecontent-website-prod07.ol.epicgames.com/content/api/pages/"
    "fortnite-game/spark-tracks"
)

VALID_KEYS = {
    "C", "C#", "Db",
    "D", "D#", "Eb",
    "E",
    "F", "F#", "Gb",
    "G", "G#", "Ab",
    "A", "A#", "Bb",
    "B",
}

VALID_MODES = {"Major", "Minor"}


def get_sync_connection():
    return psycopg2.connect(
        dbname=os.getenv("DB_NAME", "fortnite_festival"),
        user=os.getenv("SYNC_DB_USER", "festival_sync"),
        password=os.getenv("SYNC_DB_PASSWORD", "sync_password"),
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
    )


def parse_datetime(value: Any):
    if not value or not isinstance(value, str):
        return None

    try:
        cleaned = value.replace("Z", "+00:00")
        parsed = datetime.fromisoformat(cleaned)

        # Database column is TIMESTAMP WITHOUT TIME ZONE.
        # Remove timezone info after parsing.
        return parsed.replace(tzinfo=None)
    except ValueError:
        return None


def normalize_mode(value: Any):
    if not value or not isinstance(value, str):
        return None

    cleaned = value.strip().title()

    if cleaned in VALID_MODES:
        return cleaned

    return None


def normalize_key(value: Any):
    if not value or not isinstance(value, str):
        return None

    cleaned = value.strip()

    if cleaned in VALID_KEYS:
        return cleaned

    return None


def get_int(value: Any):
    if value is None:
        return None

    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def get_bpm(track: dict):
    """
    Fortnite API data has used different short field names over time.
    Based on earlier project work, mt is the main BPM field, with mmo
    included as a fallback if present.
    """
    return get_int(track.get("mt")) or get_int(track.get("mmo"))


def get_qi_json(track: dict):
    qi = track.get("qi")

    if qi is None:
        return None

    if isinstance(qi, dict):
        return qi

    if isinstance(qi, str):
        try:
            return json.loads(qi)
        except json.JSONDecodeError:
            return {"raw": qi}

    return {"raw": str(qi)}


def fetch_spark_tracks(url: str):
    print(f"Fetching Fortnite Festival data from:\n{url}\n")

    response = requests.get(url, timeout=30)
    response.raise_for_status()

    return response.json()


def iter_track_entries(payload: dict):
    """
    The spark-tracks endpoint returns a large object with metadata keys
    and many dynamic track slug keys.

    Track entries are the values that contain a dictionary named 'track'.
    """
    for map_slug, value in payload.items():
        if map_slug.startswith("_"):
            continue

        if not isinstance(value, dict):
            continue

        track = value.get("track")

        if not isinstance(track, dict):
            continue

        yield map_slug, value, track


def get_or_create_lookup(cur, table: str, id_column: str, name_column: str, value: str, cache: dict):
    value = value.strip()

    if value in cache:
        return cache[value]

    sql = f"""
        INSERT INTO {table} ({name_column})
        VALUES (%s)
        ON CONFLICT ({name_column})
        DO UPDATE SET {name_column} = EXCLUDED.{name_column}
        RETURNING {id_column};
    """

    cur.execute(sql, (value,))
    row_id = cur.fetchone()[0]
    cache[value] = row_id

    return row_id


def insert_sync_run(cur, source_url: str, tracks_imported: int, status: str, notes: str | None):
    cur.execute(
        """
        INSERT INTO sync_runs
            (source_name, source_url, tracks_imported, status, notes)
        VALUES
            (%s, %s, %s, %s, %s);
        """,
        (SOURCE_NAME, source_url, tracks_imported, status, notes),
    )


def sync_tracks():
    source_url = os.getenv("FORTNITE_SPARK_TRACKS_URL", DEFAULT_SPARK_TRACKS_URL)

    payload = fetch_spark_tracks(source_url)

    artist_cache = {}
    genre_cache = {}
    tag_cache = {}

    tracks_imported = 0
    tracks_skipped = 0
    skip_reasons = []

    conn = None

    try:
        conn = get_sync_connection()

        with conn:
            with conn.cursor() as cur:
                print("Clearing existing track data...")

                cur.execute(
                    """
                    TRUNCATE
                        track_tags,
                        track_genres,
                        track_artists,
                        track_intensities,
                        tracks,
                        artists,
                        genres,
                        tags
                    CASCADE;
                    """
                )

                print("Importing current API data...")

                for map_slug, entry, track in iter_track_entries(payload):
                    title = track.get("tt")
                    artist_name = track.get("an")

                    epic_slug = track.get("sn") or map_slug
                    release_year = get_int(track.get("ry"))
                    bpm = get_bpm(track)
                    musical_key = normalize_key(track.get("mk"))
                    mode = normalize_mode(track.get("mm"))

                    if not title or not artist_name:
                        tracks_skipped += 1
                        skip_reasons.append(f"{map_slug}: missing title or artist")
                        continue

                    if bpm is None or bpm < 80 or bpm > 180:
                        tracks_skipped += 1
                        skip_reasons.append(f"{map_slug}: invalid or missing BPM")
                        continue

                    if musical_key is None:
                        tracks_skipped += 1
                        skip_reasons.append(f"{map_slug}: invalid or missing musical key")
                        continue

                    if mode is None:
                        tracks_skipped += 1
                        skip_reasons.append(f"{map_slug}: invalid or missing mode")
                        continue

                    active_date = parse_datetime(entry.get("_activeDate"))
                    last_modified = parse_datetime(entry.get("lastModified"))

                    cur.execute(
                        """
                        INSERT INTO tracks
                            (
                                epic_slug,
                                title,
                                release_year,
                                bpm,
                                musical_key,
                                mode,
                                album_title,
                                isrc,
                                cover_art_url,
                                audio_url,
                                lad_url,
                                jam_code,
                                active_date,
                                last_modified,
                                qi_json
                            )
                        VALUES
                            (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        RETURNING track_id;
                        """,
                        (
                            epic_slug,
                            title,
                            release_year,
                            bpm,
                            musical_key,
                            mode,
                            track.get("ab"),
                            track.get("isrc"),
                            track.get("au"),
                            track.get("mu"),
                            track.get("ld"),
                            track.get("jc"),
                            active_date,
                            last_modified,
                            Json(get_qi_json(track)) if get_qi_json(track) is not None else None,
                        ),
                    )

                    track_id = cur.fetchone()[0]

                    artist_id = get_or_create_lookup(
                        cur,
                        "artists",
                        "artist_id",
                        "artist_name",
                        artist_name,
                        artist_cache,
                    )

                    cur.execute(
                        """
                        INSERT INTO track_artists (track_id, artist_id)
                        VALUES (%s, %s)
                        ON CONFLICT DO NOTHING;
                        """,
                        (track_id, artist_id),
                    )

                    genres = track.get("ge") or []
                    if isinstance(genres, list):
                        for genre_name in genres:
                            if not isinstance(genre_name, str) or not genre_name.strip():
                                continue

                            genre_id = get_or_create_lookup(
                                cur,
                                "genres",
                                "genre_id",
                                "genre_name",
                                genre_name,
                                genre_cache,
                            )

                            cur.execute(
                                """
                                INSERT INTO track_genres (track_id, genre_id)
                                VALUES (%s, %s)
                                ON CONFLICT DO NOTHING;
                                """,
                                (track_id, genre_id),
                            )

                    tags = track.get("gt") or []
                    if isinstance(tags, list):
                        for tag_name in tags:
                            if not isinstance(tag_name, str) or not tag_name.strip():
                                continue

                            tag_id = get_or_create_lookup(
                                cur,
                                "tags",
                                "tag_id",
                                "tag_name",
                                tag_name,
                                tag_cache,
                            )

                            cur.execute(
                                """
                                INSERT INTO track_tags (track_id, tag_id)
                                VALUES (%s, %s)
                                ON CONFLICT DO NOTHING;
                                """,
                                (track_id, tag_id),
                            )

                    intensities = track.get("in") or {}

                    if isinstance(intensities, dict):
                        vocals = get_int(intensities.get("vl"))
                        lead = get_int(intensities.get("gr"))
                        bass = get_int(intensities.get("ba"))
                        drums = get_int(intensities.get("ds"))

                        pro_vocals = None
                        pro_lead = get_int(intensities.get("pg"))
                        pro_bass = get_int(intensities.get("pb"))
                        pro_drums = get_int(intensities.get("pd"))

                        cur.execute(
                            """
                            INSERT INTO track_intensities
                                (
                                    track_id,
                                    vocals,
                                    lead,
                                    bass,
                                    drums,
                                    pro_vocals,
                                    pro_lead,
                                    pro_bass,
                                    pro_drums
                                )
                            VALUES
                                (%s, %s, %s, %s, %s, %s, %s, %s, %s);
                            """,
                            (
                                track_id,
                                vocals,
                                lead,
                                bass,
                                drums,
                                pro_vocals,
                                pro_lead,
                                pro_bass,
                                pro_drums,
                            ),
                        )
                    else:
                        cur.execute(
                            """
                            INSERT INTO track_intensities
                                (
                                    track_id,
                                    vocals,
                                    lead,
                                    bass,
                                    drums,
                                    pro_vocals,
                                    pro_lead,
                                    pro_bass,
                                    pro_drums
                                )
                            VALUES
                                (%s, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
                            """,
                            (track_id,),
                        )

                    tracks_imported += 1

                notes = (
                    f"Imported {tracks_imported} tracks. "
                    f"Skipped {tracks_skipped} tracks."
                )

                if skip_reasons:
                    notes += " First skipped examples: " + "; ".join(skip_reasons[:10])

                insert_sync_run(
                    cur,
                    source_url=source_url,
                    tracks_imported=tracks_imported,
                    status="success",
                    notes=notes,
                )

        print()
        print("Sync complete.")
        print(f"Tracks imported: {tracks_imported}")
        print(f"Tracks skipped: {tracks_skipped}")
        print(f"Artists imported: {len(artist_cache)}")
        print(f"Genres imported: {len(genre_cache)}")
        print(f"Tags imported: {len(tag_cache)}")

    except Exception as err:
        if conn:
            conn.rollback()

        print()
        print("Sync failed.")
        print(err)

        try:
            fail_conn = get_sync_connection()
            with fail_conn:
                with fail_conn.cursor() as cur:
                    insert_sync_run(
                        cur,
                        source_url=source_url,
                        tracks_imported=0,
                        status="failed",
                        notes=str(err)[:1000],
                    )
            fail_conn.close()
        except Exception:
            pass

    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    sync_tracks()