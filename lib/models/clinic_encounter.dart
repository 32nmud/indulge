import 'encounter.dart';

class ClinicalEncounter extends Encounter {
  final String? diagnosis;
  final Map<String, String>? testResults;

  // Constructor
  ClinicalEncounter({
    required super.id,
    required super.creationDate,
    required super.lastModifiedDate,
    required this.diagnosis,
    required this.testResults,
    super.personIds = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "diagnosis": diagnosis,
      "testResults": testResults,
    };
  }

  factory ClinicalEncounter.fromJson(Map<String, dynamic> json) {
    return ClinicalEncounter(
      id: json['id'],
      creationDate: DateTime.parse(json['creationDate']),
      lastModifiedDate: DateTime.parse(json['lastModifiedDate']),
      diagnosis: json['diagnosis'],
      testResults: json['testResults'] == null
          ? {}
          : Map.fromEntries(
              json['testResults'].map(
                  (entry) => MapEntry(entry.keys.first, entry.values.first)),
            ),
      personIds: List<String>.from(json['personIds'] ?? []),
    );
  }

  @override
  String toString() {
    return 'ClinicalEncounter(${super.toString()}, diagnosis: $diagnosis, testResults: ${testResults?.map((key, value) => '$key: $value').toList().join(', ')})';
  }

  ClinicalEncounter copyWith({
    String? id,
    DateTime? creationDate,
    DateTime? lastModifiedDate,
    List<String>? personIds,
    String? diagnosis,
    Map<String, String>? testResults,
  }) {
    return ClinicalEncounter(
      id: id ?? this.id,
      creationDate: creationDate ?? this.creationDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      personIds: personIds ?? this.personIds,
      diagnosis: diagnosis ?? this.diagnosis,
      testResults: testResults ?? this.testResults,
    );
  }
  }
}
