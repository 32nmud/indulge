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

CREATE INDEX IF NOT EXISTS idx_sexual_event_date ON sexual_event(date);

CREATE TABLE sexual_activities (
    id TEXT PRIMARY KEY,
    last_modified TIMESTAMP NOT NULL,
    json VARCHAR NOT NULL
);

-- Lightweight metadata table used by migration tooling to track schema version
-- and migration state. Keeping this in the baseline schema ensures newer code
-- can rely on the table existing even before running programmatic migrations.
CREATE TABLE database_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clinical events table for storing serialized ClinicalEvent JSON blobs.
-- The `date` column stores the event timestamp (persisted as UTC ISO string by
-- repository code) and is indexed to support efficient day-range queries.
CREATE TABLE clinical_event (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL,
    last_modified TEXT,
    json TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_clinical_event_date ON clinical_event(date);
