import 'dart:async';

import 'package:flutter/material.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/services/export_service.dart';
import 'package:logging/logging.dart';

import 'sexual_event_share_card.dart';

/// A modal bottom sheet that shows a live preview of the share card alongside
/// privacy toggles, then captures and shares the card as a JPEG when the user
/// taps "Share".
///
/// Usage:
/// ```dart
/// await EventShareBottomSheet.show(
///   context: context,
///   event: event,
///   persons: persons,
///   categories: categories,
/// );
/// ```
class EventShareBottomSheet extends StatefulWidget {
  final SexualEvent event;
  final List<Person> persons;
  final Map<String, SexualActivityCategory> categories;

  const EventShareBottomSheet({
    super.key,
    required this.event,
    required this.persons,
    required this.categories,
  });

  /// Convenience method to show the bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required SexualEvent event,
    required List<Person> persons,
    required Map<String, SexualActivityCategory> categories,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventShareBottomSheet(
        event: event,
        persons: persons,
        categories: categories,
      ),
    );
  }

  @override
  State<EventShareBottomSheet> createState() => _EventShareBottomSheetState();
}

class _EventShareBottomSheetState extends State<EventShareBottomSheet> {
  static final Logger _logger = Logger('EventShareBottomSheet');

  bool _showPartnerNames = true;
  bool _showProfilePictures = true;
  bool _isSharing = false;
  bool _isSaving = false;

  // Key used by ExportService to locate the RepaintBoundary.
  final GlobalKey _cardKey = GlobalKey();

  String get _filename =>
      'indulge_event_${widget.event.date.millisecondsSinceEpoch}';

  Future<void> _share() async {
    if (_isSharing || _isSaving) return;

    setState(() => _isSharing = true);

    try {
      // Give Flutter one frame to settle any toggle animations before capture.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await ExportService.captureAndShare(_cardKey, filename: _filename);
    } catch (e, st) {
      _logger.warning('Failed to share event card', e, st);
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
    if (_isSharing || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final saved = await ExportService.captureAndSave(
        _cardKey,
        filename: _filename,
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image saved')));
      }
    } catch (e, st) {
      _logger.warning('Failed to save event card', e, st);
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
              // ── Drag handle ───────────────────────────────────────────────
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

              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      'Share Event',
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

              // ── Scrollable body ───────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  children: [
                    // ── Card preview ──────────────────────────────────────
                    Center(
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: SexualEventShareCard(
                          event: widget.event,
                          persons: widget.persons,
                          categories: widget.categories,
                          showPartnerNames: _showPartnerNames,
                          showProfilePictures: _showProfilePictures,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Privacy options ───────────────────────────────────
                    Text(
                      'Privacy',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ToggleTile(
                      icon: Icons.people_outline,
                      title: 'Show partner names',
                      subtitle: widget.persons.isEmpty
                          ? 'No partners on this event'
                          : 'Names will appear on the card',
                      value: _showPartnerNames,
                      enabled: widget.persons.isNotEmpty,
                      onChanged: (v) => setState(() => _showPartnerNames = v),
                    ),
                    _ToggleTile(
                      icon: Icons.account_circle_outlined,
                      title: 'Show profile pictures',
                      subtitle: widget.persons.isEmpty
                          ? 'No partners on this event'
                          : 'Avatars will appear on the card',
                      value: _showProfilePictures,
                      enabled: widget.persons.isNotEmpty,
                      onChanged: (v) =>
                          setState(() => _showProfilePictures = v),
                    ),

                    const SizedBox(height: 8),

                    // ── Privacy disclaimer ────────────────────────────────
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
                              'Only the information shown in the preview above '
                              'will be included in the shared image. No other '
                              'data leaves your device.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Extra bottom padding so the share button doesn't
                    // overlap the last content when not scrolled.
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // ── Action buttons (pinned to bottom) ─────────────────────────
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
                    // Save to file
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isSharing || _isSaving) ? null : _save,
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
                        onPressed: (_isSharing || _isSaving) ? null : _share,
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

// ── Private helpers ──────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SwitchListTile(
          secondary: Icon(icon, color: colorScheme.primary),
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          value: value && enabled,
          onChanged: enabled ? onChanged : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
        ),
      ),
    );
  }
}
