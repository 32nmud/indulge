PRAGMA foreign_keys = ON;

-- Tables with enum constraints

CREATE TABLE address (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    line_1 VARCHAR NOT NULL,
    line_2 VARCHAR,
    city VARCHAR NOT NULL,
    state VARCHAR NOT NULL,
    zip VARCHAR NOT NULL,
    UNIQUE(line_1, line_2, city, state, zip)
);

CREATE TABLE coordinate (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lat REAL NOT NULL,
    long REAL NOT NULL,
    UNIQUE(lat, long)
);

CREATE TABLE location (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    address_id INTEGER REFERENCES address(id),
    coordinate_id INTEGER REFERENCES coordinate(id),
    nickname VARCHAR UNIQUE
);

CREATE TABLE person (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name VARCHAR,
    last_name VARCHAR,
    nickname VARCHAR,
    location_id INTEGER REFERENCES location(id)
);

CREATE TABLE person_contact (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id INTEGER NOT NULL REFERENCES person(id)
);

CREATE TABLE event (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL,
    last_modified TIMESTAMP NOT NULL,
    event_type TEXT NOT NULL CHECK(event_type IN ('sexual','clinical','medical')),
    location_id INTEGER REFERENCES location(id),
    notes TEXT
);

CREATE TABLE sexual_activity_type (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR NOT NULL,
    min_participants INTEGER DEFAULT 0,
    max_participants INTEGER DEFAULT 0,
    display_character VARCHAR DEFAULT '',
    is_risky BOOLEAN DEFAULT FALSE
);

CREATE TABLE sexual_activity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id INTEGER NOT NULL REFERENCES event(id),
    activity_id INTEGER NOT NULL REFERENCES sexual_activity_type(id)
);

CREATE TABLE health_test (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_type TEXT NOT NULL CHECK(test_type IN ('hiv','chlamydia','gonorrhea','syphilis','hiv_pep','prp','other')),
    notes TEXT
);

CREATE TABLE clinical_activity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id INTEGER NOT NULL REFERENCES event(id),
    test_id INTEGER NOT NULL REFERENCES health_test(id),
    result TEXT CHECK(result IN ('positive','negative','inconclusive'))
);

CREATE TABLE event_participant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id INTEGER NOT NULL REFERENCES event(id),
    person_id INTEGER NOT NULL REFERENCES person(id)
);

CREATE TABLE sexual_activity_participant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sexual_activity_id INTEGER NOT NULL REFERENCES sexual_activity(id),
    person_id INTEGER NOT NULL REFERENCES person(id)
);

CREATE TABLE clinical_activity_participant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    clinical_activity_id INTEGER NOT NULL REFERENCES clinical_activity(id),
    person_id INTEGER NOT NULL REFERENCES person(id)
);
