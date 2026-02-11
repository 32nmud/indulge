import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/event_card/event_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/common/person_avatar.dart';

class SearchPage extends StatefulWidget {
  final List<String>? initialPartnerIds;

  const SearchPage({super.key, this.initialPartnerIds});

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  // Public method to set filters from outside (e.g. navigation)
  void setPartnerFilter(String partnerId) {
    setState(() {
      _selectedPartnerIds = {partnerId};
      _performSearch();
    });
  }

  List<SexualEvent> _searchResults = [];
  List<SexualEvent> _displayedResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isLoadingMore = false;

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();

  // Filters
  DateTimeRange? _dateRange;
  Set<String> _selectedPartnerIds = {};
  Set<String> _selectedCategoryIds = {};
  // Selected activities are now composite keys: "categoryId:activityId"
  Set<String> _selectedActivityKeys = {};
  final TextEditingController _notesSearchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPartnerIds != null) {
      _selectedPartnerIds.addAll(widget.initialPartnerIds!);
    }

    // Auto-search on load to show all events initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });

    _scrollController.addListener(_onScroll);

    // Listen to provider changes to refresh search results if data changes
    // (e.g. event edited/deleted)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SexualEventsProvider>().addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    context.read<SexualEventsProvider>().removeListener(_onProviderChange);
    _scrollController.dispose();
    _notesSearchController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (mounted) {
      // Schedule the search to ensure it doesn't conflict with current build/notify cycle
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
    if (_isLoadingMore ||
        _displayedResults.length >= _searchResults.length ||
        _isSearching) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate async loading for smoother UI
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      final nextEnd = (_currentPage + 1) * _pageSize;
      final end = nextEnd < _searchResults.length
          ? nextEnd
          : _searchResults.length;

      setState(() {
        _displayedResults.addAll(
          _searchResults.sublist(_displayedResults.length, end),
        );
        _currentPage++;
        _isLoadingMore = false;
      });
    });
  }

  bool _hasActiveFilters() {
    return _dateRange != null ||
        _selectedPartnerIds.isNotEmpty ||
        _selectedCategoryIds.isNotEmpty ||
        _selectedActivityKeys.isNotEmpty ||
        _notesSearchController.text.isNotEmpty;
  }

  void _clearAllFilters() {
    setState(() {
      _dateRange = null;
      _selectedPartnerIds.clear();
      _selectedCategoryIds.clear();
      _selectedActivityKeys.clear();
      _notesSearchController.clear();
    });
    _performSearch();
  }

  void _resetPagination() {
    _currentPage = 0;
    _displayedResults.clear();
  }

  Future<void> _performSearch() async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final provider = context.read<SexualEventsProvider>();
      final allEvents = await provider.getAllEvents();

      final filteredEvents = allEvents.where((event) {
        // Date range filter
        if (_dateRange != null) {
          if (event.date.isBefore(_dateRange!.start) ||
              event.date.isAfter(
                _dateRange!.end.add(const Duration(days: 1)),
              )) {
            return false;
          }
        }

        // Notes filter
        if (_notesSearchController.text.isNotEmpty) {
          final query = _notesSearchController.text.toLowerCase();
          final notes = event.notes?.toLowerCase() ?? '';
          if (!notes.contains(query)) {
            return false;
          }
        }

        // Partner filter
        if (_selectedPartnerIds.isNotEmpty) {
          final eventPartnerIds = event.activities
              .expand((a) => a.participants)
              .map((p) => p.participant.reference)
              .toSet();
          if (!_selectedPartnerIds.any((id) => eventPartnerIds.contains(id))) {
            return false;
          }
        }

        // Activity category filter
        if (_selectedCategoryIds.isNotEmpty) {
          final eventCategoryIds = event.activities
              .map((a) => a.category.reference)
              .toSet();
          if (!_selectedCategoryIds.any(
            (id) => eventCategoryIds.contains(id),
          )) {
            return false;
          }
        }

        // Activity filter (Composite key: categoryId:activityId)
        if (_selectedActivityKeys.isNotEmpty) {
          bool hasMatchingActivity = false;
          for (var eventActivity in event.activities) {
            final categoryId = eventActivity.category.reference;
            for (var participant in eventActivity.participants) {
              for (var activityCount in participant.activityCounts) {
                final activityId = activityCount.activityReference.reference;
                final compositeKey = "$categoryId:$activityId";
                if (_selectedActivityKeys.contains(compositeKey)) {
                  hasMatchingActivity = true;
                  break;
                }
              }
              if (hasMatchingActivity) break;
            }
            if (hasMatchingActivity) break;
          }
          if (!hasMatchingActivity) return false;
        }

        return true;
      }).toList();

      // Sort by date (most recent first)
      filteredEvents.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _searchResults = filteredEvents;
        _isSearching = false;

        // Reset pagination and load first page
        _resetPagination();
        final firstPageEnd = _pageSize < filteredEvents.length
            ? _pageSize
            : filteredEvents.length;
        if (firstPageEnd > 0) {
          _displayedResults = filteredEvents.sublist(0, firstPageEnd);
          _currentPage = 1;
        }
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
    final allPersons = await provider.getAllPersons();
    // Filter out anonymous and "me"
    final filterablePersons = allPersons
        .where((p) => p.id != 'anonymous' && !p.isSelf)
        .toList();

    if (!mounted) return;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _PartnerFilterDialog(
        allPersons: filterablePersons,
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
    final provider = context.read<SexualEventsProvider>();
    final categories =
        provider.state.sexualActivityCategories?.values.toList() ?? [];

    if (!mounted) return;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _CategoryFilterDialog(
        categories: categories,
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
    final provider = context.read<SexualEventsProvider>();
    final categories =
        provider.state.sexualActivityCategories?.values.toList() ?? [];
    final activities = provider.state.sexualActivities ?? {};

    if (!mounted) return;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _ActivityFilterDialog(
        categories: categories,
        activitiesMap: activities,
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Search',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            // Search header
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
                    controller: _notesSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _notesSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _notesSearchController.clear();
                                _performSearch();
                              },
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 12),
                  // Results count
                  if (_hasSearched && !_isSearching)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _hasActiveFilters()
                            ? '${_searchResults.length} ${_searchResults.length == 1 ? 'result' : 'results'} found'
                            : '${_searchResults.length} total ${_searchResults.length == 1 ? 'event' : 'events'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Date range chip
                        FilterChip(
                          label: Text(
                            _dateRange == null
                                ? 'Date Range'
                                : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                          ),
                          selected: _dateRange != null,
                          onSelected: (selected) => _showDateRangePicker(),
                          avatar: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: _dateRange != null ? Colors.blue : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Partners chip
                        FilterChip(
                          label: Text(
                            _selectedPartnerIds.isEmpty
                                ? 'Partners'
                                : 'Partners (${_selectedPartnerIds.length})',
                          ),
                          selected: _selectedPartnerIds.isNotEmpty,
                          onSelected: (selected) => _showPartnerFilter(),
                          avatar: Icon(
                            Icons.people,
                            size: 16,
                            color: _selectedPartnerIds.isNotEmpty
                                ? Colors.blue
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Activity categories chip
                        FilterChip(
                          label: Text(
                            _selectedCategoryIds.isEmpty
                                ? 'Categories'
                                : 'Categories (${_selectedCategoryIds.length})',
                          ),
                          selected: _selectedCategoryIds.isNotEmpty,
                          onSelected: (selected) => _showCategoryFilter(),
                          avatar: Icon(
                            Icons.category,
                            size: 16,
                            color: _selectedCategoryIds.isNotEmpty
                                ? Colors.blue
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Activities chip (grouped)
                        FilterChip(
                          label: Text(
                            _selectedActivityKeys.isEmpty
                                ? 'Activities'
                                : 'Activities (${_selectedActivityKeys.length})',
                          ),
                          selected: _selectedActivityKeys.isNotEmpty,
                          onSelected: (selected) => _showActivityFilter(),
                          avatar: Icon(
                            Icons.label,
                            size: 16,
                            color: _selectedActivityKeys.isNotEmpty
                                ? Colors.blue
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Clear filters button
                        if (_hasActiveFilters())
                          ActionChip(
                            label: const Text('Clear All'),
                            onPressed: _clearAllFilters,
                            avatar: const Icon(Icons.clear_all, size: 16),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Results
            Expanded(child: _buildResultsView()),
          ],
        ),
      ),
      floatingActionButton: _hasActiveFilters()
          ? FloatingActionButton(
              onPressed: _performSearch,
              child: const Icon(Icons.search),
            )
          : null,
    );
  }

  Widget _buildResultsView() {
    if (_isSearching && _searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
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

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: _displayedResults.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _displayedResults.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final event = _displayedResults[index];
        final showDateHeader =
            index == 0 ||
            !DateUtils.isSameDay(event.date, _displayedResults[index - 1].date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  _formatDateHeader(event.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            EventCard(event: event),
          ],
        );
      },
    );
  }

  Widget _buildNoResultsState() {
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
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }
}

class _PartnerFilterDialog extends StatefulWidget {
  final List<Person> allPersons;
  final Set<String> selectedIds;

  const _PartnerFilterDialog({
    required this.allPersons,
    required this.selectedIds,
  });

  @override
  State<_PartnerFilterDialog> createState() => _PartnerFilterDialogState();
}

class _PartnerFilterDialogState extends State<_PartnerFilterDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Partners'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.allPersons.map((person) {
            final isSelected = _selectedIds.contains(person.id);
            return CheckboxListTile(
              title: Row(
                children: [
                  PersonAvatar(person: person, radius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      person.name.nickname ?? person.name.given ?? 'Unknown',
                    ),
                  ),
                ],
              ),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(person.id);
                  } else {
                    _selectedIds.remove(person.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedIds.clear();
            });
          },
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _CategoryFilterDialog extends StatefulWidget {
  final List<SexualActivityCategory> categories;
  final Set<String> selectedIds;

  const _CategoryFilterDialog({
    required this.categories,
    required this.selectedIds,
  });

  @override
  State<_CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<_CategoryFilterDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Categories'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.categories.map((category) {
            final isSelected = _selectedIds.contains(category.id);
            return CheckboxListTile(
              title: Row(
                children: [
                  Text(
                    category.displayCharacter ?? '❔',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(category.id);
                  } else {
                    _selectedIds.remove(category.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedIds.clear();
            });
          },
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ActivityFilterDialog extends StatefulWidget {
  final List<SexualActivityCategory> categories;
  final Map<String, SexualActivity> activitiesMap;
  final Set<String> selectedKeys; // format: "categoryId:activityId"

  const _ActivityFilterDialog({
    required this.categories,
    required this.activitiesMap,
    required this.selectedKeys,
  });

  @override
  State<_ActivityFilterDialog> createState() => _ActivityFilterDialogState();
}

class _ActivityFilterDialogState extends State<_ActivityFilterDialog> {
  late Set<String> _selectedKeys;
  // Keep track of expanded categories
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _selectedKeys = Set.from(widget.selectedKeys);
    // Auto-expand categories that have selected items
    for (var key in _selectedKeys) {
      final parts = key.split(':');
      if (parts.isNotEmpty) {
        _expandedCategories.add(parts[0]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Specific Activities'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.categories.map((category) {
            final categoryId = category.id;
            // Get activities for this category
            final activities = category.activities
                .map((ref) => widget.activitiesMap[ref.reference])
                .whereType<SexualActivity>()
                .toList();

            if (activities.isEmpty) return const SizedBox.shrink();

            final isExpanded = _expandedCategories.contains(categoryId);

            // Check how many items selected in this category
            final selectedCount = activities.where((a) {
              return _selectedKeys.contains("$categoryId:${a.id}");
            }).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: selectedCount > 0
                      ? Text(
                          '$selectedCount selected',
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  leading: Text(
                    category.displayCharacter ?? '❔',
                    style: const TextStyle(fontSize: 24),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedCategories.remove(categoryId);
                      } else {
                        _expandedCategories.add(categoryId);
                      }
                    });
                  },
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      children: activities.map((activity) {
                        final compositeKey = "$categoryId:${activity.id}";
                        final isSelected = _selectedKeys.contains(compositeKey);

                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Text(
                                activity.displayCharacter,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(activity.name)),
                              if (activity.isRisky) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.warning,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                              ],
                            ],
                          ),
                          value: isSelected,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedKeys.add(compositeKey);
                              } else {
                                _selectedKeys.remove(compositeKey);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(),
              ],
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedKeys.clear();
            });
          },
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedKeys),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
