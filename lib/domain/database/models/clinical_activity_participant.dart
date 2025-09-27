import 'package:meta/meta.dart';

@immutable
class ClinicalActivityParticipant {
  final int? id;
  final int clinicalActivityId;
  final int personId;

  const ClinicalActivityParticipant({
    this.id,
    required this.clinicalActivityId,
    required this.personId,
  });

  factory ClinicalActivityParticipant.fromMap(Map<String, dynamic> map) {
    return ClinicalActivityParticipant(
      id: map['id'] as int?,
      clinicalActivityId: map['clinical_activity_id'] as int,
      personId: map['person_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinical_activity_id': clinicalActivityId,
      'person_id': personId,
    };
  }

  ClinicalActivityParticipant copyWith({
    int? id,
    int? clinicalActivityId,
    int? personId,
  }) {
    return ClinicalActivityParticipant(
      id: id ?? this.id,
      clinicalActivityId: clinicalActivityId ?? this.clinicalActivityId,
      personId: personId ?? this.personId,
    );
  }

  @override
  String toString() =>
      'ClinicalActivityParticipant(id: $id, clinicalActivityId: $clinicalActivityId, personId: $personId)';
}
