import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';

/// A composable widget that renders the collection of filter chips used by
/// the Search page.
///
/// This widget intentionally does not own any business logic; it receives the
/// current filter state and callbacks from its parent (`SearchPageState`).
/// Keeping it dumb makes the Search page easier to test and the UI easier to
/// refactor in the future.
class SearchFilterChips extends StatelessWidget {
  final DateTimeRange? dateRange;
  final bool sinceLastStiTest;
  final Set<String> selectedPartnerIds;
  final Set<String> selectedCategoryIds;
  final Set<String> selectedActivityKeys;
  final String? selectedEventType;
  final bool hasActiveFilters;

  // Callbacks invoked when the corresponding chip is tapped.
  final VoidCallback onDateRangeTap;
  final VoidCallback onToggleSinceLastStiTest;
  final VoidCallback onPartnerTap;
  final VoidCallback onEventTypeTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onActivityTap;
  final VoidCallback onClearAll;

  const SearchFilterChips({
    super.key,
    required this.dateRange,
    required this.sinceLastStiTest,
    required this.selectedPartnerIds,
    required this.selectedCategoryIds,
    required this.selectedActivityKeys,
    required this.selectedEventType,
    required this.hasActiveFilters,
    required this.onDateRangeTap,
    required this.onToggleSinceLastStiTest,
    required this.onPartnerTap,
    required this.onEventTypeTap,
    required this.onCategoryTap,
    required this.onActivityTap,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          // Date range chip
          FilterChip(
            label: Text(
              dateRange == null
                  ? 'Date Range'
                  : '${dateRange!.start.month}/${dateRange!.start.day}/${dateRange!.start.year} - ${dateRange!.end.month}/${dateRange!.end.day}/${dateRange!.end.year}',
            ),
            selected: dateRange != null,
            onSelected: (_) => onDateRangeTap(),
            avatar: Icon(
              Icons.calendar_today,
              size: 16,
              color: dateRange != null ? Colors.blue : null,
            ),
          ),

          // Since Last STI Test chip (depends on clinical provider for last test date)
          FutureBuilder<DateTime?>(
            future: context
                .read<ClinicalEventsProvider>()
                .getLastClinicalEventDate(),
            builder: (context, snapshot) {
              return FilterChip(
                label: Text('Since Last STI Test'),
                selected: sinceLastStiTest,
                onSelected: (_) => onToggleSinceLastStiTest(),
                avatar: Icon(
                  Icons.medical_services,
                  size: 16,
                  color: sinceLastStiTest ? Colors.red : null,
                ),
              );
            },
          ),

          // Partners chip
          FilterChip(
            label: Text(
              selectedPartnerIds.isEmpty
                  ? 'Partners'
                  : 'Partners (${selectedPartnerIds.length})',
            ),
            selected: selectedPartnerIds.isNotEmpty,
            onSelected: (_) => onPartnerTap(),
            avatar: Icon(
              Icons.people,
              size: 16,
              color: selectedPartnerIds.isNotEmpty ? Colors.blue : null,
            ),
          ),

          // Event Type chip
          FilterChip(
            label: Text(selectedEventType ?? 'Type'),
            selected: selectedEventType != null,
            onSelected: (_) => onEventTypeTap(),
            avatar: Icon(
              Icons.group_work,
              size: 16,
              color: selectedEventType != null ? Colors.blue : null,
            ),
          ),

          // Activity categories chip
          FilterChip(
            label: Text(
              selectedCategoryIds.isEmpty
                  ? 'Categories'
                  : 'Categories (${selectedCategoryIds.length})',
            ),
            selected: selectedCategoryIds.isNotEmpty,
            onSelected: (_) => onCategoryTap(),
            avatar: Icon(
              Icons.category,
              size: 16,
              color: selectedCategoryIds.isNotEmpty ? Colors.blue : null,
            ),
          ),

          // Activities chip (grouped)
          FilterChip(
            label: Text(
              selectedActivityKeys.isEmpty
                  ? 'Activities'
                  : 'Activities (${selectedActivityKeys.length})',
            ),
            selected: selectedActivityKeys.isNotEmpty,
            onSelected: (_) => onActivityTap(),
            avatar: Icon(
              Icons.label,
              size: 16,
              color: selectedActivityKeys.isNotEmpty ? Colors.blue : null,
            ),
          ),

          // Clear filters action
          if (hasActiveFilters)
            ActionChip(
              label: const Text('Clear All'),
              onPressed: onClearAll,
              avatar: const Icon(Icons.clear_all, size: 16),
            ),
        ],
      ),
    );
  }
}
