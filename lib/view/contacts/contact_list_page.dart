import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:indulge/data/models.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/view/common/contact_editor/contact_editor_page.dart';
import 'package:indulge/view/common/person_avatar.dart';
import 'package:logging/logging.dart';
import 'package:indulge/view/common/navigation_helper.dart';
import 'package:indulge/view/common/util/pagination_controller.dart';

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger('PersonListPage');
  List<Person> _persons = [];
  Map<String, int> _personEventCounts = {};
  bool _isLoading = true;

  // Pager for contacts list pagination (keeps the UI small for long lists)
  final PaginationController<Person> _pager = PaginationController<Person>(
    pageSize: 20,
  );

  // Scroll controller used to detect when we should load more contacts.
  final ScrollController _scrollController = ScrollController();

  // Cached store reference so dispose() never reads context after deactivation.
  late EventStateStore _store;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Cache the store reference once — safe to read context here.
    _store = context.read<EventStateStore>();

    // Defer loading to avoid triggering during widget tree build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPersons();
    });

    // Listen for scrolls to implement load-more for the contacts list.
    _scrollController.addListener(_onScroll);

    // Listen to store to refresh when persons change (not on date changes).
    _store.addListener(_onStoreChange);
  }

  void _onStoreChange() {
    // Guard: never touch context or setState on a deactivated widget.
    if (!mounted) return;

    // Only react to store changes if we've already loaded initial data
    // or if the store indicates a data refresh is needed.
    if (_persons.isEmpty || !_store.needsDataRefresh) {
      return;
    }
    // Only reload if persons actually changed, not for date changes.
    final cachedPersons = _store.state.allPersons;
    if (cachedPersons != null) {
      final cachedIds = cachedPersons.map((p) => p.id).toSet();
      final currentIds = _persons.map((p) => p.id).toSet();
      if (!setEquals(cachedIds, currentIds)) {
        _loadPersons(forceLoadEvents: true);
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final threshold = _scrollController.position.maxScrollExtent * 0.8;
    if (_scrollController.position.pixels >= threshold) {
      // Request next page if available.
      if (_pager.canLoadMore(_persons) &&
          !_pager.isLoadingMore &&
          !_isLoading) {
        // Simulate the same UX as other lists: slight delay before adding items.
        setState(() {
          _pager.isLoadingMore = true;
        });

        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          _pager.loadMore(_persons);
          setState(() {
            _pager.isLoadingMore = false;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    // Remove listener via the cached reference — never read context here,
    // as the widget may already be deactivated.
    _store.removeListener(_onStoreChange);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPersons({bool forceLoadEvents = false}) async {
    if (!mounted) return;

    // Skip if we already have counts AND data isn't dirty (no new events/persons added).
    if (_personEventCounts.isNotEmpty &&
        !forceLoadEvents &&
        !_store.needsDataRefresh) {
      return;
    }

    setState(() => _isLoading = true);

    // Capture provider before the first await so we never read context
    // on a potentially-deactivated widget after suspension.
    final provider = context.read<SexualEventsProvider>();

    // Prefer the cached list of persons from the centralized store when available
    // to avoid an extra DB call; fall back to the provider otherwise.
    final persons = _store.state.allPersons ?? await provider.getAllPersons();

    if (!mounted) return;

    // Filter out the anonymous person early so event counting and pagination
    // operate only on visible contacts.
    final visiblePersons = persons.where((p) => p.id != 'anonymous').toList();

    // Fetch all events if data has changed, if force is specified, or on initial load
    // (when we don't have cached event counts yet).
    List<SexualEvent> allEvents = [];
    final hasEventCounts = _personEventCounts.isNotEmpty;
    if (forceLoadEvents || _store.needsDataRefresh || !hasEventCounts) {
      allEvents = await provider.getAllEvents();
      if (!mounted) return;
      if (_store.needsDataRefresh) {
        _store.clearDataDirty();
      }
    }

    _logger.info(
      'Counting events for ${visiblePersons.length} persons across ${allEvents.length} events',
    );
    final eventCounts = <String, int>{};

    for (final person in visiblePersons) {
      int count = 0;
      for (final event in allEvents) {
        // An event counts if the person appears in ANY activity.
        final participated = event.activities.any(
          (activity) => activity.participants.any(
            (participant) =>
                participant.participant.resourceType == 'Person' &&
                participant.participant.reference == person.id,
          ),
        );
        if (participated) count++;
      }
      eventCounts[person.id] = count;
      _logger.info(
        'Person ${person.name.nickname ?? person.name.given ?? person.id}: $count events',
      );
    }

    if (!mounted) return;

    // Initialize pager with visible persons so the UI can show a paginated list.
    _pager.reset();
    _pager.loadInitial(visiblePersons);

    setState(() {
      _persons = visiblePersons;
      _personEventCounts = eventCounts;
      _isLoading = false;
    });
  }

  Future<void> _navigateToEditor({Person? person}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactEditorPage(person: person),
      ),
    );
    // Refresh the list when returning from editor (force load events for accurate counts).
    if (mounted) _loadPersons(forceLoadEvents: true);
  }

  Future<void> _deletePerson(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Person'),
          content: Text(
            'Are you sure you want to delete ${person.name.nickname ?? person.name.given ?? "this person"}?\n\nAll events with this person will be updated to show "Anonymous" instead. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final provider = context.read<SexualEventsProvider>();
        await provider.deletePerson(person.id);
        // Force reload events for accurate counts after deletion
        _loadPersons(forceLoadEvents: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Deleted ${person.name.nickname ?? person.name.given}',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting person: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Watch EventStateStore so this widget rebuilds when the centralized store changes.
    // The _onStoreChange listener handles data refresh on changes.
    context.watch<EventStateStore>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Contacts',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadPersons(forceLoadEvents: true);
                },
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _persons.isEmpty
                    ? _buildEmptyState()
                    : _buildPersonList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No contacts yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a person to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonList() {
    // Filter out the anonymous person from the contacts list
    final visiblePersons = _persons.where((p) => p.id != 'anonymous').toList();

    if (visiblePersons.isEmpty) {
      return _buildEmptyState();
    }

    // Sort to pin "Me" person to the top
    visiblePersons.sort((a, b) {
      if (a.isSelf && !b.isSelf) return -1;
      if (!a.isSelf && b.isSelf) return 1;
      // For other persons, maintain their original order or sort by name
      final aName = a.name.nickname ?? a.name.given ?? 'Unknown';
      final bName = b.name.nickname ?? b.name.given ?? 'Unknown';
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return ListView.builder(
      itemCount: visiblePersons.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final person = visiblePersons[index];
        return _buildPersonCard(person);
      },
    );
  }

  Widget _buildPersonCard(Person person) {
    final displayName = person.name.nickname ?? person.name.given ?? 'Unknown';
    final subtitle = _buildSubtitle(person);
    final isSelf = person.isSelf;
    final eventCount = _personEventCounts[person.id] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelf ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: Avatar, Name, Badge
            Row(
              children: [
                PersonAvatar(person: person, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: isSelf
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Me',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Event count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$eventCount',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second row: Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search'),
                  onPressed: () {
                    NavigationHelper.of(
                      context,
                    )?.navigateToSearchWithPartner(person.id);
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  onPressed: () => _navigateToEditor(person: person),
                ),
                if (!isSelf) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _deletePerson(person),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _buildSubtitle(Person person) {
    final parts = <String>[];

    if (person.name.given != null && person.name.nickname != null) {
      parts.add(person.name.given!);
    }

    if (person.name.family != null) {
      parts.add(person.name.family!);
    }

    if (person.birthday != null) {
      final age = _calculateAge(person.birthday!);
      if (age != null) {
        parts.add('$age years old');
      }
    }

    return parts.isEmpty ? null : parts.join(' • ');
  }

  int? _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }
}
