import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:indulge/data/models/v2/clinical_event/clinical_event.dart';
import 'package:indulge/data/models/v2/clinical_test_result/clinical_test_result.dart';
import 'package:indulge/view/common/sexual_event_editor/widgets/widgets.dart';

/// A form widget for creating/editing a `ClinicalEvent`.
///
/// - Shows a required date field (prefills from `initialDate` or `initialEvent`).
/// - Allows adding/removing one or more test rows. Each row requires:
///   - `TestType` (enum). If `other` is selected, a small free-text label is shown
///     for clarification (the tests model does not persist this label per-test;
///     any provided labels will be appended to the event notes on save).
///   - `TestResult` (enum).
///   - `SpecimenSite` (enum).
/// - Optional `facility` and `notes` fields.
/// - `onSave` receives a built `ClinicalEvent` and should return a `Future<bool>`
///   indicating whether the save succeeded. If `onSave` is omitted, the form
///   will simply `Navigator.pop(context, event)` with the built event.
class ClinicalEventForm extends StatefulWidget {
  final ClinicalEvent? initialEvent;
  final DateTime? initialDate;
  final Future<bool> Function(ClinicalEvent event)? onSave;

  const ClinicalEventForm({
    Key? key,
    this.initialEvent,
    this.initialDate,
    this.onSave,
  }) : super(key: key);

  @override
  State<ClinicalEventForm> createState() => ClinicalEventFormState();
}

