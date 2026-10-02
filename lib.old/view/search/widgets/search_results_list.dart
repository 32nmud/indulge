import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/sexual_event_card/sexual_event_card.dart';

/// A reusable widget that renders the search results area for the Search page.
///
/// Responsibilities:
/// - Show initial empty/search-prompt state when the user hasn't searched yet.
/// - Show a loading indicator while searching (if no results yet).
/// - Show a "no results" state when a search completed with zero matches.
/// - Render a paginated list of `displayedResults` and an optional loading
///   indicator at the end when more results are being loaded.
///
/// The widget is presentation-only; the parent is responsible for managing the
/// search/filter state, pagination and scroll controller.
class SearchResultsList extends StatelessWidget {
  final bool isSearching;
  final bool hasSearched;
  final List<SexualEvent> searchResults;
  final List<SexualEvent> displayedResults;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final String Function(DateTime) formatDateHeader;
  final VoidCallback onClearAll;

  const SearchResultsList({
    super.key,
    required this.isSearching,
    required this.hasSearched,
    required this.searchResults,
    required this.displayedResults,
    required this.isLoadingMore,
    required this.scrollController,
    required this.formatDateHeader,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    // Loading overlay when a search is in progress and we don't yet have results.
    if (isSearching && searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Prompt shown before the user has initiated any search.
    if (!hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search your history',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use filters to find specific events',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // When a search has completed but no results were found.
    if (searchResults.isEmpty) {
      return _buildNoResultsState(context);
    }

    // Otherwise render the paginated list of results.
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB / UI chrome
      itemCount: displayedResults.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at the end while more results are fetched.
        if (index >= displayedResults.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final event = displayedResults[index];

        final showDateHeader =
            index == 0 ||
            !DateUtils.isSameDay(event.date, displayedResults[index - 1].date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  formatDateHeader(event.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SexualEventCard(event: event),
          ],
        );
      },
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onClearAll,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }
}
