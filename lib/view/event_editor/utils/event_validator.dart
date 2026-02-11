import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

class EventValidator {
  static bool validateEvent({
    required BuildContext context,
    required SexualEvent event,
    required Map<String, SexualActivityCategory> availableActivityCategories,
    required Person? myself,
  }) {
    // Must have at least one activity
    if (event.activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one activity'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // Each activity must have at least one participant (can be "Me" or others)
    for (var i = 0; i < event.activities.length; i++) {
      final activity = event.activities[i];
      final activityCategory =
          availableActivityCategories[activity.category.reference];

      // Check if activity requires a partner
      if (activityCategory?.requiresPartner == true) {
        // For activities requiring a partner, must have at least one non-self participant
        final nonSelfCount = activity.participants.where((p) {
          return myself == null || p.participant.reference != myself.id;
        }).length;

        if (nonSelfCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Category "${activityCategory?.name ?? 'Unknown'}" requires at least one partner',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
      } else {
        // For solo-capable activities, must have at least one participant (including "Me")
        if (activity.participants.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Category "${activityCategory?.name ?? 'Unknown'}" must have at least one participant (you or someone else)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
      }
    }

    return true;
  }
}
