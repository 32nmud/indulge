import '../../data/models/sexual_event.dart';

/// Contract for CRUD operations on a *SexualEvent*.
/// The UI (or higher‑level services) will depend on this interface,
/// while the concrete implementation lives in the data layer.
abstract class SexualEventRepository {
  /// Load a single event by its database id.
  Future<SexualEvent?> getById(int id);

  /// Load all events that occur on the supplied [date].
  /// The [date] argument is interpreted as a calendar day
  /// (time component is ignored).
  Future<List<SexualEvent>> getByDate(DateTime date);

  /// Load a count of all events that occur on any date.
  Future<Map<DateTime, int>> getDailyEventCount();

  /// Persist a new or existing event.
  /// If [event.baseEventId] is null, a new row is inserted
  /// and the generated id is returned.
  /// If an id is present, the existing row is updated.
  Future<int> save(SexualEvent event);

  /// Delete the event identified by [id].
  Future<void> delete(int id);

  /// Remove a sexual activity by its database id.
  Future<void> removeActivity(int id);
}
