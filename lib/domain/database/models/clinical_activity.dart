import 'package:meta/meta.dart';
import 'enums.dart';

@immutable
class ClinicalActivity {
  final int? id;
  final int eventId;
  final int testId;
  final TestResult? result;

  const ClinicalActivity({
    this.id,
    required this.eventId,
    required this.testId,
    this.result,
  });

  factory ClinicalActivity.fromMap(Map<String, dynamic> map) {
    return ClinicalActivity(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      testId: map['test_id'] as int,
      result: map['result'] != null
          ? TestResult.values
              .firstWhere((e) => e.name == map['result'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'test_id': testId,
      'result': result?.name,
    };
  }

  ClinicalActivity copyWith({
    int? id,
    int? eventId,
    int? testId,
    TestResult? result,
  }) {
    return ClinicalActivity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      testId: testId ?? this.testId,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return 'ClinicalActivity(id: $id, eventId: $eventId, testId: $testId, result: $result)';
  }
}
