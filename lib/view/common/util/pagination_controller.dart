import 'dart:math';

/// A simple, reusable pagination controller for lists.
///
/// Responsibilities:
/// - Keep track of the currently visible (paginated) items in `displayed`.
/// - Manage `currentPage` and `isLoadingMore` state.
/// - Provide helpers to reset and to load the initial page and subsequent pages.
///
/// Important:
/// - This controller is intentionally synchronous and operates on an in-memory
///   list of all items provided by the caller. It does not perform I/O.
/// - The caller is responsible for calling `loadInitial` with the full result
///   set after a new search and calling `loadMore` when additional pages are
///   needed (for example when the user scrolls near the end).
class PaginationController<T> {
  PaginationController({this.pageSize = 20});

  /// Number of items per page.
  final int pageSize;

  /// 0-based page index. Remains 0 before any page is loaded. After
  /// `loadInitial` has run it will be 1, after a single `loadMore` it'll be 2, etc.
  int currentPage = 0;

  /// Items currently visible to the UI.
  final List<T> displayed = <T>[];

  /// True while a load-more operation is in progress.
  bool isLoadingMore = false;

  /// Whether more items can be loaded from the provided [allItems].
  bool canLoadMore(List<T> allItems) {
    return !isLoadingMore && displayed.length < allItems.length;
  }

  /// Resets pagination state. Call before starting a new search.
  void reset() {
    currentPage = 0;
    isLoadingMore = false;
    displayed.clear();
  }

  /// Loads the initial page from [allItems].
  ///
  /// Returns the list of items that were added to `displayed`.
  List<T> loadInitial(List<T> allItems) {
    reset();
    final end = min(pageSize, allItems.length);
    if (end > 0) {
      displayed.addAll(allItems.sublist(0, end));
      currentPage = 1;
    }
    return List<T>.from(displayed);
  }

  /// Loads the next page from [allItems]. If there are no more items this is a
  /// no-op and an empty list is returned.
  ///
  /// Returns the newly added items (may be empty).
  List<T> loadMore(List<T> allItems) {
    if (!canLoadMore(allItems)) return <T>[];

    isLoadingMore = true;
    try {
      final nextEnd = (currentPage + 1) * pageSize;
      final end = min(nextEnd, allItems.length);
      if (end > displayed.length) {
        final newItems = allItems.sublist(displayed.length, end);
        displayed.addAll(newItems);
        currentPage++;
        return List<T>.from(newItems);
      }
      return <T>[];
    } finally {
      isLoadingMore = false;
    }
  }

  /// Convenience getter for the total count currently displayed.
  int get displayedCount => displayed.length;
}
