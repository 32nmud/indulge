import 'dart:convert';
import 'location.dart';
import 'encounter.dart';
import 'dart:typed_data';

class SexualEncounter extends Encounter {
  final Location? location;
  final List<String>? partners;
  final List<String>? activities;
  final String? enjoyment;
  final String? notes;
  final Uint8List? media;

  SexualEncounter({
    required super.id,
    required super.creationDate,
    required super.lastModifiedDate,
    this.location,
    this.partners,
    this.activities,
    this.enjoyment,
    this.notes,
    this.media,
  });

  factory SexualEncounter.fromJson(Map<String, dynamic> json) {
    return SexualEncounter(
      id: json['id'],
      creationDate: DateTime.parse(json['creationDate']),
      lastModifiedDate: DateTime.parse(json['lastModifiedDate']),
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      partners: json['partners'],
      activities: json['activities'],
      enjoyment: json['enjoyment'],
      notes: json['notes'],
      media: json['media'] != null
          ? Uint8List.fromList(base64Decode(json['media']))
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'location': location?.toJson(),
      'partners': partners,
      'activities': activities,
      'enjoyment': enjoyment,
      'notes': notes,
      'media': base64Encode(media ?? []),
    };
  }

  @override
  String toString() {
    return 'SexualEncounter(${super.toString()}, location: $location, partners: $partners, activities: $activities, enjoyment: $enjoyment, notes: $notes, media: $media)';
  }

  SexualEncounter copyWith({
    String? id,
    DateTime? creationDate,
    DateTime? lastModifiedDate,
    Location? location,
    List<String>? partners,
    List<String>? activities,
    String? enjoyment,
    String? notes,
    Uint8List? media,
  }) {
    return SexualEncounter(
      id: id ?? this.id,
      creationDate: creationDate ?? this.creationDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      location: location ?? this.location,
      partners: partners ?? this.partners,
      activities: activities ?? this.activities,
      enjoyment: enjoyment ?? this.enjoyment,
      notes: notes ?? this.notes,
      media: media ?? this.media,
    );
  }
}
