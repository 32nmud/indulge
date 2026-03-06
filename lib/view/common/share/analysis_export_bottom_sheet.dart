import 'dart:async';

import 'package:flutter/material.dart';
import 'package:indulge/services/export_service.dart';
import 'package:indulge/view/analysis/models/activity_breakdown_data.dart';
import 'package:indulge/view/analysis/models/overview_data.dart';
import 'package:indulge/view/analysis/models/partner_breakdown_data.dart';
import 'package:logging/logging.dart';

import 'package:indulge/view/analysis/share/analysis_share_card.dart';

/// Modal bottom sheet that shows a live preview of the [AnalysisShareCard]
/// and lets the user share or save it as a JPEG.
///
/// The card is rendered visibly inside the scrollable preview area — the same
/// proven pattern used by [EventShareBottomSheet] — so the RepaintBoundary
/// always has a fully painted render object ready for capture.
///
/// Usage:
/// ```dart
/// await AnalysisExportBottomSheet.show(
///   context: context,
///   timeWindowLabel: 'Last 12 months',
///   overviewData: _overviewData,
///   activityData: _activityBreakdownData,
///   partnerData: _partnerBreakdownData,
/// );
/// ```
class AnalysisExportBottomSheet extends StatefulWidget {
  final String timeWindowLabel;
  final OverviewData overviewData;
  final ActivityBreakdownData activityData;
  final PartnerBreakdownData partnerData;

  const AnalysisExportBottomSheet({
    super.key,
    required this.timeWindowLabel,
    required this.overviewData,
    required this.activityData,
    required this.partnerData,
  });

  static Future<void> show({
    required BuildContext context,
    required String timeWindowLabel,
    required OverviewData overviewData,
    required ActivityBreakdownData activityData,
    required PartnerBreakdownData partnerData,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnalysisExportBottomSheet(
        timeWindowLabel: timeWindowLabel,
        overviewData: overviewData,
        activityData: activityData,
        partnerData: partnerData,
      ),
    );
  }

  @override
  State<AnalysisExportBottomSheet> createState() =>
      _AnalysisExportBottomSheetState();
}

class _AnalysisExportBottomSheetState extends State<AnalysisExportBottomSheet> {
  static final Logger _logger = Logger('AnalysisExportBottomSheet');

  final GlobalKey _cardKey = GlobalKey();

  bool _isSharing = false;
  bool _isSaving = false;
  bool _privacyMode = false;

  bool get _isBusy => _isSharing || _isSaving;

  String get _filename {
    final slug = widget.timeWindowLabel.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return 'indulge_analysis_$slug';
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _share() async {
    if (_isBusy) return;
    setState(() => _isSharing = true);
    try {
      // One extra frame so any pending animations settle before capture.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await ExportService.captureAndShare(
        _cardKey,
        filename: _filename,
        pixelRatio: 2.0,
      );
    } catch (e, st) {
      _logger.warning('Failed to share analysis card', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _save() async {
    if (_isBusy) return;
    setState(() => _isSaving = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final saved = await ExportService.captureAndSave(
        _cardKey,
        filename: _filename,
        pixelRatio: 2.0,
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image saved')));
      }
    } catch (e, st) {
      _logger.warning('Failed to save analysis card', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      'Export Analysis',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Scrollable body ──────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  children: [
                    // The card is 1920 px wide — scale it down to fit the
                    // available preview width while keeping the RepaintBoundary
                    // at full logical size so the capture is full-resolution.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox(
                          height: null,
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.topCenter,
                            child: RepaintBoundary(
                              key: _cardKey,
                              child: AnalysisShareCard(
                                overviewData: widget.overviewData,
                                activityData: widget.activityData,
                                partnerData: widget.partnerData,
                                timeWindowLabel: widget.timeWindowLabel,
                                privacyMode: _privacyMode,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── Privacy toggle ─────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        secondary: Icon(
                          _privacyMode
                              ? Icons.lock_outline
                              : Icons.lock_open_outlined,
                          size: 20,
                          color: _privacyMode
                              ? const Color(0xFF4DB6AC)
                              : colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'Anonymise partners',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _privacyMode
                                ? const Color(0xFF4DB6AC)
                                : colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          _privacyMode
                              ? 'Partner names and photos are hidden — safe to share.'
                              : 'Toggle to hide partner names and photos before sharing.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: _privacyMode,
                        activeColor: const Color(0xFF4DB6AC),
                        onChanged: (v) => setState(() => _privacyMode = v),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Info note ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Preview is scaled to fit your screen. '
                              'The exported image is high-resolution. '
                              'Review the preview before sharing.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom padding so the pinned buttons don't overlap.
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // ── Action buttons (pinned) ──────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    // Save
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isBusy ? null : _save,
                        icon: _isSaving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.save_alt_outlined),
                        label: Text(_isSaving ? 'Saving…' : 'Save'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Share
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _isBusy ? null : _share,
                        icon: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share_outlined),
                        label: Text(_isSharing ? 'Preparing…' : 'Share'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
