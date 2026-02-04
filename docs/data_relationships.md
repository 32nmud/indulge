# Data Relationships Documentation

This document provides a definitive overview of the data relationships defined by the SQL schema (`assets/sql/schema.sql`) and the Dart data models (`lib/data/models.dart`) in the Indulge project. This documentation is intended for developers and uses deterministic language to describe the structure and associations in the data model.

---

## Database Schema

The schema defines the following tables:

- **location**
- **person**
- **sexual_event**
- **sexual_activity_type**
- **sexual_activity_type_property**

Each table uses a `TEXT` primary key (`id`), a `last_modified` timestamp, and a `json` column for serialized data. The `sexual_event` table also includes a `date` field. The schema does not define explicit foreign key constraints; all relationships are managed at the application layer.

---

## Dart Data Models

The Dart models are organized as follows:

- `Person`
- `Address`
- `Location`
- `SexualEvent`
- `SexualActivity`
- `SexualActivityType`
- `SexualActivityTypeProperty`
- `SexualActivityParticipant`
- `Name`
- `Reference`

Each model is mapped to a corresponding table or used as a value object within other models.

---

## Data Relationships

### 1. Person

- A `Person` is uniquely identified by an `id`.
- A `Person` has a `Name` and may have a `Reference` to a `Location`.
- A `Person` may participate in one or more `SexualEvent` instances via the `SexualActivityParticipant` model.

### 2. Location

- A `Location` is uniquely identified by an `id` and contains an `Address`.
- A `Location` may be referenced by a `Person` or associated with a `SexualEvent`.

### 3. SexualEvent

- A `SexualEvent` is uniquely identified by an `id` and has a `date`.
- A `SexualEvent` contains a list of `SexualActivity` instances.
- Each `SexualActivity` within a `SexualEvent` represents a specific activity that occurred during the event.

### 4. SexualActivity

- A `SexualActivity` contains a `Reference` to a `SexualActivityType`.
- A `SexualActivity` contains a list of `SexualActivityParticipant` instances.
- Each `SexualActivityParticipant` references a `Person` (via `Reference`) and may reference one or more `SexualActivityTypeProperty` instances.

### 5. SexualActivityType

- A `SexualActivityType` is uniquely identified by an `id` and has a `name`.
- A `SexualActivityType` contains a list of `SexualActivityTypeProperty` instances.
- Each `SexualActivityTypeProperty` describes a property or characteristic of the activity type.

### 6. SexualActivityTypeProperty

- A `SexualActivityTypeProperty` is uniquely identified by an `id` and has a `name`.
- Properties include flags such as `canHaveMultipleParticipants` and `isRisky`.

### 7. Reference

- The `Reference` model is used throughout the data model to create links between entities (e.g., linking a `SexualActivityParticipant` to a `Person`, or a `SexualActivity` to a `SexualActivityType`).

### 8. Name and Address

- The `Name` model is used within `Person`.
- The `Address` model is used within `Location`.

---

## Entity Relationship Diagram

```
Person
  │
  │ (via Reference in SexualActivityParticipant)
  ↓
SexualActivityParticipant
  │
  │ (part of)
  ↓
SexualActivity
  │
  │ (part of)
  ↓
SexualEvent
  │
  │ (contains)
  ↓
Location (referenced by Person or SexualEvent)

SexualActivity
  │
  │ (references)
  ↓
SexualActivityType
  │
  │ (contains)
  ↓
SexualActivityTypeProperty
```

---

## Implementation Notes

- All relationships are managed at the application/model layer using the `Reference` model. There are no foreign key constraints in the database schema.
- All main entity data is stored as JSON in the database, allowing for flexible and extensible data structures.
- The use of value objects (`Name`, `Address`, `Reference`) ensures consistency and reusability across the data model.
- The data model supports extensibility for future requirements by leveraging JSON columns and modular Dart models.

---

## Summary

The Indulge data model defines clear relationships between people, events, activities, activity types, and properties. All associations are explicitly managed in the application layer using references, and the schema is designed for flexibility and future growth. This documentation should be used as the authoritative reference for understanding and extending the data relationships in the project.
