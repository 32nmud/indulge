import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';

/// Callback when the role picker is requested.
typedef OnShowRolePicker =
    Future<void> Function(
      BuildContext context,
      String activityName,
      String personId,
      ActivityRole currentRole, {
      String? categoryId,
    });

/// Callback when a participant's property is toggled.
typedef OnToggleProperty =
    void Function(String activityName, String personId, {String? categoryId});

/// Callback when a property count is incremented.
typedef OnIncrementCount =
    void Function(String activityName, String personId, {String? categoryId});

/// Callback when a property count is decremented.
typedef OnDecrementCount =
    void Function(String activityName, String personId, {String? categoryId});

/// Callback when a participant is removed.
typedef OnRemoveParticipant = void Function(int participantIndex);

/// Callback when solo toggle is changed.
typedef OnToggleSolo =
    void Function(String activityName, String personId, {String? categoryId});
