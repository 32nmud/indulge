import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:indulge/data/models/v1/clinical_event/clinical_event.dart';
import 'package:indulge/data/models/v1/clinical_test_result/clinical_test_result.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/view/common/clinical_event_editor/clinical_event_editor.dart';

/// A compact card that displays a single `ClinicalEvent` and its tests.
///
/// The visual style and affordances are intentionally similar to the
/// sexual event card: collapsible with expansion tile, shows test details,
/// and displays notes below the test results when present.
class ClinicalEventCard extends StatefulWidget {
  final ClinicalEvent event;

  const ClinicalEventCard(Key? key, {required this.event}) : super(key: key);

  @override
  State<ClinicalEventCard> createState() => _ClinicalEventCardState();
}

class _ClinicalEventCardState extends State<ClinicalEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _displayTestType(TestType t) {
    switch (t) {
      case TestType.chlamydia:
        return 'Chlamydia';
      case TestType.gonorrhea:
        return 'Gonorrhea';
      case TestType.hiv:
        return 'HIV';
      case TestType.syphilis:
        return 'Syphilis';
      case TestType.trichomonas:
        return 'Trichomonas';
      case TestType.hepatitis:
        return 'Hepatitis';
      case TestType.other:
        return 'Other';
    }
  }

  String _displayTestResult(TestResult r) {
    switch (r) {
      case TestResult.negative:
        return 'Negative';
      case TestResult.positive:
        return 'Positive';
      case TestResult.indeterminate:
        return 'Indeterminate';
      case TestResult.pending:
        return 'Pending';
    }
  }

  String _displaySpecimenSite(SpecimenSite s) {
    switch (s) {
      case SpecimenSite.throat:
        return 'Throat';
      case SpecimenSite.urine:
        return 'Urine';
      case SpecimenSite.rectal:
        return 'Rectal';
      case SpecimenSite.blood:
        return 'Blood';
    }
  }

  Widget _buildTestRow(ClinicalTestResult tr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              _displayTestType(tr.testType),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _displaySpecimenSite(tr.specimenSite),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _displayTestResult(tr.result),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: tr.result == TestResult.positive
                    ? Colors.redAccent
                    : (tr.result == TestResult.negative
                          ? Colors.green
                          : Colors.orange),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final provider = context.read<ClinicalEventsProvider>();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => ClinicalEventEditorPage(
          initialEvent: widget.event,
          initialDate: widget.event.date,
          onSave: (ClinicalEvent updatedEvent) async {
            try {
              await provider.saveEvent(updatedEvent);
              return true;
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Error saving clinical event: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return false;
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Clinical Event'),
          content: const Text(
            'Are you sure you want to delete this clinical event? This action cannot be undone.',
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

    if (confirmed == true && context.mounted) {
      try {
        final provider = context.read<ClinicalEventsProvider>();
        await provider.deleteEvent(widget.event.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting clinical event: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildButtonRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            onPressed: () => _openEditor(context),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes =
        widget.event.notes != null && widget.event.notes!.trim().isNotEmpty;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) => _scaleController.reverse(),
          onTapCancel: () => _scaleController.reverse(),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.medical_services,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              'Clinical event with ${widget.event.tests.length} test${widget.event.tests.length == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_formatDate(widget.event.date)),
            children: [
              // Tests list header
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Test',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Site',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Result',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Tests
              ...widget.event.tests.map((t) => _buildTestRow(t)),
              // Notes section
              if (hasNotes) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Notes",
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        MarkdownBody(data: widget.event.notes!),
                      ],
                    ),
                  ),
                ),
              ],
              const Divider(),
              _buildButtonRow(context),
            ],
          ),
        ),
      ),
    );
  }
}
