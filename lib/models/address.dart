class Address {
  final String line1;
  final String? line2;
  final String? state;
  final String? zipCode;
  final String? name;

  // Constructor
  Address({
    required this.line1,
    this.line2,
    this.state,
    this.zipCode,
    this.name,
  });

  // Method to convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      "line1": line1,
      "line2": line2,
      "state": state,
      "zipCode": zipCode,
      "name": name,
    };
  }

  // Factory method to create a User from JSON
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      line1: json['line1'],
      line2: json['line2'],
      state: json['state'],
      zipCode: json['zipCode'],
      name: json['name'],
    );
  }

  // Override toString for better readability
  @override
  String toString() {
    return 'Address(line1: $line1, line2: $line2, state: $state, zipCode: $zipCode, name: $name)';
  }
}
