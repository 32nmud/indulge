import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/dialogs/partner_filter_dialog.dart';
import 'package:indulge/view/common/dialogs/category_filter_dialog.dart';
import 'package:indulge/view/common/dialogs/activity_filter_dialog.dart';
import 'package:indulge/view/common/dialogs/event_type_filter_dialog.dart';
import 'package:indulge/view/search/widgets/search_header.dart';
import 'package:indulge/view/search/widgets/search_results_list.dart';
import 'package:indulge/view/common/util/pagination_controller.dart';
import 'package:indulge/view/search/utils/search_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';

class SearchPage extends StatefulWidget {
  final List<String>? initialPartnerIds;

  const SearchPage({super.key, this.initialPartnerIds});

  @override
  State<SearchPage> createState() => SearchPageState();
}

/// The main search page state. Business logic (filters, searching,
/// pagination) remains here; the visual pieces are delegated to
/// `SearchHeader` and `SearchResultsList` to keep this file organized.
class SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  // Public method to set filters from outside (e.g. navigation)
  void setPartnerFilter(String partnerId) {
    setState(() {
      _selectedPartnerIds = {partnerId};
      _performSearch();
    });
  }

  void setEventTypeFilter(String eventType) {
    setState(() {
      _selectedEventType = eventType;
      _performSearch();
    });
  }

  void setDateRangeFilter(DateTimeRange range) {
    setState(() {
      _dateRange = range;
      _performSearch();
    });
  }

  void applyFilters({
    DateTimeRange? dateRange,
    String? eventType,
    String? partnerId,
    String? categoryId,
    bool sinceLastStiTest = false,
  }) {
    setState(() {
      // Clear all existing filters
      _dateRange = null;
      _selectedPartnerIds.clear();
      _selectedCategoryIds.clear();
      _selectedActivityKeys.clear();
      _selectedEventType = null;
      _notesSearchController.clear();
      _sinceLastStiTest = false;

      if (dateRange != null) _dateRange = dateRange;
      if (eventType != null) _selectedEventType = eventType;
      if (partnerId != null) _selectedPartnerIds = {partnerId};
      if (categoryId != null) _selectedCategoryIds = {categoryId};
      if (sinceLastStiTest) _sinceLastStiTest = true;
      _performSearch();
    });
  }

  List<SexualEvent> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // Pagination (migrated to PaginationController)
  final ScrollController _scrollController = ScrollController();
  final PaginationController<SexualEvent> _pager =
      PaginationController<SexualEvent>(pageSize: 20);

  // Filters
  DateTimeRange? _dateRange;
  Set<String> _selectedPartnerIds = {};
  Set<String> _selectedCategoryIds = {};
  // Selected activities are composite keys: "categoryId:activityId"
  Set<String> _selectedActivityKeys = {};
  String? _selectedEventType;
  final TextEditingController _notesSearchController = TextEditingController();
  bool _sinceLastStiTest = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPartnerIds != null) {
      _selectedPartnerIds.addAll(widget.initialPartnerIds!);
    }

    // Don't auto-search on load - only search when user explicitly triggers it
    // This prevents redundant database queries when switching tabs

    _scrollController.addListener(_onScroll);

    // Listen to centralized EventStateStore changes to refresh search results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventStateStore>().addListener(_onStoreChange);
    });
  }

  @override
  void dispose() {
    context.read<EventStateStore>().removeListener(_onStoreChange);
    _scrollController.dispose();
    _notesSearchController.dispose();
    super.dispose();
  }

  DateTime? _lastSelectedDate;

  void _onStoreChange() {
    if (!mounted) return;

    final store = context.read<EventStateStore>();

    // Skip reload if only selectedDate changed - that's irrelevant for search
    if (_lastSelectedDate != null && store.state.selectedDate != null) {
      if (_lastSelectedDate != store.state.selectedDate) {
        _lastSelectedDate = store.state.selectedDate;
        return;
      }
    }
    _lastSelectedDate = store.state.selectedDate;

    // Only reload if data was explicitly marked dirty
    if (store.needsDataRefresh) {
      Future.microtask(() => _performSearch());
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreResults();
    }
  }

  void _loadMoreResults() {
    // Use PaginationController to determine if more data can be loaded.
    if (!_pager.canLoadMore(_searchResults) || _isSearching) {
      return;
    }

    setState(() {
      _pager.isLoadingMore = true;
    });

    // Simulate async loading for smoother UI (same UX as before)
    // Simulate async loading for smoother UI
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      // Load next page into the pager; we don't need the returned slice here.
      _pager.loadMore(_searchResults);

      setState(() {
        _pager.isLoadingMore = false;
      });
    });
  }

  bool _hasActiveFilters() {
    return _dateRange != null ||
        _sinceLastStiTest ||
        _selectedPartnerIds.isNotEmpty ||
        _selectedCategoryIds.isNotEmpty ||
        _selectedActivityKeys.isNotEmpty ||
        _selectedEventType != null ||
        _notesSearchController.text.isNotEmpty;
  }

  void _clearAllFilters() {
    setState(() {
      _dateRange = null;
      _sinceLastStiTest = false;
      _selectedPartnerIds.clear();
      _selectedCategoryIds.clear();
      _selectedActivityKeys.clear();
      _selectedEventType = null;
      _notesSearchController.clear();
    });
    _performSearch();
  }

  void _toggleSinceLastStiTest(DateTime? lastStiTestDate) {
    setState(() {
      _sinceLastStiTest = !_sinceLastStiTest;
      if (_sinceLastStiTest && lastStiTestDate != null) {
        _dateRange = DateTimeRange(start: lastStiTestDate, end: DateTime.now());
      } else {
        _dateRange = null;
      }
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (!mounted) return;

    // Guard against concurrent searches
    if (_isSearching) {
      return;
    }
    _isSearching = true;

    setState(() {
      _hasSearched = true;
    });

    try {
      final provider = context.read<SexualEventsProvider>();
      final store = context.read<EventStateStore>();

      // Clear dirty flag after loading
      if (store.needsDataRefresh) {
        store.clearDataDirty();
      }

      final allEvents = await provider.getAllEvents();

      _isSearching = false;
      final myId = store.state.myself?.id;

      // Use the pure filter function from search_utils to get filtered & sorted events
      final categoriesMap = store.state.sexualActivityCategories ?? {};

      final filteredEvents = filterSexualEvents(
        allEvents,
        dateRange: _dateRange,
        notesQuery: _notesSearchController.text,
        eventType: _selectedEventType,
        partnerIds: _selectedPartnerIds,
        categoryIds: _selectedCategoryIds,
        categoriesMap: categoriesMap,
        activityKeys: _selectedActivityKeys,
        myselfId: myId,
      );

      setState(() {
        _searchResults = filteredEvents;
        _isSearching = false;

        // Reset pagination controller and load first page
        _pager.reset();
        _pager.loadInitial(_searchResults);
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _performSearch();
      });
    }
  }

  Future<void> _showPartnerFilter() async {
    final provider = context.read<SexualEventsProvider>();
    final store = context.read<EventStateStore>();
    final allPersons = store.state.allPersons ?? await provider.getAllPersons();

    if (!mounted) return;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => PartnerFilterDialog(
        allPersons: allPersons,
        selectedIds: _selectedPartnerIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPartnerIds = result;
        _performSearch();
      });
    }
  }

  Future<void> _showCategoryFilter() async {
    final categoriesMap =
        context.read<EventStateStore>().state.sexualActivityCategories ?? {};

    if (!mounted) return;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => CategoryFilterDialog(
        categoriesMap: categoriesMap,
        selectedIds: _selectedCategoryIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategoryIds = result;
        _performSearch();
      });
    }
  }

  Future<void> _showActivityFilter() async {
    final categoriesMap =
        context.read<EventStateStore>().state.sexualActivityCategories ?? {};

    if (!mounted) return;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => ActivityFilterDialog(
        categoriesMap: categoriesMap,
        selectedKeys: _selectedActivityKeys,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedActivityKeys = result;
        _performSearch();
      });
    }
  }

  Future<void> _showEventTypeFilter() async {
    if (!mounted) return;

    final result = await showDialog<String?>(
      context: context,
      builder: (context) =>
          EventTypeFilterDialog(selectedType: _selectedEventType),
    );

    if (result != null) {
      setState(() {
        _selectedEventType = result;
        _performSearch();
      });
    }
  }

  String _formatDateHeader(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top title + search bar + chips moved into SearchHeader widget.
            SearchHeader(
              notesController: _notesSearchController,
              isSearching: _isSearching,
              hasSearched: _hasSearched,
              searchResultsCount: _searchResults.length,
              hasActiveFilters: _hasActiveFilters(),
              dateRange: _dateRange,
              sinceLastStiTest: _sinceLastStiTest,
              selectedPartnerIds: _selectedPartnerIds,
              selectedCategoryIds: _selectedCategoryIds,
              selectedActivityKeys: _selectedActivityKeys,
              selectedEventType: _selectedEventType,
              onSubmitSearch: _performSearch,
              onClearSearch: () {
                _notesSearchController.clear();
                _performSearch();
              },
              onDateRangeTap: _showDateRangePicker,
              onToggleSinceLastStiTest: () async {
                final last = await context
                    .read<ClinicalEventsProvider>()
                    .getLastClinicalEventDate();
                _toggleSinceLastStiTest(last);
              },
              onPartnerTap: _showPartnerFilter,
              onEventTypeTap: _showEventTypeFilter,
              onCategoryTap: _showCategoryFilter,
              onActivityTap: _showActivityFilter,
              onClearAll: _clearAllFilters,
            ),

            // Results list is delegated to SearchResultsList
            Expanded(
              child: SearchResultsList(
                isSearching: _isSearching,
                hasSearched: _hasSearched,
                searchResults: _searchResults,
                displayedResults: _pager.displayed,
                isLoadingMore: _pager.isLoadingMore,
                scrollController: _scrollController,
                formatDateHeader: _formatDateHeader,
                onClearAll: _clearAllFilters,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
