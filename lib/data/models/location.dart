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

  @override
  String toString() =>
      'Location(id: $id, address: $address, city: $city, state: $state, zip: $zip)';
}
