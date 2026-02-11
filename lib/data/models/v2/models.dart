// V2 Models - Updated terminology and enhanced models
//
// Key changes from v1:
// - SexualActivityTypeProperty → SexualActivity (resourceType: "SexualActivity")
// - SexualActivityType → SexualActivityCategory (resourceType: "SexualActivityCategory")
// - SexualActivityParticipant → ActivityParticipant
// - PropertyCount → ActivityCount
// - Person enhanced with additional fields (bodyType, gender, health info, etc.)
// - SexualEvent enhanced with notes field
//
// These are conceptually different models from v1, not just renamed.

export 'sexual_activity/sexual_activity.dart';
export 'sexual_activity_category/sexual_activity_category.dart';
export 'activity_count/activity_count.dart';
export 'activity_participant/activity_participant.dart';
export 'address/address.dart';
export 'person/person.dart';
export 'sexual_event/sexual_event.dart';
export 'event_activity/event_activity.dart';
export 'location/location.dart';
export 'name/name.dart';
export 'reference/reference.dart';
