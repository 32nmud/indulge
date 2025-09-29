-- Sample data for testing
-- Location: indulge/assets/sql/sample_data.sql

-- Addresses
INSERT INTO address (line_1, line_2, city, state, zip) VALUES
  ('123 Main St', NULL, 'Anytown', 'NY', '12345'),
  ('456 Oak Ave', 'Apt 2', 'Otherville', 'CA', '67890');

-- Coordinates
INSERT INTO coordinate (lat, long) VALUES
  (40.7128, -74.0060),  -- New York
  (34.0522, -118.2437); -- Los Angeles

-- Locations
INSERT INTO location (address_id, coordinate_id, nickname) VALUES
  (1, 1, 'Home'),
  (2, 2, 'Office');

-- Persons
INSERT INTO person (first_name, last_name, nickname, location_id) VALUES
  ('John', 'Doe', 'Johnny', 1),
  ('Jane', 'Smith', 'Janey', 2),
  ('Alice', 'Johnson', NULL, 1);

-- Events
INSERT INTO event (date, created_at, last_modified, event_type, location_id, notes) VALUES
  ('2025-09-29', '2025-09-29 10:00:00', '2025-09-29 10:00:00', 'sexual', 1, 'First event notes'),
  ('2025-09-28', '2025-09-28 11:00:00', '2025-09-28 11:00:00', 'clinical', 2, 'Second event notes');

-- Sexual activity types
INSERT INTO sexual_activity_type (name, min_participants, max_participants, display_character, is_risky) VALUES
  ('Monogamous', 2, 2, 'M', 0),
  ('Polyamorous', 3, 10, 'P', 1);

-- Sexual activity linking to first event
INSERT INTO sexual_activity (event_id, activity_id) VALUES
  (1, 1);

-- Health tests
INSERT INTO health_test (test_type, notes) VALUES
  ('hiv', 'Standard HIV test'),
  ('chlamydia', 'Chlamydia test');

-- Clinical activities linking to second event
INSERT INTO clinical_activity (event_id, test_id, result) VALUES
  (2, 1, 'negative'),
  (2, 2, 'positive');

-- Event participants
INSERT INTO event_participant (event_id, person_id) VALUES
  (1, 1),
  (1, 2),
  (2, 2),
  (2, 3);

-- Sexual activity participants
INSERT INTO sexual_activity_participant (sexual_activity_id, person_id) VALUES
  (1, 1),
  (1, 2);

-- Clinical activity participants
INSERT INTO clinical_activity_participant (clinical_activity_id, person_id) VALUES
  (1, 2),
  (2, 3);
