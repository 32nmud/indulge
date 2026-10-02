import 'package:flutter/material.dart';
import 'package:indulge/view/search/widgets/filter_chips.dart';

/// SearchHeader widget extracted from SearchPage.
/// Presentation-only: receives controller, state and callbacks from parent.
class SearchHeader extends StatefulWidget {
  final TextEditingController notesController;
  final bool isSearching;
  final bool hasSearched;
  final int searchResultsCount;
  final bool hasActiveFilters;

  final DateTimeRange? dateRange;
  final bool sinceLastStiTest;
  final Set<String> selectedPartnerIds;
  final Set<String> selectedCategoryIds;
  final Set<String> selectedActivityKeys;
  final String? selectedEventType;

  final VoidCallback onSubmitSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onDateRangeTap;
  final VoidCallback onToggleSinceLastStiTest;
  final VoidCallback onPartnerTap;
  final VoidCallback onEventTypeTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onActivityTap;
  final VoidCallback onClearAll;

  const SearchHeader({
    super.key,
    required this.notesController,
    required this.isSearching,
    required this.hasSearched,
    required this.searchResultsCount,
    required this.hasActiveFilters,
    required this.dateRange,
    required this.sinceLastStiTest,
    required this.selectedPartnerIds,
    required this.selectedCategoryIds,
    required this.selectedActivityKeys,
    required this.selectedEventType,
    required this.onSubmitSearch,
    required this.onClearSearch,
    required this.onDateRangeTap,
    required this.onToggleSinceLastStiTest,
    required this.onPartnerTap,
    required this.onEventTypeTap,
    required this.onCategoryTap,
    required this.onActivityTap,
    required this.onClearAll,
  });

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.notesController;
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SearchHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notesController != widget.notesController) {
      oldWidget.notesController.removeListener(_onControllerChanged);
      _controller.removeListener(_onControllerChanged);
      _controller = widget.notesController;
      _controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Search',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Text Search Bar
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: widget.onClearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => widget.onSubmitSearch(),
                ),
                const SizedBox(height: 12),

                // Results count
                if (widget.hasSearched && !widget.isSearching)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      widget.hasActiveFilters
                          ? '${widget.searchResultsCount} ${widget.searchResultsCount == 1 ? 'result' : 'results'} found'
                          : '${widget.searchResultsCount} total ${widget.searchResultsCount == 1 ? 'event' : 'events'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                // Filter chips
                SizedBox(
                  width: double.infinity,
                  child: SearchFilterChips(
                    dateRange: widget.dateRange,
                    sinceLastStiTest: widget.sinceLastStiTest,
                    selectedPartnerIds: widget.selectedPartnerIds,
                    selectedCategoryIds: widget.selectedCategoryIds,
                    selectedActivityKeys: widget.selectedActivityKeys,
                    selectedEventType: widget.selectedEventType,
                    hasActiveFilters: widget.hasActiveFilters,
                    onDateRangeTap: widget.onDateRangeTap,
                    onToggleSinceLastStiTest: widget.onToggleSinceLastStiTest,
                    onPartnerTap: widget.onPartnerTap,
                    onEventTypeTap: widget.onEventTypeTap,
                    onCategoryTap: widget.onCategoryTap,
                    onActivityTap: widget.onActivityTap,
                    onClearAll: widget.onClearAll,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
