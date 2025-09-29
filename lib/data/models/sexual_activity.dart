import 'package:meta/meta.dart';

@immutable
class SexualActivity {
  final int? id;
  final int eventId;
  final int activityId;
  final String name;
  final int minParticipants;
  final int maxParticipants;
  final String displayCharacter;
  final bool isRisky;

  const SexualActivity({
    this.id,
    required this.eventId,
    required this.activityId,
    required this.name,
    required this.minParticipants,
    required this.maxParticipants,
    required this.displayCharacter,
    required this.isRisky,
  });

  @override
  String toString() =>
      'SexualActivity(id: $id, eventId: $eventId, activityId: $activityId, name: $name, minParticipants: $minParticipants, maxParticipants: $maxParticipants, displayCharacter: $displayCharacter, isRisky: $isRisky)';
}
