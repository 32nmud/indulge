import 'package:indulge/data/models.dart';
import 'package:indulge/provider/sexual_event_provider.dart';

/// A pre-fetched, in-memory cache of [Person] objects keyed by ID.
///
/// Instead of hitting the database for every participant in every activity
/// in every event (potentially thousands of queries for the same few people),
/// this cache loads all persons in a single query upfront and provides
/// synchronous O(1) lookups.
class PersonCache {
  final Map<String, Person> _cache;

  PersonCache._(this._cache);

  /// Builds a [PersonCache] by fetching all persons from the provider
  /// in a single database call.
  static Future<PersonCache> build(SexualEventsProvider provider) async {
    final allPersons = await provider.getAllPersons();
    final cache = <String, Person>{};
    for (final person in allPersons) {
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
}
