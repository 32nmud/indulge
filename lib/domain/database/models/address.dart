import 'package:meta/meta.dart';

@immutable
class Address {
  final int? id;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String zip;

  const Address({
    this.id,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.zip,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] as int?,
      line1: map['line_1'] as String,
      line2: map['line_2'] as String?,
      city: map['city'] as String,
      state: map['state'] as String,
      zip: map['zip'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'line_1': line1,
      'line_2': line2,
      'city': city,
      'state': state,
      'zip': zip,
    };
  }

  Address copyWith({
    int? id,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? zip,
  }) {
    return Address(
      id: id ?? this.id,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
    );
  }

  @override
  String toString() {
    return 'Address(id: $id, line1: $line1, line2: $line2, city: $city, state: $state, zip: $zip)';
  }
}

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
