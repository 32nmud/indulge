import 'package:freezed_annotation/freezed_annotation.dart';
import '../address/address.dart';

part 'location.freezed.dart';
part 'location.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class Location with _$Location {
  const Location._();

  const factory Location({
    required double latitude,
    required double longitude,
    Address? address,
  }) = _Location;

  // -----------------------------------------------------------------
  // Custom JSON (de)serialization
  // -----------------------------------------------------------------
  factory Location.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('address')) {
      throw ArgumentError('Missing required field "address"');
    }
    // Remove any incoming `resourceType` – we ignore it completely.
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$LocationFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    // Let the generated helper create the map, then inject the constant.
    final map = _$LocationToJson(this as _Location);
    map['resourceType'] = "Location"; // guarantee the correct value
    return map;
  }

  // -----------------------------------------------------------------
  // Fixed getters
  // -----------------------------------------------------------------
  @JsonKey(name: 'resourceType')
  String get resourceType => "Location";
}
