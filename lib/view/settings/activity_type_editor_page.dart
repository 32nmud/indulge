import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/data/models.dart';
import 'package:uuid/uuid.dart';

class ActivityTypeEditorPage extends StatefulWidget {
  final SexualActivityCategory? activityCategory;

  const ActivityTypeEditorPage({super.key, this.activityCategory});

  @override
  State<ActivityTypeEditorPage> createState() => _ActivityTypeEditorPageState();
}

class _ActivityTypeEditorPageState extends State<ActivityTypeEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emojiController;
  late List<_ActivityRow> _activities;
  bool _isLoading = false;
  bool _requiresPartner = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.activityCategory?.name ?? '',
    );
    _emojiController = TextEditingController(
      text: widget.activityCategory?.displayCharacter ?? '❓',
    );
    _requiresPartner = widget.activityCategory?.requiresPartner ?? false;

    // Load existing activities or start with empty list
    _activities = [];
    if (widget.activityCategory != null) {
      final provider = context.read<SexualEventsProvider>();
      for (var ref in widget.activityCategory!.activities) {
        final activity = provider.state.sexualActivities?[ref.reference];
        if (activity != null) {
          _activities.add(
            _ActivityRow(
              id: activity.id,
              nameController: TextEditingController(text: activity.name),
              emojiController: TextEditingController(
                text: activity.displayCharacter,
              ),
              isRisky: activity.isRisky,
              requiresPartner: activity.requiresPartner,
              canHaveMultipleParticipants: activity.canHaveMultipleParticipants,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    for (var activity in _activities) {
      activity.nameController.dispose();
      activity.emojiController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activityCategory == null ? 'New Category' : 'Edit Category',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveActivityCategory,
            ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _addActivity,
              child: const Icon(Icons.add),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji field
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _emojiController,
                            decoration: const InputDecoration(
                              labelText: 'Emoji',
                              border: OutlineInputBorder(),
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 32),
                            maxLength: 1,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name field
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Category Name *',
                              hintText: 'e.g., Oral, Vaginal, Manual, etc.',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Activity-level requiresPartner checkbox
                    CheckboxListTile(
                      title: const Text('Requires Partner'),
                      subtitle: const Text(
                        'When enabled, this category cannot be performed alone (requires at least one other person)',
                      ),
                      value: _requiresPartner,
                      onChanged: (value) {
                        setState(() {
                          _requiresPartner = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Activities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_activities.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No activities added yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._activities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final activity = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  // Activity emoji
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                      controller: activity.emojiController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 24),
                                      maxLength: 1,
                                      keyboardType: TextInputType.text,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return '!';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Activity name
                                  Expanded(
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: activity.nameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Activity Name',
                                            hintText: 'e.g., Giving, Receiving',
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Name required';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CheckboxListTile(
                                                title: const Text(
                                                  'Risky',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                value: activity.isRisky,
                                                onChanged: (value) {
                                                  setState(() {
                                                    activity.isRisky =
                                                        value ?? false;
                                                  });
                                                },
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                              ),
                                            ),
                                            Expanded(
                                              child: CheckboxListTile(
                                                title: const Text(
                                                  'Needs Partner',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                value: activity.requiresPartner,
                                                onChanged: (value) {
                                                  setState(() {
                                                    activity.requiresPartner =
                                                        value ?? false;
                                                  });
                                                },
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                              ),
                                            ),
                                          ],
                                        ),
                                        CheckboxListTile(
                                          title: const Text(
                                            'Can have multiple participants',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          value: activity
                                              .canHaveMultipleParticipants,
                                          onChanged: (value) {
                                            setState(() {
                                              activity.canHaveMultipleParticipants =
                                                  value ?? true;
                                            });
                                          },
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeActivity(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveActivityCategory,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.activityCategory == null ? 'Create' : 'Save',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _addActivity() {
    setState(() {
      _activities.add(
        _ActivityRow(
          id: const Uuid().v4(),
          nameController: TextEditingController(),
          emojiController: TextEditingController(text: '❔'),
          isRisky: false,
          requiresPartner: false,
          canHaveMultipleParticipants: true,
        ),
      );
    });
  }

  Future<void> _removeActivity(int index) async {
    final activityRow = _activities[index];
    final id = activityRow.id;
    final isExisting =
        widget.activityCategory?.activities.any((ref) => ref.reference == id) ??
        false;

    if (isExisting) {
      final provider = context.read<SexualEventsProvider>();
      final count = await provider.getUsageCountForActivity(id);

      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Activity?'),
          content: Text(
            count > 0
                ? 'This activity is used in $count existing event${count == 1 ? '' : 's'}. Deleting it will remove it from all of them.'
                : 'Are you sure you want to delete this activity?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await provider.deleteSexualActivity(id);
    }

    if (!mounted) return;

    setState(() {
      _activities[index].nameController.dispose();
      _activities[index].emojiController.dispose();
      _activities.removeAt(index);
    });
  }

  Future<void> _saveActivityCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<SexualEventsProvider>();

      // Save all activities first
      final activityReferences = <Reference>[];
      for (var activity in _activities) {
        final act = SexualActivity(
          id: activity.id,
          name: activity.nameController.text.trim(),
          displayCharacter: activity.emojiController.text.trim(),
          isRisky: activity.isRisky,
          requiresPartner: activity.requiresPartner,
          canHaveMultipleParticipants: activity.canHaveMultipleParticipants,
        );
        await provider.saveSexualActivity(act);
        activityReferences.add(
          Reference(reference: act.id, resourceType: 'SexualActivity'),
        );
      }

      // Save the activity category
      final activityCategory = SexualActivityCategory(
        id: widget.activityCategory?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        displayCharacter: _emojiController.text.trim(),
        activities: activityReferences,
        requiresPartner: _requiresPartner,
      );

      await provider.saveActivityCategory(activityCategory);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _ActivityRow {
  final String id;
  final TextEditingController nameController;
  final TextEditingController emojiController;
  bool isRisky;
  bool requiresPartner;
  bool canHaveMultipleParticipants;

  _ActivityRow({
    required this.id,
    required this.nameController,
    required this.emojiController,
    required this.isRisky,
    required this.requiresPartner,
    required this.canHaveMultipleParticipants,
  });
}
