import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/analysis/utils/person_cache.dart';

void main() {
  group('PersonCache', () {
    group('fromList', () {
      test('creates empty cache from empty list', () {
        final cache = PersonCache.fromList([]);

        expect(cache.getPersonById('any-id'), isNull);
        expect(cache.persons, isEmpty);
      });

      test('creates cache with single person', () {
        final person = Person(
          id: 'person-1',
          date: DateTime(2024, 1, 1),
          name: const Name(given: 'John', family: 'Doe'),
          isSelf: false,
        );

        final cache = PersonCache.fromList([person]);

        expect(cache.getPersonById('person-1'), person);
        expect(cache.getPersonById('non-existent'), isNull);
      });

      test('creates cache with multiple persons', () {
        final person1 = Person(
          id: 'person-1',
          date: DateTime(2024, 1, 1),
          name: const Name(given: 'John', family: 'Doe'),
          isSelf: true,
        );
        final person2 = Person(
          id: 'person-2',
          date: DateTime(2024, 1, 2),
          name: const Name(given: 'Jane', family: 'Smith'),
          isSelf: false,
        );

        final cache = PersonCache.fromList([person1, person2]);

        expect(cache.getPersonById('person-1'), person1);
        expect(cache.getPersonById('person-2'), person2);
        expect(cache.persons.length, 2);
      });

      test('overwrites duplicate person IDs with latest entry', () {
        final person1 = Person(
          id: 'person-1',
          date: DateTime(2024, 1, 1),
          name: const Name(given: 'John', family: 'Doe'),
          isSelf: false,
        );
        final person2 = Person(
          id: 'person-1',
          date: DateTime(2024, 1, 2),
          name: const Name(given: 'Johnny', family: 'D'),
          isSelf: false,
        );

        final cache = PersonCache.fromList([person1, person2]);

        expect(cache.getPersonById('person-1'), person2);
        expect(cache.persons.length, 1);
      });
    });

    group('getPersonById', () {
      test('returns null for non-existent ID', () {
        final cache = PersonCache.fromList([]);

        expect(cache.getPersonById('missing'), isNull);
      });

      test('returns correct person by ID', () {
        final person = Person(
          id: 'test-id',
          date: DateTime(2024, 1, 1),
          name: const Name(given: 'Test', family: 'User'),
          isSelf: false,
        );

        final cache = PersonCache.fromList([person]);

        expect(cache.getPersonById('test-id'), person);
      });
    });

    group('isSelf', () {
      test('returns false for non-existent person', () {
        final cache = PersonCache.fromList([]);

        expect(cache.isSelf('missing'), false);
      });

      test('returns true when person has isSelf true', () {
        final selfPerson = Person(
          id: 'self-id',
          date: DateTime(2024, 1, 1),
          name: const Name(given: 'Me', family: 'Self'),
          isSelf: true,
        );

        final cache = PersonCache.fromList([selfPerson]);

        expect(cache.isSelf('self-id'), true);
      });

      test('returns false when person has isSelf false', () {
        final otherPerson = Person(
          id: 'other-id',
          date: DateTime(2024, 1, 1),
          name: const Name(given: 'Other', family: 'Person'),
          isSelf: false,
        );

        final cache = PersonCache.fromList([otherPerson]);

        expect(cache.isSelf('other-id'), false);
      });
    });

    group('persons', () {
      test('returns all persons as list', () {
        final person1 = Person(
          id: 'p1',
          date: DateTime(2024, 1, 1),
          name: const Name(given: 'One', family: 'A'),
          isSelf: true,
        );
        final person2 = Person(
          id: 'p2',
          date: DateTime(2024, 1, 2),
          name: const Name(given: 'Two', family: 'B'),
          isSelf: false,
        );

        final cache = PersonCache.fromList([person1, person2]);
        final persons = cache.persons;

        expect(persons.length, 2);
        expect(persons.contains(person1), true);
        expect(persons.contains(person2), true);
      });

      test('returns empty list for empty cache', () {
        final cache = PersonCache.fromList([]);

        expect(cache.persons, isEmpty);
      });
    });
  });
}
