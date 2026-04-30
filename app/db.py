import os
import psycopg2
from dotenv import load_dotenv


load_dotenv()


def get_connection():
    """
    Creates and returns a PostgreSQL database connection using .env settings.
    The application should connect as festival_app, not postgres.
    """
    return psycopg2.connect(
        dbname=os.getenv("DB_NAME", "fortnite_festival"),
        user=os.getenv("DB_USER", "festival_app"),
        password=os.getenv("DB_PASSWORD", "password"),
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
    )