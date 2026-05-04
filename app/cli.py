from app.reports import (
    search_tracks_by_title,
    search_tracks_by_artist,
    find_compatible_tracks,
    genre_report,
    artist_report,
    intensity_report,
    api_sync_status,
)
from app.tracks import add_new_track


def print_menu():
    print("\n======================================")
    print(" Fortnite Festival Database")
    print("======================================")
    print("1. Search tracks by title")
    print("2. Search tracks by artist")
    print("3. Find compatible tracks by key/mode/BPM")
    print("4. View genre report")
    print("5. View artist report")
    print("6. View highest intensity tracks")
    print("7. Add a new track")
    print("8. View latest API sync status")
    print("9. Exit")


def main():
    while True:
        print_menu()
        choice = input("\nSelect an option: ").strip()

        if choice == "1":
            search_tracks_by_title()

        elif choice == "2":
            search_tracks_by_artist()

        elif choice == "3":
            find_compatible_tracks()

        elif choice == "4":
            genre_report()

        elif choice == "5":
            artist_report()

        elif choice == "6":
            intensity_report()

        elif choice == "7":
            add_new_track()

        elif choice == "8":
            api_sync_status()

        elif choice == "9":
            print("\nGoodbye.")
            break

        else:
            print("\nInvalid option. Please select a number from 1 to 9.")


if __name__ == "__main__":
    main()