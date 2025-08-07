class Encounter {
  final String id;
  final DateTime creationDate;
  final DateTime lastModifiedDate;
  final List<String> personIds;

  Encounter({
    required this.id,
    required this.creationDate,
    required this.lastModifiedDate,
    this.personIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "creationDate": creationDate.toIso8601String(),
      "lastModifiedDate": lastModifiedDate.toIso8601String(),
      "personIds": personIds,
    };
  }

  @override
  String toString() {
    return 'Encounter(id: $id, creationDate: $creationDate, lastModifiedDate: $lastModifiedDate, personIds: $personIds)';
  }
}
