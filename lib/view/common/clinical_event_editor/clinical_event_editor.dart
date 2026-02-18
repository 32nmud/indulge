import 'package:flutter/material.dart';
import 'clinical_event_form.dart';
import 'package:indulge/data/models/v2/clinical_event/clinical_event.dart';

/// ClinicalEventEditorPage hosts the `ClinicalEventForm` and provides an
/// AppBar save action that mirrors the behavior in the sexual event editor:
/// - Save button in the AppBar (disabled while saving)
/// - On save success the page pops
/// - On error a red SnackBar is shown
class ClinicalEventEditorPage extends StatefulWidget {
  final ClinicalEvent? initialEvent;
  final DateTime? initialDate;
  final Future<bool> Function(ClinicalEvent event)? onSave;

  const ClinicalEventEditorPage({
    Key? key,
    this.initialEvent,
    this.initialDate,
    this.onSave,
  }) : super(key: key);

  @override
  State<ClinicalEventEditorPage> createState() =>
      _ClinicalEventEditorPageState();
}

class _ClinicalEventEditorPageState extends State<ClinicalEventEditorPage> {
  final GlobalKey<ClinicalEventFormState> _formKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _handleSavePressed() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await formState.submit();
      if (success) {
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save clinical event.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialEvent != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit clinical event' : 'New clinical event'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _handleSavePressed,
            tooltip: 'Save Event',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClinicalEventForm(
            _formKey,
            initialEvent: widget.initialEvent,
            initialDate: widget.initialDate,
            onSave: widget.onSave,
          ),
        ),
      ),
    );
  }
}
