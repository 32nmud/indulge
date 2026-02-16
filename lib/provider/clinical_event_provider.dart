import 'package:flutter/cupertino.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/data/repositories/clinical_event_repository.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:logging/logging.dart';

/// Provider responsible for clinical event state and persistence.
///
/// This is a lightweight skeleton modeled after the existing
/// `SexualEventsProvider`. It intentionally exposes the minimal set of
/// operations required by the UI and other services:
/// - initialization (accepts an optional repository for testing)
/// - refreshAllData to reload presence maps / events
/// - CRUD operations for ClinicalEvent
/// - helpers to compute last test dates and latest results
class ClinicalEventsProvider extends ChangeNotifier {
  late ClinicalEventRepository _repository;
  final EventStateStore _stateStore;
  late final Future<String> _ready;
  final Logger _logger = Logger('ClinicalEventsProvider');

  ClinicalEventsProvider({
    ClinicalEventRepository? repository,
    required EventStateStore stateStore,
  }) : _stateStore = stateStore {
    _ready = _initProvider(repository: repository);
  }

  Future<String> _initProvider({ClinicalEventRepository? repository}) async {
    if (repository == null) {
      _repository = await ClinicalEventRepository.create();
    } else {
      _repository = repository;
    }

    // Load presence map for a reasonable default window (e.g. last 90 days)
    // Consumers can call refreshAllData() to load a different window.
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 90));
    final presence = await _repository.getDailyPresence(
      start,
      now.add(const Duration(days: 1)),
    );

    // Write initial presence into the shared store when available.
    _stateStore.setDailyClinicalEventPresence(presence);

    return 'ready';
  }

  Future<String> get ready => _ready;

  /// Refreshes clinical-event related data from the repository.
  /// This will update the presence map and reload events for the selected date.
  Future<void> refreshAllData({DateTime? start, DateTime? end}) async {
    final now = DateTime.now();
    final s = start ?? now.subtract(const Duration(days: 90));
    final e = end ?? now.add(const Duration(days: 1));

    final presence = await _repository.getDailyPresence(s, e);
    _stateStore.setDailyClinicalEventPresence(presence);

    // Reload events for currently selected date if present
    if (_stateStore.state.selectedDate != null) {
      await _loadClinicalEventsForDate(_stateStore.state.selectedDate!);
    }
  }

  /// Selects a date (day) and loads clinical events for that date.
  void selectDate(DateTime date) {
    // Normalize to midnight to ensure consistent day queries
    final normalized = DateTime(date.year, date.month, date.day);
    _stateStore.setSelectedDate(normalized);
    _loadClinicalEventsForDate(normalized);
  }

  /// Select a specific ClinicalEvent and update state.
  Future<void> selectClinicalEvent(ClinicalEvent event) async {
    _stateStore.setSelectedClinicalEvent(event);
    // Optionally load events for the same date to populate currentClinicalEvents
    await _loadClinicalEventsForDate(event.date);
  }

  /// Save (insert or update) a clinical event then refresh presence + day events.
  /// Also update the centrally-stored `selectedDate` so daily views will show
  /// the saved event's date immediately.
  Future<void> saveEvent(ClinicalEvent event) async {
    _logger.info(
      'saveEvent: starting save for event id=${event.id} date=${event.date}',
    );
    await _repository.save(event);
    _logger.fine('saveEvent: repository.save completed for id=${event.id}');

    // Refresh presence map for a sliding window that includes the event date
    final start = event.date.subtract(const Duration(days: 30));
    final end = event.date.add(const Duration(days: 31));
    _logger.fine('saveEvent: fetching presence from $start to $end');
    final presence = await _repository.getDailyPresence(start, end);
    _logger.fine(
      'saveEvent: presence map retrieved (${presence.length} entries)',
    );

    _stateStore.setDailyClinicalEventPresence(presence);
    _logger.fine(
      'saveEvent: dailyClinicalEventPresence updated in EventStateStore',
    );

    // Normalize to local date-only (time removed) to avoid timezone mismatches.
    final localDate = DateTime(
      event.date.toLocal().year,
      event.date.toLocal().month,
      event.date.toLocal().day,
    );
    _stateStore.setSelectedDate(localDate);
    _logger.fine(
      'saveEvent: selectedDate set to $localDate in EventStateStore',
    );

    // Reload events for the normalized day so UI shows latest
    _logger.fine('saveEvent: loading clinical events for date $localDate');
    await _loadClinicalEventsForDate(localDate);
    _logger.fine('saveEvent: clinical events reloaded for $localDate');

    // Select the saved event in the centralized store
    _stateStore.setSelectedClinicalEvent(event);
    _logger.info('saveEvent: completed save flow for event id=${event.id}');

    // Mark data as dirty to trigger refresh
    _stateStore.markDataDirty();
  }

  /// Delete an event and refresh presence/map for the affected date range.
  Future<void> deleteEvent(String id) async {
    // Fetch event to learn its date (if available) before deletion
    final event = await _repository.getById(id);
    DateTime? affectedDate = event?.date;

    await _repository.deleteById(id);

    if (affectedDate != null) {
      final start = affectedDate.subtract(const Duration(days: 30));
      final end = affectedDate.add(const Duration(days: 31));
      final presence = await _repository.getDailyPresence(start, end);
      _stateStore.setDailyClinicalEventPresence(presence);

      // Reload events for the affected date
      await _loadClinicalEventsForDate(affectedDate);
    } else {
      // Fallback: refresh a default window
      await refreshAllData();
    }

    // Clear selection if it was the deleted event
    if (_stateStore.state.selectedClinicalEvent?.id == id) {
      _stateStore.setSelectedClinicalEvent(null);
    }

    // Mark data as dirty to trigger refresh
    _stateStore.markDataDirty();
  }

  /// Returns clinical events for a specific date (day).
  Future<List<ClinicalEvent>> getEventsForDate(DateTime date) async {
    return await _repository.getByDate(date);
  }

  /// Returns whether at least one clinical event exists for a date.
  bool hasClinicalEventForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _stateStore.state.dailyClinicalEventPresence?[normalized] == true;
  }

  /// Returns the last date a specific test type was performed (or null).
  Future<DateTime?> getLastTestDateFor(TestType testType) async {
    return await _repository.getLastTestDateFor(testType);
  }

  /// Returns the date of the most recent clinical event, or null if no events exist.
  Future<DateTime?> getLastClinicalEventDate() async {
    return await _repository.getLastClinicalEventDate();
  }

  /// Returns the dates of the most recent N clinical events, ordered by date descending.
  Future<List<DateTime>> getRecentClinicalEventDates(int count) async {
    return await _repository.getRecentClinicalEventDates(count);
  }

  /// Returns the most recent result for each TestType.
  Future<Map<TestType, ClinicalTestResult>> getLatestTestResults() async {
    return await _repository.getLatestTestResults();
  }

  /* -------------------------
     Private helpers
  ------------------------- */

  Future<void> _loadClinicalEventsForDate(DateTime date) async {
    _logger.info('_loadClinicalEventsForDate: loading events for date=$date');
    List<ClinicalEvent> events;
    try {
      events = await _repository.getByDate(date);
      _logger.fine(
        '_loadClinicalEventsForDate: repository returned ${events.length} event(s)',
      );
    } catch (e, st) {
      _logger.warning(
        '_loadClinicalEventsForDate: repository.getByDate failed: $e\n$st',
      );
      // On failure, ensure we clear current events to avoid stale UI state.
      _stateStore.setCurrentClinicalEvents([]);
      return;
    }

    // Normalize event dates to the local timezone so UI consumes local DateTimes.
    final normalized = events.map((e) {
      try {
        return e.copyWith(date: e.date.toLocal());
      } catch (err) {
        _logger.warning(
          '_loadClinicalEventsForDate: failed to normalize event ${e.id}: $err',
        );
        return e;
      }
    }).toList();

    // Write normalized day events directly into the store.
    _stateStore.setCurrentClinicalEvents(normalized);
    _logger.fine(
      '_loadClinicalEventsForDate: set ${normalized.length} events into EventStateStore',
    );
  }
}
