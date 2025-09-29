import 'package:meta/meta.dart';

@immutable
class Location {
  final int? id;
  final int? addressId;
  final int? coordinateId;
  final String? nickname;

  const Location({
    this.id,
    this.addressId,
    this.coordinateId,
    this.nickname,
  });

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'] as int?,
      addressId: map['address_id'] as int?,
      coordinateId: map['coordinate_id'] as int?,
      nickname: map['nickname'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address_is': addressId,
      'coordinate_id': coordinateId,
      'nickname': nickname
    };
  }

  Location copyWith({
    int? id,
    final int? addressId,
    final int? coordinateId,
    final String? nickname,
  }) {
    return Location(
      id: id ?? this.id,
      addressId: addressId ?? this.addressId,
      coordinateId: coordinateId ?? this.coordinateId,
      nickname: nickname ?? this.nickname,
    );
  }

  @override
  String toString() {
    return 'Location(id: $id, addressId: $addressId, coordinateId: $coordinateId, nickname: $nickname)';
  }
}
