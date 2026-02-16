# ClinicalEventEditor — Implementation Plan

Goal
----
Create a polished, accessible, and testable Clinical Event Editor UI that:
- Lets users create and edit clinical events (tests/appointments/results).
- Validates input and saves through the ClinicalEventsProvider (which writes to EventStateStore).
- Reads initial values (e.g., `selectedDate`) from `EventStateStore`.
- Integrates with existing navigation (SpeedDial FAB -> Clinical editor) and theming.

High-level requirements
-----------------------
This editor is focused on STI/STD laboratory testing events. The UI and data flow should map directly to the existing `ClinicalEvent` model: a single event that contains a list of `ClinicalTestResult` entries (one per test/specimen).

1. Fields (model-driven)
   - Date (required): maps to `ClinicalEvent.date`. Prefill from `EventStateStore.state.selectedDate` when available.
   - Tests (required): a list of one or more `ClinicalTestResult` objects. For each test entry the form must allow:
       - `TestType` (enum): canonical options from the model (chlamydia, gonorrhea, hiv, syphilis, trichomonas, hepatitis, other). When `other` is chosen, allow a small free-text label for clarification.
       - `TestResult` (enum): standardized values (negative, positive, indeterminate, pending).
       - `SpecimenSite` (enum): choices (throat, urine, rectal) — allow selecting the correct specimen site per test.
     The UI should support adding/removing multiple test rows for a single clinical event.
   - Facility (optional): maps to `ClinicalEvent.facility` (free-form string).
   - Notes (optional): maps to `ClinicalEvent.notes`.
   - lastModifiedDate is handled by the provider/store (not a form field).
   - Scope exclusions: Partner linkage, attachments/images, appointments, vaccinations, or per-test free-form notes beyond the above are out of scope for this first iteration.

