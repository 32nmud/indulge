PRAGMA foreign_keys = ON;



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

CREATE TABLE sexual_activity_type_property (
    id TEXT PRIMARY KEY,
    last_modified TIMESTAMP NOT NULL,
    json VARCHAR NOT NULL
);
