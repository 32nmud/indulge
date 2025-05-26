class Coordinate {
  final String lat;
  final String long;

  // Constructor
  Coordinate({required this.lat, required this.long});

  // Method to convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      "lat": lat,
      "long": long,
    };
  }

  // Factory method to create a User from JSON
  factory Coordinate.fromJson(Map<String, dynamic> json) {
    return Coordinate(
      lat: json['lat'],
      long: json['long'],
    );
  }

  // Override toString for better readability
  @override
  String toString() {
    return 'Coordinate(lat: $lat, long: $long)';
  }
}