2. Behaviors
   - Prefill date from `EventStateStore.state.selectedDate` on open (if present).
   - Validate that at least one test row exists and each test row has TestType, TestResult, and SpecimenSite selected.
   - On Save:
     - Build a `ClinicalEvent` DTO with `tests: List<ClinicalTestResult>` and other fields.
     - Call `ClinicalEventsProvider.saveEvent(event)` (or the provider's create API). Provider persists, updates `EventStateStore`, and returns/propagates the saved event.
     - Show a loading indicator while saving; on success pop the route and show a success SnackBar; on error show an error SnackBar and allow retry.
   - On Cancel/back: if the form is dirty, confirm discard; otherwise simply pop.

3. Accessibility & UX
   - Clear field labels, semantic hints, and correct focus order.
   - Keyboard support and proper input types.
   - Use platform date/time pickers where appropriate.
   - For lists of tests, ensure controls are reachable and announced to assistive tech.

4. Tests
   - Widget tests:
     - Form renders with empty/default values and with an initial ClinicalEvent (edit mode).
     - Adding/removing test rows works.
     - Validation blocks save when required fields are missing.
     - Save calls provider and results are applied to EventStateStore (use a mock provider/store).
   - Unit tests:
     - Helpers that map form input -> `ClinicalTestResult` / `ClinicalEvent`.
     - Validation helpers.

5. Integration / provider expectations
   - ClinicalEventsProvider should accept a `ClinicalEvent` (or equivalent DTO) and persist it, then update the central `EventStateStore`.
   - If provider API differs, add a small adapter in the UI layer to convert the form DTO to the provider's expected model.

Files to create / modify
------------------------
- New
  - `lib/view/common/clinical_event_editor/clinical_event_editor.dart` — Main page + form widget(s).
  - `lib/view/common/clinical_event_editor/clinical_event_model.dart` — Lightweight model / DTO used by the editor (optional; could use provider model).
  - `lib/view/common/clinical_event_editor/validators.dart` — Small helpers for validation/parsing (optional).
  - `test/widget/clinical_event_editor_test.dart` — Widget tests.
- Possible provider changes (only if provider lacks API)
  - `lib/provider/clinical_event_provider.dart` — ensure `saveEvent(ClinicalEvent event)` exists and writes to store.
  - `lib/provider/event_state_store.dart` — ensure convenience method to apply a new clinical event exists (or call provider then store).

UI Structure (component breakdown)
----------------------------------
- `ClinicalEventEditorPage` (StatelessWidget)
  - Scaffold with `AppBar` ("New clinical event" / "Edit clinical event")
  - Body: `ClinicalEventForm` wrapped in padding and ScrollView
  - FloatingActionButton / AppBar actions: Save button and Cancel
- `ClinicalEventForm` (StatefulWidget)
  - Uses a `GlobalKey<FormState>`
  - Keeps local form state in a `ClinicalEvent` DTO (or local fields)
  - Exposes `isDirty` and `toClinicalEvent()` helpers
  - Uses `TextFormField` / `DropdownButtonFormField` / `DateTime` picker widgets
  - `Date` picker: showDatePicker, with inline display of current selected
  - `Time` picker: optional, `showTimePicker`
  - Autocomplete for test name if contact / category lists exist
  - Save button triggers form validation and `onSave` callback

Data model
----------
Create `ClinicalEvent` DTO with fields:
- `String? id` (nullable for new)
- `DateTime date`
- `String type` (enum string)
- `String? testName`
- `String? result` (string typed; parse numeric when needed)
- `String? providerName`
- `String? notes`
- `String? partnerId` (optional relationship)
- `List<String>? tags`

API contract & provider usage
-----------------------------
Preferred flow:
1. UI validates and builds `ClinicalEvent` DTO.
2. UI calls `context.read<ClinicalEventsProvider>().saveEvent(event)` (or `createEvent`).
   - Provider performs repo effects and writes to `EventStateStore` (per migration pattern).
   - Provider returns the saved event (with id) or throws on error — use try/catch.
3. On success:
   - Optionally call `context.read<EventStateStore>().applyXXX(...)` if the provider does not update the store.
   - Pop the route and show a success SnackBar.

If provider API is different:
- Add an adapter in the provider to accept DTOs from UI.
- Keep UI unaware of persistence details beyond calling provider method.

Validation rules
----------------
- Date: required
- Type: required (default "Lab Test")
- Test name: required for some types (e.g., Lab Test)
- Result: optional, but if present and type expects numeric, validate numeric range as needed
- Notes: max length (e.g., 2000 chars)
- Provide clear inline error messages

Error handling & UX on save
---------------------------
- On save: show a modal CircularProgressIndicator or set Save button to loading state (disable inputs).
- If save succeeds: pop route, show success SnackBar (or return saved event to caller).
- If save fails: show error SnackBar with retry option.
- If user taps back while editing: if form dirty, show confirm dialog (discard changes?).

Animations & polish
-------------------
- Small stagger on items appearance (already in SpeedDial approach).
- Focus the first input when page opens (date or test name).
- Use platform pickers for date/time.

Accessibility
-------------
- Provide `semanticLabel` for important interactive elements.
- Ensure label text readable, color contrast ok (use theme).
- Ensure keyboard navigation / Next/Done works.

Testing
-------
- Widget tests:
  - Renders with default values (selectedDate prefill).
  - Enter valid data and tap Save -> `provider.saveEvent` called (mock provider).
  - Validation: missing required fields shows errors.
  - Cancel when dirty shows confirmation.
- Unit tests:
  - Validation helpers
  - DTO <-> provider model conversions
- Integration test (optional):
  - Confirm event appears in main Events list after save.

Step-by-step implementation plan (priority)
------------------------------------------
Phase 0: Prep & discovery (short)
- Inspect `ClinicalEventsProvider` and `EventStateStore` APIs to confirm save contract.
- Note any missing helper methods and file locations.

Phase 1: Scaffold (1–2 hours)
- Create `clinical_event_editor.dart` with page scaffold and an empty form placeholder.
- Hook navigation from SpeedDial (already wired to placeholder). Verify navigation opens the new page.

Phase 2: Form implementation (2–4 hours)
- Implement `ClinicalEventForm` with fields listed above, form validation, and Date/Time pickers.
- Wire Save/Cancel UI and local form state.

Phase 3: Provider integration (1–2 hours)
- Call `ClinicalEventsProvider.saveEvent(...)` inside Save handler.
- Show loading state while save is in progress.
- On success, pop and show a SnackBar. On failure, show retry.

Phase 4: UX polish & accessibility (1–2 hours)
- Focus, proper keyboard types, labels, and error messages.
- Truncate long labels, clamp widths on small screens.

Phase 5: Tests (2–4 hours)
- Add widget tests and unit tests as described.

Phase 6: Review & refactor (1–2 hours)
- Extract common widgets (DateTimeRow, LabelChip).
- Fix lint warnings; remove debug prints.

Acceptance criteria
-------------------
- Editor opens from the SpeedDial Clinical action and pre-fills date.
- Required fields validate and prevent save when missing.
- Save calls provider and persists the event (provider updates `EventStateStore`).
- UI shows loading and success/failure states appropriately.
- Tests exist that cover core flows.

Potential edge-cases & notes
---------------------------
- If provider is asynchronous and takes long, preserve unsaved state if user navigates away and returns (optional).
- If editing existing event (edit flow), prepopulate fields from provider/store, and call provider.updateEvent(...) on save.
- Consider consistent `heroTag` assignment for FAB transitions if you want animated transitions into the editor.

Developer notes (quick)
-----------------------
- Use `Form` + `TextFormField` with `autovalidateMode: onUserInteraction`.
- Use provider's `ready` future / readiness pattern (if used elsewhere) to guard save calls.
- Keep UI layer thin: do validation + simple dto mapping; business logic and persistence live in providers.

If you want, I can:
- Open the provider files and confirm `saveEvent` signature and responsibility.
- Create the initial `clinical_event_editor.dart` scaffold and push it as a first PR.
- Wire up tests and a basic integration test that saves a clinical event and verifies it lands in `EventStateStore`.

Which of the above should I implement first? (I can start by creating the page scaffold and the form fields.)