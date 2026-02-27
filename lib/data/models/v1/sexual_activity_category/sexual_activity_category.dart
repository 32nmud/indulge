import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:indulge/data/models/versioned_model.dart';
import '../reference/reference.dart';
import '../sexual_activity/sexual_activity.dart';
import 'package:uuid/uuid.dart';

part 'sexual_activity_category.freezed.dart';
part 'sexual_activity_category.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class SexualActivityCategory
    with _$SexualActivityCategory
    implements VersionedModel {
  const SexualActivityCategory._();

  const factory SexualActivityCategory({
    @Default("") String id,
    DateTime? lastUpdateDate,
    required String name,
    String? displayCharacter,
    @Default(-1) int minParticipants,
    @Default(-1) int maxParticipants,
    @Default([]) List<SexualActivity> activities,
    @Default(false) bool requiresPartner,
    @Default(0) int sortOrder,
    @Default([]) List<Reference> subCategories,
  }) = _SexualActivityCategory;

  // -----------------------------------------------------------------
  // Custom JSON (de)serialization
  // -----------------------------------------------------------------
  factory SexualActivityCategory.fromJson(Map<String, dynamic> json) {
    // Remove any incoming `resourceType` – we ignore it completely.
    final cleaned = Map<String, dynamic>.from(json)..remove('resourceType');
    return _$SexualActivityCategoryFromJson(cleaned);
  }

  @override
  Map<String, dynamic> toJson() {
    // Let the generated helper create the map, then inject the constant.
    final map = _$SexualActivityCategoryToJson(this as _SexualActivityCategory);
    map['resourceType'] = "SexualActivityCategory";
    return map;
  }

  // -----------------------------------------------------------------
  // Fixed getters
  // -----------------------------------------------------------------
  @JsonKey(name: 'resourceType')
  @override
  String get resourceType => "SexualActivityCategory";

  @override
  int get version => 1;

  @override
  String get id => (this as _SexualActivityCategory).id == ""
      ? const Uuid().v4()
      : (this as _SexualActivityCategory).id;
}
