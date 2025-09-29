import 'package:meta/meta.dart';

@immutable
class Coordinate {
  final int? id;
  final double lat;
  final double long;

  const Coordinate({
    this.id,
    required this.lat,
    required this.long,
  });

  factory Coordinate.fromMap(Map<String, dynamic> map) {
    return Coordinate(
      id: map['id'] as int?,
      lat: (map['lat'] as num).toDouble(),
      long: (map['long'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lat': lat,
      'long': long,
    };
  }

  Coordinate copyWith({
    int? id,
    double? lat,
    double? long,
  }) {
    return Coordinate(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      long: long ?? this.long,
    );
  }

  @override
  String toString() {
    return 'Coordinate(id: $id, lat: $lat, long: $long)';
  }
}
