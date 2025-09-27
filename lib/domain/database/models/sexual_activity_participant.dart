import 'package:meta/meta.dart';

@immutable
class SexualActivityParticipant {
  final int? id;
  final int sexualActivityId;
  final int personId;

  const SexualActivityParticipant({
    this.id,
    required this.sexualActivityId,
    required this.personId,
  });

  factory SexualActivityParticipant.fromMap(Map<String, dynamic> map) {
    return SexualActivityParticipant(
      id: map['id'] as int?,
      sexualActivityId: map['sexual_activity_id'] as int,
      personId: map['person_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sexual_activity_id': sexualActivityId,
      'person_id': personId,
    };
  }

  SexualActivityParticipant copyWith({
    int? id,
    int? sexualActivityId,
    int? personId,
  }) {
    return SexualActivityParticipant(
      id: id ?? this.id,
      sexualActivityId: sexualActivityId ?? this.sexualActivityId,
      personId: personId ?? this.personId,
    );
  }

  @override
  String toString() =>
      'SexualActivityParticipant(id: $id, sexualActivityId: $sexualActivityId, personId: $personId)';
}
