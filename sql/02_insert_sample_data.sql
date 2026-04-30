-- ============================================================
-- Fortnite Festival Database
-- Milestone 3: Preliminary Data Population
-- ============================================================

-- Clear existing data in dependency order.
DELETE FROM track_tags;
DELETE FROM track_genres;
DELETE FROM track_artists;
DELETE FROM track_intensities;
DELETE FROM tags;
DELETE FROM genres;
DELETE FROM artists;
DELETE FROM tracks;

-- Reset identity sequences.
ALTER SEQUENCE tracks_track_id_seq RESTART WITH 1;
ALTER SEQUENCE artists_artist_id_seq RESTART WITH 1;
ALTER SEQUENCE genres_genre_id_seq RESTART WITH 1;
ALTER SEQUENCE tags_tag_id_seq RESTART WITH 1;

-- ============================================================
-- Tracks
-- ============================================================

INSERT INTO tracks
(epic_slug, title, release_year, bpm, musical_key, mode, album_title, isrc, cover_art_url, audio_url, lad_url, jam_code, active_date, last_modified, qi_json)
VALUES
('badromance_ladygaga', 'Bad Romance', 2009, 119, 'A', 'Minor', 'The Fame Monster', 'USUM70918596', 'https://example.com/badromance.jpg', 'https://example.com/badromance_audio', 'https://example.com/badromance_lad', 'JAM001', '2024-02-22', '2024-02-22', '{"source":"sample"}'),
('sandstorm_darude', 'Sandstorm', 1999, 136, 'E', 'Minor', 'Before the Storm', 'FISGT9900001', 'https://example.com/sandstorm.jpg', 'https://example.com/sandstorm_audio', 'https://example.com/sandstorm_lad', 'JAM002', '2024-03-01', '2024-03-01', '{"source":"sample"}'),
('whatspoppin_jackharlow', 'WHATS POPPIN', 2020, 145, 'C#', 'Minor', 'Sweet Action', 'USAT22000162', 'https://example.com/whatspoppin.jpg', 'https://example.com/whatspoppin_audio', 'https://example.com/whatspoppin_lad', 'JAM003', '2024-03-08', '2024-03-08', '{"source":"sample"}'),
('i_kendricklamar', 'i', 2014, 122, 'F#', 'Minor', 'To Pimp a Butterfly', 'USUM71414289', 'https://example.com/i.jpg', 'https://example.com/i_audio', 'https://example.com/i_lad', 'JAM004', '2024-03-15', '2024-03-15', '{"source":"sample"}'),
('blindinglights_theweeknd', 'Blinding Lights', 2019, 171, 'F', 'Minor', 'After Hours', 'USUG11904206', 'https://example.com/blindinglights.jpg', 'https://example.com/blindinglights_audio', 'https://example.com/blindinglights_lad', 'JAM005', '2024-03-22', '2024-03-22', '{"source":"sample"}'),
('basketcase_greenday', 'Basket Case', 1994, 85, 'Eb', 'Major', 'Dookie', 'USRE19900153', 'https://example.com/basketcase.jpg', 'https://example.com/basketcase_audio', 'https://example.com/basketcase_lad', 'JAM006', '2024-03-29', '2024-03-29', '{"source":"sample"}'),
('buddyholly_weezer', 'Buddy Holly', 1994, 121, 'F#', 'Minor', 'Weezer', 'USGF19562907', 'https://example.com/buddyholly.jpg', 'https://example.com/buddyholly_audio', 'https://example.com/buddyholly_lad', 'JAM007', '2024-04-05', '2024-04-05', '{"source":"sample"}'),
('thehills_theweeknd', 'The Hills', 2015, 113, 'C', 'Minor', 'Beauty Behind the Madness', 'USUG11500737', 'https://example.com/thehills.jpg', 'https://example.com/thehills_audio', 'https://example.com/thehills_lad', 'JAM008', '2024-04-12', '2024-04-12', '{"source":"sample"}'),
('cakebytheocean_dnce', 'Cake By The Ocean', 2015, 119, 'E', 'Minor', 'DNCE', 'USUM71513339', 'https://example.com/cakebytheocean.jpg', 'https://example.com/cakebytheocean_audio', 'https://example.com/cakebytheocean_lad', 'JAM009', '2024-04-19', '2024-04-19', '{"source":"sample"}'),
('sevennationarmy_whitestripes', 'Seven Nation Army', 2003, 124, 'E', 'Minor', 'Elephant', 'USVT10300001', 'https://example.com/sevennationarmy.jpg', 'https://example.com/sevennationarmy_audio', 'https://example.com/sevennationarmy_lad', 'JAM010', '2024-04-26', '2024-04-26', '{"source":"sample"}');

-- ============================================================
-- Artists
-- ============================================================

INSERT INTO artists (artist_name)
VALUES
('Lady Gaga'),
('Darude'),
('Jack Harlow'),
('Kendrick Lamar'),
('The Weeknd'),
('Green Day'),
('Weezer'),
('DNCE'),
('The White Stripes'),
('Epic Games');

-- ============================================================
-- Genres
-- ============================================================

INSERT INTO genres (genre_name)
VALUES
('Pop'),
('Dance/Electronic'),
('Rap/Hip-Hop'),
('Rock'),
('R&B'),
('Alternative'),
('Punk Rock'),
('Funk'),
('Indie Rock'),
('Fortnite Original');

-- ============================================================
-- Tags
-- ============================================================

INSERT INTO tags (tag_name)
VALUES
('High Energy'),
('Good For Mashups'),
('Fast BPM'),
('Slow BPM'),
('Same Key Friendly'),
('Vocals Focused'),
('Guitar Focused'),
('Drum Focused'),
('Bass Focused'),
('Classic Track');

-- ============================================================
-- Track Intensities
-- ============================================================

INSERT INTO track_intensities
(track_id, vocals, lead, bass, drums, pro_vocals, pro_lead, pro_bass, pro_drums)
VALUES
(1, 5, 4, 3, 4, 5, 4, 3, 4),
(2, NULL, 6, 4, 5, NULL, 6, 4, 5),
(3, 5, 3, 4, 3, 5, 3, 4, 3),
(4, 5, 4, 4, 5, 5, 4, 4, 5),
(5, 5, 5, 4, 4, 5, 5, 4, 4),
(6, 4, 5, 4, 5, 4, 5, 4, 5),
(7, 4, 5, 4, 4, 4, 5, 4, 4),
(8, 5, 3, 5, 3, 5, 3, 5, 3),
(9, 5, 4, 4, 4, 5, 4, 4, 4),
(10, 3, 6, 5, 5, 3, 6, 5, 5);

-- ============================================================
-- Track Artists
-- ============================================================

INSERT INTO track_artists (track_id, artist_id)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 5),
(9, 8),
(10, 9);

-- ============================================================
-- Track Genres
-- ============================================================

INSERT INTO track_genres (track_id, genre_id)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 3),
(5, 5),
(6, 7),
(7, 6),
(8, 5),
(9, 1),
(10, 4);

-- ============================================================
-- Track Tags
-- ============================================================

INSERT INTO track_tags (track_id, tag_id)
VALUES
(1, 1),
(1, 2),
(2, 1),
(2, 3),
(3, 3),
(4, 2),
(5, 3),
(6, 10),
(7, 7),
(8, 6),
(9, 2),
(10, 7),
(10, 9);