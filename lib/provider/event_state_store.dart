import 'package:flutter/foundation.dart';
import 'package:indulge/provider/event_state.dart';
import 'package:indulge/data/models.dart';

/// Centralized EventState store (single source of truth).
///
/// Providers can attach to this store and forward state updates. The store
/// keeps an immutable `EventState` internally and exposes small setters that
/// update only the relevant slice and notify listeners once per logical update.
class EventStateStore extends ChangeNotifier {
  EventState _state = EventState();

  EventState get state => _state;

  void _update(EventState Function(EventState) updater) {
    _state = updater(_state);
    notifyListeners();
  }

  /// Sexual event related setters
  void setDailyEventCount(Map<DateTime, int>? counts) =>
      _update((s) => s.copyWith(dailyEventCount: counts));

  void setCurrentEvents(List<SexualEvent>? events) =>
      _update((s) => s.copyWith(currentEvents: events));

  void setSelectedEvent(SexualEvent? event) =>
      _update((s) => s.copyWith(selectedEvent: event));

  void setSelectedDate(DateTime? date) =>
      _update((s) => s.copyWith(selectedDate: date));

  void setSexualActivityCategories(
    Map<String, SexualActivityCategory>? categories,
  ) => _update((s) => s.copyWith(sexualActivityCategories: categories));

  void setSexualActivities(Map<String, SexualActivity>? activities) =>
      _update((s) => s.copyWith(sexualActivities: activities));

  void setMyself(Person? me) => _update((s) => s.copyWith(myself: me));

  /// Cache/seed the global list of known persons so UI and analysis code can
  /// access persons without triggering separate DB calls. This is populated
  /// by providers during initialization or when persons are modified.
  void setAllPersons(List<Person>? persons) =>
      _update((s) => s.copyWith(allPersons: persons));

  /// Convenience getter that returns a map of person id -> Person for quick
  /// lookups by id. Returns null if the cached list is not populated.
  Map<String, Person>? get allPersonsMap {
    final all = _state.allPersons;
    if (all == null) return null;
    return Map.fromEntries(all.map((p) => MapEntry(p.id, p)));
  }

  /// Non-nullable view of cached persons. Returns an empty map when the cache
  /// is not yet populated, useful to avoid null checks in UI code.
  Map<String, Person> get allPersonsOrEmpty {
    final all = _state.allPersons;
    if (all == null) return const {};
    return Map.fromEntries(all.map((p) => MapEntry(p.id, p)));
  }

  /// Lookup helper to find a cached Person by id. Returns null if not present.
  Person? getPersonById(String id) =>
      allPersonsMap == null ? null : allPersonsMap![id];

  /// Sexual activities convenience accessors
  Map<String, SexualActivity>? get sexualActivitiesMap =>
      _state.sexualActivities;

  SexualActivity? getActivityById(String id) =>
      _state.sexualActivities == null ? null : _state.sexualActivities![id];

  /// Sexual activity categories convenience accessors
  Map<String, SexualActivityCategory>? get sexualActivityCategoriesMap =>
      _state.sexualActivityCategories;

  SexualActivityCategory? getCategoryById(String id) =>
      _state.sexualActivityCategories == null
      ? null
      : _state.sexualActivityCategories![id];

  /// Convenience getter for the cached 'myself' person id (if present).
  String? get myselfId => _state.myself?.id;

  void setSelectedEventLocation(Location? loc) =>
      _update((s) => s.copyWith(selectedEventLocation: loc));

  void setSelectedEventParticipants(List<Person>? participants) =>
      _update((s) => s.copyWith(selectedEventParticipants: participants));

  void setSelectedEventSexualActivityParticipants(
    List<ActivityParticipant>? sap,
  ) => _update((s) => s.copyWith(selectedEventSexualActivityParticipants: sap));

  void setSelectedEventActivityParticipants(Map<String, List<Person>>? map) =>
      _update((s) => s.copyWith(selectedEventActivityParticipants: map));

  /// Clinical event related setters
  void setDailyClinicalEventPresence(Map<DateTime, bool>? presence) =>
      _update((s) => s.copyWith(dailyClinicalEventPresence: presence));

  void setCurrentClinicalEvents(List<ClinicalEvent>? events) =>
      _update((s) => s.copyWith(currentClinicalEvents: events));

  void setSelectedClinicalEvent(ClinicalEvent? event) =>
      _update((s) => s.copyWith(selectedClinicalEvent: event));

  /// Composite helper for clinical event save/delete flows to avoid multiple notifications.
  /// Updates presence map, events for a date, and selected clinical event in one atomic update.
  void applyClinicalEventSave({
    required Map<DateTime, bool>? presence,
    required List<ClinicalEvent>? eventsForDate,
    ClinicalEvent? selected,
  }) {
    _state = _state.copyWith(
      dailyClinicalEventPresence: presence,
      currentClinicalEvents: eventsForDate,
      selectedClinicalEvent: selected,
    );
    notifyListeners();
  }

  /// Composite helper for sexual event save/delete flows to avoid multiple notifications.
  /// Updates daily counts, events for a date, and selected sexual event atomically.
  void applySexualEventSave({
    required Map<DateTime, int>? dailyCounts,
    required List<SexualEvent>? eventsForDate,
    SexualEvent? selected,
  }) {
    _state = _state.copyWith(
      dailyEventCount: dailyCounts,
      currentEvents: eventsForDate,
      selectedEvent: selected,
    );
    notifyListeners();
  }
}
