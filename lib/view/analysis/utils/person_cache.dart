import 'package:indulge/data/models.dart';
import 'package:indulge/provider/sexual_event_provider.dart';

/// A pre-fetched, in-memory cache of [Person] objects keyed by ID.
///
/// Instead of hitting the database for every participant in every activity
/// in every event (potentially thousands of queries for the same few people),
/// this cache loads all persons in a single query upfront and provides
/// synchronous O(1) lookups.
///
/// Migration note:
/// - `build` still accepts a `SexualEventsProvider` for backward compatibility,
///   but now also accepts an optional `preFetched` list of persons. Callers
///   that already have a snapshot (for example from `EventStateStore.state`)
///   can pass that list to avoid an extra DB call.
class PersonCache {
  final Map<String, Person> _cache;

  PersonCache._(this._cache);

  /// Builds a [PersonCache] by fetching all persons from the provider
  /// in a single database call, unless an optional pre-fetched list is supplied.
  ///
  /// Usage:
  /// - `PersonCache.build(provider)` (existing behavior)
  /// - `PersonCache.build(provider, preFetched: personsFromStore)` to avoid an extra DB call.
  static Future<PersonCache> build(
    SexualEventsProvider provider, {
    List<Person>? preFetched,
  }) async {
    final allPersons = preFetched ?? await provider.getAllPersons();
    final cache = <String, Person>{};
    for (final person in allPersons) {
      cache[person.id] = person;
    }
    return PersonCache._(cache);
  }

  /// Convenience constructor when callers already have the full list synchronously.
  static PersonCache fromList(List<Person> persons) {
    final cache = <String, Person>{};
    for (final person in persons) {
      cache[person.id] = person;
    }
    return PersonCache._(cache);
  }

  /// Returns the [Person] for the given [id], or `null` if not found.
  Person? getPersonById(String id) => _cache[id];

  /// Returns `true` if the person with [id] has `isSelf == true`.
  ///
  /// Returns `false` if the person is not found or `isSelf` is false.
  bool isSelf(String id) => _cache[id]?.isSelf ?? false;

  /// Returns all persons in the cache as a list.
  List<Person> get persons => _cache.values.toList();
}
