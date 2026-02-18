import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/view/analysis/utils/calculator_utils/partner_count_converter.dart';

void main() {
  group('PartnerCountConverter', () {
    group('convertPartnerCounts', () {
      test('returns empty map for empty input', () {
        final result = PartnerCountConverter.convertPartnerCounts({});

        expect(result, isEmpty);
      });

      test('converts single partner set correctly', () {
        final partnerSets = {
          'event-1': {'partner-a', 'partner-b'},
        };

        final result = PartnerCountConverter.convertPartnerCounts(partnerSets);

        expect(result['event-1'], 2);
      });

      test('converts multiple partner sets correctly', () {
        final partnerSets = {
          'event-1': {'partner-a'},
          'event-2': {'partner-a', 'partner-b', 'partner-c'},
          'event-3': <String>{},
        };

        final result = PartnerCountConverter.convertPartnerCounts(partnerSets);

        expect(result['event-1'], 1);
        expect(result['event-2'], 3);
        expect(result['event-3'], 0);
      });

      test('handles events with no partners', () {
        final partnerSets = {'solo-event': <String>{}};

        final result = PartnerCountConverter.convertPartnerCounts(partnerSets);

        expect(result['solo-event'], 0);
      });

      test('preserves all keys from input', () {
        final partnerSets = {
          'event-a': {'p1'},
          'event-b': {'p1', 'p2'},
          'event-c': {'p1', 'p2', 'p3'},
        };

        final result = PartnerCountConverter.convertPartnerCounts(partnerSets);

        expect(result.keys.toSet(), {'event-a', 'event-b', 'event-c'});
      });
    });

    group('convertNestedPartnerCounts', () {
      test('returns empty map for empty input', () {
        final result = PartnerCountConverter.convertNestedPartnerCounts({});

        expect(result, isEmpty);
      });

      test('converts single nested partner set correctly', () {
        final nestedPartnerSets = {
          'kissing': {
            'lip-kiss': {'partner-a', 'partner-b'},
          },
        };

        final result = PartnerCountConverter.convertNestedPartnerCounts(
          nestedPartnerSets,
        );

        expect(result['kissing']!['lip-kiss'], 2);
      });

      test('converts multiple categories and activities correctly', () {
        final nestedPartnerSets = {
          'kissing': {
            'lip-kiss': {'partner-a'},
            'french-kiss': {'partner-a', 'partner-b'},
          },
          'foreplay': {
            'fingering': {'partner-c'},
          },
        };

        final result = PartnerCountConverter.convertNestedPartnerCounts(
          nestedPartnerSets,
        );

        expect(result['kissing']!['lip-kiss'], 1);
        expect(result['kissing']!['french-kiss'], 2);
        expect(result['foreplay']!['fingering'], 1);
      });

      test('handles empty activity sets', () {
        final nestedPartnerSets = {
          'solo': {'masturbation': <String>{}},
        };

        final result = PartnerCountConverter.convertNestedPartnerCounts(
          nestedPartnerSets,
        );

        expect(result['solo']!['masturbation'], 0);
      });

      test('handles categories with no activities', () {
        final nestedPartnerSets = {'empty-category': <String, Set<String>>{}};

        final result = PartnerCountConverter.convertNestedPartnerCounts(
          nestedPartnerSets,
        );

        expect(result['empty-category'], isEmpty);
      });

      test('preserves structure of nested maps', () {
        final nestedPartnerSets = {
          'category-a': {
            'activity-1': {'p1'},
            'activity-2': {'p1', 'p2'},
          },
          'category-b': {
            'activity-3': {'p1', 'p2', 'p3'},
          },
        };

        final result = PartnerCountConverter.convertNestedPartnerCounts(
          nestedPartnerSets,
        );

        expect(result.keys.toSet(), {'category-a', 'category-b'});
        expect(result['category-a']!.keys.toSet(), {
          'activity-1',
          'activity-2',
        });
        expect(result['category-b']!.keys.toSet(), {'activity-3'});
      });
    });
  });
}
