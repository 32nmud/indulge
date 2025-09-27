import 'package:meta/meta.dart';

@immutable
class Location {
  final int? id;
  final String address;
  final String? city;
  final String? state;
  final String? zip;

  const Location({
    this.id,
    required this.address,
    this.city,
    this.state,
    this.zip,
  });

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'] as int?,
      address: map['address'] as String,
      city: map['city'] as String?,
      state: map['state'] as String?,
      zip: map['zip'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
    };
  }

  Location copyWith({
    int? id,
    String? address,
    String? city,
    String? state,
    String? zip,
  }) {
    return Location(
      id: id ?? this.id,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
    );
  }

  @override
  String toString() {
    return 'Location(id: $id, address: $address, city: $city, state: $state, zip: $zip)';
  }
}
