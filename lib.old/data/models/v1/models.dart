// V1 Models - Canonical models after legacy cleanup
//
// Key changes from legacy:
// - SexualActivityTypeProperty → SexualActivity (resourceType: "SexualActivity")
// - SexualActivityType → SexualActivityCategory (resourceType: "SexualActivityCategory")
// - SexualActivityParticipant → ActivityParticipant
// - PropertyCount → ActivityCount
// - Person enhanced with additional fields (bodyType, gender, health info, etc.)
// - SexualEvent enhanced with notes field
// - Added: isActionable and sortOrder to SexualActivity
// - Added: sortOrder and subcategories to SexualActivityCategory

export 'sexual_activity/sexual_activity.dart';
export 'sexual_activity_category/sexual_activity_category.dart';
export 'activity_count/activity_count.dart';
export 'activity_participant/activity_participant.dart';
export 'address/address.dart';
export 'person/person.dart';
export 'sexual_event/sexual_event.dart';
export 'clinical_event/clinical_event.dart';
export 'clinical_test_result/clinical_test_result.dart';
export 'event_activity/event_activity.dart';
export 'location/location.dart';
export 'name/name.dart';
export 'reference/reference.dart';
