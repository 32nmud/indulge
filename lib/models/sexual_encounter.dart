import 'location.dart';

class SexualEncounter{
  final String id;
  final DateTime creationDate;
  final DateTime lastUpdateDate;
  final Location? location;
  final List<String>? partners;
  final List<String>? activities;
  final String? enjoyment;
  final String? notes;
  final String? media;

  SexualEncounter({
    required this.id,
    required this.creationDate,
    required this.lastUpdateDate,
    this.location,
    this.partners,
    this.activities,
    this.enjoyment,
    this.notes,
    this.media
  });
  
  Map<String, dynamic> toJson() { 
    return {
      'id': id,
      'creationDate': creationDate.toIso8601String(),
      'lastUpdateDate': lastUpdateDate.toIso8601String(),
      'location': location?.toJson(),
      'partners': partners?.map((partner) => partner).toList(),
      'activities': activities?.map((partner) => partner).toList(),
      'enjoyment': enjoyment,
      'notes': notes,
      'media': media,
    };
  }

  factory SexualEncounter.fromJson(Map<String, dynamic> json) {
    return SexualEncounter(
      id: json['id'],
      creationDate: json['creationDate'],
      lastUpdateDate: json['lastUpdateDate'],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      partners: json['partners'],
      activities: json['activities'],
      enjoyment: json['enjoyment'],
      notes: json['notes'],
      media: json['media'],
    );
  }
  
    SexualEncounter copyWith({
    String? id,
    DateTime? creationDate,
    DateTime? lastUpdateDate,
    Location? location,
    List<String>? partners,
    List<String>? activities,
    String? enjoyment,
    String? notes,
    String? media,
  }) {
    return SexualEncounter(
      id: id ?? this.id,
      creationDate: creationDate ?? this.creationDate,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      location: location ?? this.location,
      partners: partners ?? this.partners,
      activities: activities ?? this.activities,
      enjoyment: enjoyment ?? this.enjoyment,
      notes: notes ?? this.notes,
      media: media ?? this.media,
    );
  }
}
