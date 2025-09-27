import 'package:meta/meta.dart';
import 'enums.dart';

@immutable
class HealthTest {
  final int? id;
  final TestType testType;
  final String? notes;

  const HealthTest({
    this.id,
    required this.testType,
    this.notes,
  });

  factory HealthTest.fromMap(Map<String, dynamic> map) {
    return HealthTest(
      id: map['id'] as int?,
      testType: TestType.values.firstWhere(
        (e) => e.name == map['test_type'] as String,
      ),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'test_type': testType.name,
      'notes': notes,
    };
  }

  HealthTest copyWith({
    int? id,
    TestType? testType,
    String? notes,
  }) {
    return HealthTest(
      id: id ?? this.id,
      testType: testType ?? this.testType,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'HealthTest(id: $id, testType: $testType, notes: $notes)';
}
