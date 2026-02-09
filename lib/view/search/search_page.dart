import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/view/common/event_card/event_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  List<SexualEvent> _searchResults = [];
  List<SexualEvent> _displayedResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isLoadingMore = false;

  // Pagination
  static const int _pageSize = 10;
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();

  // Filter state
  DateTimeRange? _dateRange;
  Set<String> _selectedPartnerIds = {};
  Set<String> _selectedActivityTypeIds = {};
  Set<String> _selectedPropertyIds = {};
  bool? _riskyOnly;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Listen to provider changes to reload search results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SexualEventsProvider>().addListener(_onProviderChange);
      // Load all events initially when no filters are set
      _performSearch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    context.read<SexualEventsProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    // Re-run search (which always runs now to show all events by default)
    _performSearch();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Trigger load when within 200px of bottom

    if (currentScroll >= maxScroll - delta) {
      _loadMoreResults();
    }
  }

  void _loadMoreResults() {
    if (_isLoadingMore) return;

    final startIndex = _currentPage * _pageSize;
    if (startIndex >= _searchResults.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate async loading (could add a small delay if desired)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final endIndex = ((startIndex + _pageSize) < _searchResults.length)
          ? (startIndex + _pageSize)
          : _searchResults.length;

      setState(() {
        _displayedResults.addAll(_searchResults.sublist(startIndex, endIndex));
        _currentPage++;
        _isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      body: Column(
        children: [
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
                      // Activity types chip
                      FilterChip(
                        label: Text(
                          _selectedActivityTypeIds.isEmpty
                              ? 'Activities'
                              : 'Activities (${_selectedActivityTypeIds.length})',
                        ),
                        selected: _selectedActivityTypeIds.isNotEmpty,
                        onSelected: (selected) => _showActivityTypeFilter(),
                        avatar: Icon(
                          Icons.category,
                          size: 16,
                          color: _selectedActivityTypeIds.isNotEmpty
                              ? Colors.blue
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Properties chip
                      FilterChip(
                        label: Text(
                          _selectedPropertyIds.isEmpty
                              ? 'Properties'
                              : 'Properties (${_selectedPropertyIds.length})',
                        ),
                        selected: _selectedPropertyIds.isNotEmpty,
                        onSelected: (selected) => _showPropertyFilter(),
                        avatar: Icon(
                          Icons.label,
                          size: 16,
                          color: _selectedPropertyIds.isNotEmpty
                              ? Colors.blue
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Risky filter chip
                      FilterChip(
                        label: const Text('Risky Only'),
                        selected: _riskyOnly == true,
                        onSelected: (selected) {
                          setState(() {
                            _riskyOnly = selected ? true : null;
                            _performSearch();
                          });
                        },
                        avatar: Icon(
                          Icons.warning,
                          size: 16,
                          color: _riskyOnly == true ? Colors.orange : null,
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
      floatingActionButton: _hasActiveFilters()
          ? FloatingActionButton(
              heroTag: 'search_perform_fab',
              onPressed: _performSearch,
              child: const Icon(Icons.search),
            )
          : null,
    );
  }

  Widget _buildResultsView() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    // Group displayed events by date
    final groupedEvents = <DateTime, List<SexualEvent>>{};
    for (var event in _displayedResults) {
      final dateOnly = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      groupedEvents.putIfAbsent(dateOnly, () => []).add(event);
    }

    final sortedDates = groupedEvents.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    // Calculate total item count (dates + events + loading indicator)
    int itemCount = 0;
    for (var date in sortedDates) {
      itemCount++; // Date header
      itemCount += groupedEvents[date]!.length; // Events
    }

    // Add 1 for loading indicator if there are more results
    final hasMore = _displayedResults.length < _searchResults.length;
    if (hasMore) {
      itemCount++;
    }

    return RefreshIndicator(
      onRefresh: _performSearch,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          int currentIndex = 0;

          for (var dateIndex = 0; dateIndex < sortedDates.length; dateIndex++) {
            final date = sortedDates[dateIndex];
            final events = groupedEvents[date]!;

            // Check if this is the date header
            if (currentIndex == index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: dateIndex == 0 ? 0 : 16,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      _formatDateHeader(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${events.length} ${events.length == 1 ? 'event' : 'events'})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            currentIndex++;

            // Check if this is one of the events
            for (var eventIndex = 0; eventIndex < events.length; eventIndex++) {
              if (currentIndex == index) {
                return EventCard(event: events[eventIndex]);
              }
              currentIndex++;
            }
          }

          // Loading indicator at the end
          if (hasMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _dateRange != null ||
        _selectedPartnerIds.isNotEmpty ||
        _selectedActivityTypeIds.isNotEmpty ||
        _selectedPropertyIds.isNotEmpty ||
        _riskyOnly != null;
  }

  void _clearAllFilters() {
    setState(() {
      _dateRange = null;
      _selectedPartnerIds.clear();
      _selectedActivityTypeIds.clear();
      _selectedPropertyIds.clear();
      _riskyOnly = null;
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

      // For now, get all events and filter in memory
      // TODO: Move filtering to repository for better performance
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

        // Activity type filter
        if (_selectedActivityTypeIds.isNotEmpty) {
          final eventActivityTypeIds = event.activities
              .map((a) => a.type.reference)
              .toSet();
          if (!_selectedActivityTypeIds.any(
            (id) => eventActivityTypeIds.contains(id),
          )) {
            return false;
          }
        }

        // Property filter
        if (_selectedPropertyIds.isNotEmpty) {
          bool hasMatchingProperty = false;
          for (var activity in event.activities) {
            for (var participant in activity.participants) {
              for (var propCount in participant.propertyCounts) {
                if (_selectedPropertyIds.contains(
                  propCount.propertyReference.reference,
                )) {
                  hasMatchingProperty = true;
                  break;
                }
              }
              if (hasMatchingProperty) break;
            }
            if (hasMatchingProperty) break;
          }
          if (!hasMatchingProperty) return false;
        }

        // Risky filter
        if (_riskyOnly == true) {
          bool hasRiskyActivity = false;
          for (var activity in event.activities) {
            for (var participant in activity.participants) {
              for (var propCount in participant.propertyCounts) {
                final property =
                    provider.state.sexualActivityTypeProperties?[propCount
                        .propertyReference
                        .reference];
                if (property?.isRisky == true) {
                  hasRiskyActivity = true;
                  break;
                }
              }
              if (hasRiskyActivity) break;
            }
            if (hasRiskyActivity) break;
          }
          if (!hasRiskyActivity) return false;
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
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _performSearch();
    }
  }

  Future<void> _showPartnerFilter() async {
    final provider = context.read<SexualEventsProvider>();
    final allPersons = await provider.getAllPersons();

    if (!mounted) return;

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _PartnerFilterDialog(
        allPersons: allPersons,
        selectedIds: _selectedPartnerIds,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedPartnerIds = selected;
      });
      _performSearch();
    }
  }

  Future<void> _showActivityTypeFilter() async {
    final provider = context.read<SexualEventsProvider>();
    final activityTypes =
        provider.state.sexualActivityTypes?.values.toList() ?? [];

    if (!mounted) return;

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _ActivityTypeFilterDialog(
        activityTypes: activityTypes,
        selectedIds: _selectedActivityTypeIds,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedActivityTypeIds = selected;
      });
      _performSearch();
    }
  }

  Future<void> _showPropertyFilter() async {
    final provider = context.read<SexualEventsProvider>();
    final properties =
        provider.state.sexualActivityTypeProperties?.values.toList() ?? [];

    if (!mounted) return;

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _PropertyFilterDialog(
        properties: properties,
        selectedIds: _selectedPropertyIds,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedPropertyIds = selected;
      });
      _performSearch();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      final daysAgo = today.difference(dateOnly).inDays;
      if (daysAgo < 7) {
        const weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        return weekdays[date.weekday - 1];
      } else {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    }
  }
}

// Partner filter dialog
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
            final isSelf = person.isSelf;
            return CheckboxListTile(
              title: Row(
                children: [
                  Text(
                    person.name.nickname ?? person.name.given ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: isSelf ? FontWeight.bold : null,
                    ),
                  ),
                  if (isSelf) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Me',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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

// Property filter dialog
class _PropertyFilterDialog extends StatefulWidget {
  final List<SexualActivityTypeProperty> properties;
  final Set<String> selectedIds;

  const _PropertyFilterDialog({
    required this.properties,
    required this.selectedIds,
  });

  @override
  State<_PropertyFilterDialog> createState() => _PropertyFilterDialogState();
}

class _PropertyFilterDialogState extends State<_PropertyFilterDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Properties'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.properties.map((property) {
            final isSelected = _selectedIds.contains(property.id);
            return CheckboxListTile(
              title: Row(
                children: [
                  Text(
                    property.displayCharacter,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(property.name)),
                  if (property.isRisky) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.warning, size: 16, color: Colors.orange),
                  ],
                ],
              ),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(property.id);
                  } else {
                    _selectedIds.remove(property.id);
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

// Activity type filter dialog
class _ActivityTypeFilterDialog extends StatefulWidget {
  final List<SexualActivityType> activityTypes;
  final Set<String> selectedIds;

  const _ActivityTypeFilterDialog({
    required this.activityTypes,
    required this.selectedIds,
  });

  @override
  State<_ActivityTypeFilterDialog> createState() =>
      _ActivityTypeFilterDialogState();
}

class _ActivityTypeFilterDialogState extends State<_ActivityTypeFilterDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Activity Types'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.activityTypes.map((activityType) {
            final isSelected = _selectedIds.contains(activityType.id);
            return CheckboxListTile(
              title: Row(
                children: [
                  Text(
                    activityType.displayCharacter ?? '❔',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(activityType.name),
                ],
              ),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(activityType.id);
                  } else {
                    _selectedIds.remove(activityType.id);
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
