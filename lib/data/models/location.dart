import 'dart:ffi';

import 'package:meta/meta.dart';

@immutable
class Location {
  final int? id;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final double? lat;
  final double? long;

  const Location({
    this.id,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.lat,
    this.long,
  });

  @override
  String toString() =>
      'Location(id: $id, address: $address, city: $city, state: $state, zip: $zip, lat: $lat, long: $long)';
}
