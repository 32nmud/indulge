import 'package:flutter/material.dart';
import '../models/analysis_data.dart';

class AnalysisColors {
  static const Color solo = Colors.blue;
  static const Color couple = Colors.purple;
  static const Color group = Colors.orange;
  static const Color total = Colors.blueGrey;

  static Color getColor(AnalysisEventType? type, {BuildContext? context}) {
    switch (type) {
      case AnalysisEventType.solo:
        return solo;
      case AnalysisEventType.couple:
        return couple;
      case AnalysisEventType.group:
        return group;
      case AnalysisEventType.total:
      case null:
        // Use theme primary color for total/default if context is provided, else fallback
        if (context != null) {
          return Theme.of(context).colorScheme.primary;
        }
        return total;
    }
  }
}
