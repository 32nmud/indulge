import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import '../../location_map.dart';

/// A composed location editor widget that encapsulates:
///  - the Location header row (title + GPS action),
///  - the info text box with Open / Remove actions,
///  - the inline map area (using `LocationMap`) with its own Remove/Close controls.
///
/// This widget is a controlled component: the parent controls whether the map
/// area is visible via [showMap]. All actions (open, close, remove, request
/// device location, center updates) are reported back to the parent via the
/// provided callbacks.
class LocationEditor extends StatelessWidget {
  /// Whether the inline map editor is visible.
  final bool showMap;

  /// Whether a persisted or pending location is considered attached.
  /// Used to choose the info text and whether the 'Remove' button is shown.
  final bool hasAttached;

  /// Current map center / pin coordinates (used as the initial center for the map).
  final double pinLatitude;
  final double pinLongitude;

  /// Map zoom.
  final double mapZoom;

  /// Whether the editor is actively attempting to fetch device location.
  final bool isFetchingLocation;

  /// Editor-local pending selection (may be null if nothing pending).
  final double? pendingLatitude;
  final double? pendingLongitude;

  /// Controller for the underlying flutter_map instance (owned by the parent).
  final fm.MapController mapController;

  /// Invoked when the user taps the GPS icon (request device location).
  final VoidCallback onRequestLocation;

  /// Invoked when the user taps the top-level Open button (show map).
  final VoidCallback onOpen;

  /// Invoked when the user taps the Remove button (remove attached/persisted location).
  final VoidCallback onRemove;

  /// Invoked when the user taps the Close (or Remove inside map) button to close the
  /// inline map view without persisting a removal.
  final VoidCallback onClose;

  /// Called when the visible center of the map changes (panning/zooming).
  final void Function(double latitude, double longitude) onCenterChanged;

  const LocationEditor({
    super.key,
    required this.showMap,
    required this.hasAttached,
    required this.pinLatitude,
    required this.pinLongitude,
    required this.mapZoom,
    required this.isFetchingLocation,
    required this.pendingLatitude,
    required this.pendingLongitude,
    required this.mapController,
    required this.onRequestLocation,
    required this.onOpen,
    required this.onRemove,
    required this.onClose,
    required this.onCenterChanged,
  });

  Widget _buildInfoBox(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onPrimaryContainer;

    final message = hasAttached
        ? 'A location is attached to this event.'
        : 'Press the GPS icon or tap Open to center the map on your current location (will fallback to a default if unavailable).';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.primaryContainer,
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: TextStyle(color: textColor)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: onOpen, child: const Text('Open')),
          if (hasAttached) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onRemove, child: const Text('Remove')),
          ],
        ],
      ),
    );
  }

  Widget _buildMapArea(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map widget
        LocationMap(
          mapController: mapController,
          latitude: pinLatitude,
          longitude: pinLongitude,
          zoom: mapZoom,
          isFetching: isFetchingLocation,
          onCenterChanged: onCenterChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Small spacer to align with other content
            const SizedBox(width: 8),
            // Close map view (does not remove attached location unless parent implements that)
            TextButton(onPressed: onClose, child: const Text('Close')),
            const SizedBox(width: 8),
            // Remove persisted/attached location (distinct from Close)
            if (hasAttached)
              TextButton(onPressed: onRemove, child: const Text('Remove')),
            // Show a visible indicator if there is an unsaved (pending) selection.
            if (pendingLatitude != null && pendingLongitude != null)
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  'Pending selection',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: title + GPS button
        Row(
          children: [
            const Expanded(
              child: Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Tooltip(
              message: 'Tap to request location permission and center map',
              child: IconButton(
                icon: const Icon(Icons.gps_fixed),
                tooltip: 'Use current location',
                onPressed: onRequestLocation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Info box OR map area depending on showMap
        if (!showMap) _buildInfoBox(context) else _buildMapArea(context),
      ],
    );
  }
}