class ClinicalEventFormState extends State<ClinicalEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _facilityController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _date;
  bool _loading = false;
  bool _touched = false;

  final List<_TestRowModel> _tests = [];

  @override
  void initState() {
    super.initState();

    // Initialize from initialEvent if provided.
    if (widget.initialEvent != null) {
      final ev = widget.initialEvent!;
      _date = ev.date.toLocal();
      _facilityController.text = ev.facility ?? '';
      _notesController.text = ev.notes ?? '';

      // Map existing tests into UI models. We won't capture per-test free-text
      // labels because the persisted model doesn't include that field; the UI
      // still allows typing one (stored in _TestRowModel.otherLabel) and we'll
      // append those labels to the event notes when saving.
      for (final t in ev.tests) {
        _tests.add(
          _TestRowModel(
            testType: t.testType,
            result: t.result,
            specimenSite: t.specimenSite,
          ),
        );
      }
    } else {
      // Default date: initialDate or now.
      _date = (widget.initialDate ?? DateTime.now()).toLocal();

      // Start with a single empty test row by default.
      _tests.add(_TestRowModel());
    }

    // Mark touched whenever controllers change.
    _facilityController.addListener(() => _markTouched());
    _notesController.addListener(() => _markTouched());
  }

  @override
  void dispose() {
    _facilityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _markTouched() {
    if (!_touched) {
      setState(() {
        _touched = true;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked.toLocal();
        _markTouched();
      });
    }
  }

  void _addTest() {
    setState(() {
      _tests.add(_TestRowModel());
      _markTouched();
    });
  }

  void _removeTest(int index) {
    if (_tests.length <= 1) {
      // Keep at least one test row in the UI to match validation requirement.
      return;
    }
    setState(() {
      _tests.removeAt(index);
      _markTouched();
    });
  }

  bool get _isDirty => _touched;

  Future<void> _onCancel() async {
    if (_isDirty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes. Discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    Navigator.of(context).pop();
  }

  Future<bool> _onSavePressed() async {
    final form = _formKey.currentState;
    if (form == null) return false;

    if (!form.validate()) {
      // Scroll-to-top-ish behavior could be added if the form is long.
      return false;
    }

    // Map UI models into domain DTOs.
    final notesBuffer = StringBuffer();
    if (_notesController.text.trim().isNotEmpty) {
      notesBuffer.writeln(_notesController.text.trim());
    }

    // Append any 'other' labels per-test in a compact form so we don't lose
    // the user's clarification even though the per-test model doesn't persist it.
    final otherLabels = <String>[];
    final tests = <ClinicalTestResult>[];

    for (var i = 0; i < _tests.length; i++) {
      final row = _tests[i];
      if (row.testType == null ||
          row.result == null ||
          row.specimenSite == null) {
        // Shouldn't happen because validators should have prevented submission.
        continue;
      }
      tests.add(
        ClinicalTestResult(
          testType: row.testType!,
          result: row.result!,
          specimenSite: row.specimenSite!,
        ),
      );

      if (row.otherLabel.trim().isNotEmpty) {
        otherLabels.add(
          'Test ${i + 1} (${describeEnum(row.testType!)}): ${row.otherLabel.trim()}',
        );
      }
    }

    if (otherLabels.isNotEmpty) {
      notesBuffer.writeln();
      notesBuffer.writeln('Other test labels:');
      for (final l in otherLabels) {
        notesBuffer.writeln('- $l');
      }
    }

    final built = ClinicalEvent(
      id: widget.initialEvent?.id ?? const Uuid().v4(),
      // Store the selected date as a local DateTime so repository queries
      // using local-day start/end match saved rows.
      date: _date,
      tests: tests,
      facility: _facilityController.text.trim().isEmpty
          ? null
          : _facilityController.text.trim(),
      notes: notesBuffer.toString().trim().isEmpty
          ? null
          : notesBuffer.toString().trim(),
    );

    setState(() {
      _loading = true;
    });

    bool success = true;
    try {
      if (widget.onSave != null) {
        success = await widget.onSave!(built);
      } else {
        // No onSave provided: let the caller handle navigation/persistence.
        success = true;
      }
    } catch (e) {
      success = false;
    }

    if (!mounted) return success;

    setState(() {
      _loading = false;
    });

    if (success) {
      // Don't pop here; caller (page) should handle navigation after calling submit().
      if (widget.onSave != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Clinical event saved')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save clinical event. Please try again.'),
        ),
      );
    }

    return success;
  }

  /// Public helper used by callers that hold a `GlobalKey<ClinicalEventFormState>`
  /// to trigger the form submission programmatically (for example from an
  /// AppBar save button). Returns `true` when save succeeded.
  Future<bool> submit() async => await _onSavePressed();

  String _formatDate(DateTime d) => DateFormat.yMMMMd().format(d);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          onChanged: _markTouched,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date
                DateTimeSection(dateTime: _date, onTap: _selectDate),
                const SizedBox(height: 16),

                // Tests list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addTest,
                      icon: const Icon(Icons.add),
                      label: const Text('Add test'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Column(
                  children: List.generate(_tests.length, (index) {
                    final row = _tests[index];
                    return Card(
                      key: ValueKey(index),
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<TestType>(
                                    value: row.testType,
                                    decoration: const InputDecoration(
                                      labelText: 'Test type',
                                    ),
                                    items: TestType.values
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(_displayTestType(t)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        row.testType = v;
                                        _markTouched();
                                      });
                                    },
                                    validator: (v) =>
                                        v == null ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _tests.length > 1
                                      ? () => _removeTest(index)
                                      : null,
                                  icon: const Icon(Icons.delete),
                                  tooltip: _tests.length > 1
                                      ? 'Remove test'
                                      : 'Keep at least one test',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<TestResult>(
                                    value: row.result,
                                    decoration: const InputDecoration(
                                      labelText: 'Result',
                                    ),
                                    items: TestResult.values
                                        .map(
                                          (r) => DropdownMenuItem(
                                            value: r,
                                            child: Text(_displayTestResult(r)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        row.result = v;
                                        _markTouched();
                                      });
                                    },
                                    validator: (v) =>
                                        v == null ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<SpecimenSite>(
                                    value: row.specimenSite,
                                    decoration: const InputDecoration(
                                      labelText: 'Specimen site',
                                    ),
                                    items: SpecimenSite.values
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              _displaySpecimenSite(s),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        row.specimenSite = v;
                                        _markTouched();
                                      });
                                    },
                                    validator: (v) =>
                                        v == null ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),

                            // If TestType.other, allow a small free-text label for clarification.
                            if (row.testType == TestType.other) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: row.otherLabel,
                                decoration: const InputDecoration(
                                  labelText: 'Other test label (optional)',
                                  hintText: 'e.g., NAAT for X organism',
                                ),
                                onChanged: (v) {
                                  row.otherLabel = v;
                                  _markTouched();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // Facility
                TextFormField(
                  controller: _facilityController,
                  decoration: const InputDecoration(
                    labelText: 'Facility (optional)',
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                NotesSection(
                  initialNotes: _notesController.text,
                  onNotesChanged: (v) => _notesController.text = v,
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Loading overlay
        if (_loading)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
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
}

/// Simple mutable model used by the form to track per-row state.
class _TestRowModel {
  TestType? testType;
  TestResult? result;
  SpecimenSite? specimenSite;

  /// Optional free-text label shown when `testType == TestType.other`.
  String otherLabel = '';

  _TestRowModel({
    this.testType,
    this.result,
    this.specimenSite,
    this.otherLabel = '',
  });
}

/// Small helper to describe enum values in places where `describeEnum` from
/// foundation isn't available. We only need it for basic debug-ish use above.
String describeEnum(Object enumEntry) {
  final s = enumEntry.toString();
  final index = s.indexOf('.');
  return index == -1 ? s : s.substring(index + 1);
}
