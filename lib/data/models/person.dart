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

  @override
  String toString() =>
      'Person(id: $id, firstName: $firstName, lastName: $lastName, nickname: $nickname, locationId: $locationId)';
}
