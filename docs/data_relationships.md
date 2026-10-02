# Data Relationships Documentation

This document provides a definitive overview of the data relationships defined by the SQL schema (`assets/sql/schema.sql`) and the Dart data models (`lib/data/models.dart`) in the Indulge project. This documentation is intended for developers and uses deterministic language to describe the structure and associations in the data model.

---

## Database Schema

The schema defines the following tables:

- **person**
- **sexual_event**
- **sexual_activities** (formerly sexual_activity_type)
- **database_metadata**
- **clinical_event**

Each table uses a `TEXT` primary key (`id`), a `last_modified` timestamp, and a `json` column for serialized data. The `sexual_event` table also includes a `date` field. The schema does not define explicit foreign key constraints; all relationships are managed at the application layer.

---

## Dart Data Models

The Dart models are organized as follows:

- `Person`
- `Address`
- `Location`
- `SexualEvent`
- `SexualActivity`
- `SexualActivityCategory`
- `ActivityCount`
- `ActivityParticipant`
- `EventActivity`
- `ClinicalEvent`
- `ClinicalTestResult`
- `Name`
- `Reference`

Each model is mapped to a corresponding table or used as a value object within other models.

---

## Data Relationships

### 1. Person

- A `Person` is uniquely identified by an `id`.
- A `Person` has a `Name` and may have a `Reference` to a `Location`.
- A `Person` may participate in one or more `SexualEvent` instances via the `ActivityParticipant` model.

### 2. Location

- A `Location` is uniquely identified by an `id` and contains an `Address`.
- A `Location` may be referenced by a `Person` or associated with a `SexualEvent`.

### 3. SexualEvent

- A `SexualEvent` is uniquely identified by an `id` and has a `date`.
- A `SexualEvent` contains a list of `EventActivity` instances.
- Each `EventActivity` within a `SexualEvent` represents a specific activity that occurred during the event.

### 4. SexualActivityCategory

- A `SexualActivityCategory` is uniquely identified by an `id` and has a `name`.
- A `SexualActivityCategory` contains a list of `SexualActivity` instances directly (embedded).
- A `SexualActivityCategory` may contain a list of `Reference` to subcategories.
- A `SexualActivityCategory` has a `sortOrder` field for custom ordering.

### 5. SexualActivity

- A `SexualActivity` is uniquely identified by an `id` and has a `name`.
- `SexualActivity` contains fields for `isActionable` (default: true) and `sortOrder` (default: 0).
- `isActionable` determines whether the activity is an action (true) or a tool/resource (false).
- `sortOrder` allows custom ordering of activities.

### 6. EventActivity

- An `EventActivity` contains a `Reference` to a `SexualActivityCategory`.
- An `EventActivity` contains a list of `ActivityParticipant` instances.
- Each `ActivityParticipant` references a `Person` (via `Reference`) and contains a list of `ActivityCount` instances.

### 7. ActivityCount

- An `ActivityCount` contains a `Reference` to a `SexualActivity` and a `count` value.

### 8. Reference

- The `Reference` model is used throughout the data model to create links between entities (e.g., linking an `ActivityParticipant` to a `Person`, or an `EventActivity` to a `SexualActivityCategory`).

### 9. Name and Address

- The `Name` model is used within `Person`.
- The `Address` model is used within `Location`.

### 10. ClinicalEvent

- A `ClinicalEvent` is uniquely identified by an `id` and has a `date`.
- A `ClinicalEvent` contains a list of `ClinicalTestResult` instances.

---

## Entity Relationship Diagram

```
Person
  │
  │ (via Reference in ActivityParticipant)
  ↓
ActivityParticipant
  │
  │ (part of)
  ↓
EventActivity
  │
  │ (part of)
  ↓
SexualEvent
  │
  │ (contains)
  ↓
Location (referenced by Person or SexualEvent)

SexualActivityCategory
  │
  │ (contains directly)
  ↓
SexualActivity
  │
  │ (references via ActivityCount)
  ↓
ActivityParticipant → Person
```

---

## Implementation Notes

- All relationships are managed at the application/model layer using the `Reference` model. There are no foreign key constraints in the database schema.
- All main entity data is stored as JSON in the database, allowing for flexible and extensible data structures.
- The use of value objects (`Name`, `Address`, `Reference`) ensures consistency and reusability across the data model.
- The data model supports extensibility for future requirements by leveraging JSON columns and modular Dart models.
- Activities are embedded directly within `SexualActivityCategory` for simpler, more direct relationships.

---

## Summary

The Indulge data model defines clear relationships between people, events, activities, and categories. Key changes in this version:
- `SexualActivityCategory` now directly contains `SexualActivity` instances
- Added `isActionable` and `sortOrder` fields to `SexualActivity`
- Added `sortOrder` and `subcategories` fields to `SexualActivityCategory`

All associations are explicitly managed in the application layer using references, and the schema is designed for flexibility and future growth. This documentation should be used as the authoritative reference for understanding and extending the data relationships in the project.