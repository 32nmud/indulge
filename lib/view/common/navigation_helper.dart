import 'package:flutter/material.dart';

// InheritedWidget to provide navigation callback
class NavigationHelper extends InheritedWidget {
  final void Function(String partnerId) navigateToSearchWithPartner;
  final void Function(String eventType) navigateToSearchWithEventType;
  final void Function(String categoryId) navigateToSearchWithCategory;
  final void Function(DateTimeRange range) navigateToSearchWithDateRange;
  final void Function({
    DateTimeRange? dateRange,
    String? eventType,
    String? partnerId,
    String? categoryId,
  })
  navigateToSearch;

  const NavigationHelper({
    super.key,
    required this.navigateToSearchWithPartner,
    required this.navigateToSearchWithEventType,
    required this.navigateToSearchWithCategory,
    required this.navigateToSearchWithDateRange,
    required this.navigateToSearch,
    required super.child,
  });

  static NavigationHelper? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NavigationHelper>();
  }

  @override
  bool updateShouldNotify(NavigationHelper oldWidget) => false;
}
