PRAGMA foreign_keys = ON;

CREATE TABLE location (
    id TEXT PRIMARY KEY,
    last_modified TIMESTAMP NOT NULL,
    json VARCHAR NOT NULL
);

CREATE TABLE person (
    id TEXT PRIMARY KEY,
    last_modified TIMESTAMP NOT NULL,
    json VARCHAR NOT NULL
);

CREATE TABLE sexual_event (
    id TEXT PRIMARY KEY,
    date TIMESTAMP NOT NULL,
    last_modified TIMESTAMP NOT NULL,
    json VARCHAR NOT NULL
);

CREATE TABLE sexual_activity_type (
    id TEXT PRIMARY KEY,
    last_modified TIMESTAMP NOT NULL,
    json VARCHAR NOT NULL
);
