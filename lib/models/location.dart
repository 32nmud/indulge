import 'address.dart';
import 'coordinate.dart';

class Location {
  final String id;
  final DateTime creationDate;
  final DateTime lastModifiedDate;
  final Address? address;
  final Coordinate? coordinate;
  final String? name;

  // Constructor
  Location({
    required this.id,
    required this.creationDate,
    required this.lastModifiedDate,
    this.address,
    this.coordinate,
    this.name,
  });

  // Method to convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creationDate': creationDate.toIso8601String(),
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
      'address': address?.toJson(),
      'coordinate': coordinate?.toJson(),
      'name': name,
    };
  }

  // Factory method to create a User from JSON
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      creationDate: DateTime.parse(json['creationDate']),
      lastModifiedDate: DateTime.parse(json['lastModifiedDate']),
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      coordinate: json['coordinate'] != null ? Coordinate.fromJson(json['coordinate']) : null,
      name: json['name'],
    );
  }

  // Override toString for better readability
  @override
  String toString() {
    return 'Location(id: $id, creationDate: $creationDate, lastModifiedDate: $lastModifiedDate, address: $address, coordinate: $coordinate)';
  }
}
