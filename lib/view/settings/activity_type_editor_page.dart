import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/data/models.dart';
import 'package:uuid/uuid.dart';

class ActivityTypeEditorPage extends StatefulWidget {
  final SexualActivityType? activityType;

  const ActivityTypeEditorPage({super.key, this.activityType});

  @override
  State<ActivityTypeEditorPage> createState() => _ActivityTypeEditorPageState();
}

class _ActivityTypeEditorPageState extends State<ActivityTypeEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emojiController;
  late List<_PropertyRow> _properties;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.activityType?.name ?? '',
    );
    _emojiController = TextEditingController(
      text: widget.activityType?.displayCharacter ?? '❓',
    );

    // Load existing properties or start with empty list
    _properties = [];
    if (widget.activityType != null) {
      final provider = context.read<SexualEventsProvider>();
      for (var ref in widget.activityType!.properties) {
        final property =
            provider.state.sexualActivityTypeProperties?[ref.reference];
        if (property != null) {
          _properties.add(
            _PropertyRow(
              id: property.id,
              nameController: TextEditingController(text: property.name),
              emojiController: TextEditingController(
                text: property.displayCharacter,
              ),
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
    for (var property in _properties) {
      property.nameController.dispose();
      property.emojiController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activityType == null
              ? 'New Activity Type'
              : 'Edit Activity Type',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveActivityType,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                              labelText: 'Activity Name *',
                              hintText: 'e.g., Oral Sex, Kissing, etc.',
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
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Properties',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addProperty,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Property'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_properties.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No properties added yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._properties.asMap().entries.map((entry) {
                        final index = entry.key;
                        final property = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  // Property emoji
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                      controller: property.emojiController,
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
                                  // Property name
                                  Expanded(
                                    child: TextFormField(
                                      controller: property.nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Property Name',
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
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeProperty(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveActivityType,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.activityType == null ? 'Create' : 'Save',
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

  void _addProperty() {
    setState(() {
      _properties.add(
        _PropertyRow(
          id: const Uuid().v4(),
          nameController: TextEditingController(),
          emojiController: TextEditingController(text: '❔'),
        ),
      );
    });
  }

  void _removeProperty(int index) {
    setState(() {
      _properties[index].nameController.dispose();
      _properties[index].emojiController.dispose();
      _properties.removeAt(index);
    });
  }

  Future<void> _saveActivityType() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<SexualEventsProvider>();

      // Save all properties first
      final propertyReferences = <Reference>[];
      for (var property in _properties) {
        final prop = SexualActivityTypeProperty(
          id: property.id,
          name: property.nameController.text.trim(),
          displayCharacter: property.emojiController.text.trim(),
        );
        await provider.saveActivityProperty(prop);
        propertyReferences.add(
          Reference(
            reference: prop.id,
            resourceType: 'SexualActivityTypeProperty',
          ),
        );
      }

      // Save the activity type
      final activityType = SexualActivityType(
        id: widget.activityType?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        displayCharacter: _emojiController.text.trim(),
        properties: propertyReferences,
      );

      await provider.saveActivityType(activityType);

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

class _PropertyRow {
  final String id;
  final TextEditingController nameController;
  final TextEditingController emojiController;

  _PropertyRow({
    required this.id,
    required this.nameController,
    required this.emojiController,
  });
}
