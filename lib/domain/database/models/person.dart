import 'package:meta/meta.dart';

@immutable
class Person {
  final int? id;
  final String firstName;
  final String? lastName;
  final String? nickname;
  final int? locationId;

  const Person({
    this.id,
    required this.firstName,
    this.lastName,
    this.nickname,
    this.locationId,
  });

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int?,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String?,
      nickname: map['nickname'] as String?,
      locationId: map['location_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'nickname': nickname,
      'location_id': locationId,
    };
  }

  Person copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? nickname,
    int? locationId,
  }) {
    return Person(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickname: nickname ?? this.nickname,
      locationId: locationId ?? this.locationId,
    );
  }

  @override
  String toString() =>
      'Person(id: $id, firstName: $firstName, lastName: $lastName, nickname: $nickname, locationId: $locationId)';
}
