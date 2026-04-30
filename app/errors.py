from psycopg2 import errors


def handle_db_error(conn, err):
    """
    Rolls back the current transaction and prints a user-friendly error message.
    """
    if conn:
        conn.rollback()

    if isinstance(err, errors.UniqueViolation):
        print("\nError: That record already exists. A unique value was duplicated.")

    elif isinstance(err, errors.ForeignKeyViolation):
        print("\nError: Related data was not found. Please check the selected track, artist, genre, or tag.")

    elif isinstance(err, errors.CheckViolation):
        print("\nError: One of the entered values violates a database rule.")
        print("Example: BPM must be 80-180, mode must be Major/Minor, and intensity values must be 0-6.")

    elif isinstance(err, errors.NotNullViolation):
        print("\nError: A required field was left blank.")

    elif isinstance(err, errors.InsufficientPrivilege):
        print("\nError: This database user does not have permission to perform that action.")

    else:
        print("\nDatabase error:")
        print(err)