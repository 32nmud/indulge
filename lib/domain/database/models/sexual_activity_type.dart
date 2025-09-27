import 'package:meta/meta.dart';

@immutable
class SexualActivityType {
  final int? id;
  final String name;
  final int minParticipants;
  final int maxParticipants;
  final String displayCharacter;
  final bool isRisky;

  const SexualActivityType({
    this.id,
    required this.name,
    required this.minParticipants,
    required this.maxParticipants,
    required this.displayCharacter,
    required this.isRisky,
  });

  factory SexualActivityType.fromMap(Map<String, dynamic> map) {
    return SexualActivityType(
      id: map['id'] as int?,
      name: map['name'] as String,
      minParticipants: (map['min_participants'] as int?) ?? 0,
      maxParticipants: (map['max_participants'] as int?) ?? 0,
      displayCharacter: map['display_character'] as String? ?? '',
      isRisky: map['is_risky'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'min_participants': minParticipants,
        'max_participants': maxParticipants,
        'display_character': displayCharacter,
        'is_risky': isRisky,
      };

  SexualActivityType copyWith({
    int? id,
    String? name,
    int? minParticipants,
    int? maxParticipants,
    String? displayCharacter,
    bool? isRisky,
  }) {
    return SexualActivityType(
      id: id ?? this.id,
      name: name ?? this.name,
      minParticipants: minParticipants ?? this.minParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      displayCharacter: displayCharacter ?? this.displayCharacter,
      isRisky: isRisky ?? this.isRisky,
    );
  }
}
