import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/view/person_editor/person_editor_page.dart';
import 'package:logging/logging.dart';

class PersonListPage extends StatefulWidget {
  const PersonListPage({super.key});

  @override
  State<PersonListPage> createState() => _PersonListPageState();
}

class _PersonListPageState extends State<PersonListPage>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger('PersonListPage');
  List<Person> _persons = [];
  Map<String, int> _personEventCounts = {};
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPersons();
    // Listen to provider changes to reload when persons are added/modified
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SexualEventsProvider>().addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    context.read<SexualEventsProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    setState(() => _isLoading = true);
    final provider = context.read<SexualEventsProvider>();
    final persons = await provider.getAllPersons();

    // Calculate event counts for each person
    final allEvents = await provider.getAllEvents();
    _logger.info(
      'Counting events for ${persons.length} persons across ${allEvents.length} events',
    );
    final eventCounts = <String, int>{};

    for (final person in persons) {
      int count = 0;
      for (final event in allEvents) {
        // Check if this person participated in this event
        // An event counts if the person appears in ANY activity
        bool participated = event.activities.any(
          (activity) => activity.participants.any(
            (participant) =>
                participant.participant.resourceType == 'Person' &&
                participant.participant.reference == person.id,
          ),
        );

        if (participated) {
          count++;
        }
      }
      eventCounts[person.id] = count;
      _logger.info(
        'Person ${person.name.nickname ?? person.name.given ?? person.id}: $count events',
      );
    }

    setState(() {
      _persons = persons;
      _personEventCounts = eventCounts;
      _isLoading = false;
    });
  }

  Future<void> _navigateToEditor({Person? person}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonEditorPage(person: person)),
    );
    // Refresh the list when returning from editor
    _loadPersons();
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
        _loadPersons();

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
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadPersons();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _persons.isEmpty
            ? _buildEmptyState()
            : _buildPersonList(),
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelf
              ? Theme.of(context).colorScheme.primary
              : null,
          child: Icon(
            isSelf ? Icons.account_circle : Icons.person,
            color: isSelf ? Theme.of(context).colorScheme.onPrimary : null,
          ),
        ),
        title: Row(
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelf) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Me',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Event count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$eventCount',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditor(person: person),
              tooltip: 'Edit',
            ),
            if (!isSelf)
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                onPressed: () => _deletePerson(person),
                tooltip: 'Delete',
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
