import 'package:uuid/uuid.dart';

class Person {
  String id;
  String firstName;
  String? lastName;
  String? nickname;
  DateTime? birthDay;

  DateTime? dateMet;

  String? homeLocation;
  int? challengeRating;
  String? bodyType;

  Person._(this.id, this.firstName, this.lastName, this.nickname, this.birthDay,
      this.dateMet, this.homeLocation, this.challengeRating, this.bodyType);

  factory Person(
      String firstName,
      String? lastName,
      String? nickname,
      DateTime? birthDay,
      DateTime? dateMet,
      String? homeLocation,
      int? challengeRating,
      String? bodyType) {
    const uuid = Uuid();
    return Person._(
      uuid.v4(),
      firstName,
      lastName,
      nickname,
      birthDay,
      dateMet,
      homeLocation,
      challengeRating,
      bodyType,
    );
  }

  factory Person.fromMap(Map<String, Object?> map) {
    String id = map["id"] as String;
    String firstName = map["firstName"] as String;
    String? lastName = map["lastName"] as String?;
    String? nickname = map["nickname"] as String?;
    DateTime? birthDay;
    if (map["birthDay"] != null) {
      birthDay = DateTime.parse(map["birthDay"] as String);
    }
    DateTime? dateMet;
    if (map["dateMet"] != null) {
      dateMet = DateTime.parse(map["dateMet"] as String);
    }
    String? homeLocation = map["homeLocation"] as String?;
    int? challengeRating = map["challengeRating"] as int?;
    String? bodyType = map["bodyType"] as String?;

    return Person._(id, firstName, lastName, nickname, birthDay, dateMet,
        homeLocation, challengeRating, bodyType);
  }
}
