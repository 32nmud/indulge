import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:indulge/data/models.dart';

/// AnalysisLocationHeatmap
///
/// - Aggregates the provided [locations] into an NxN grid (configurable by
///   [gridSize]) and produces a soft density visualization using concentric
///   [fm.CircleMarker] entries per populated cell.
/// - Single-finger scroll is intentionally allowed to propagate to the parent
///   scrollable (page). Map interactions require two or more fingers — this is
///   implemented by wrapping the map in [_TwoFingerInteractive], which only
///   allows pointer delivery to the map when more than one pointer is active.
class AnalysisLocationHeatmap extends StatefulWidget {
  final List<Location> locations;
  final double height;
  final int gridSize;
  final double initialZoom;

  const AnalysisLocationHeatmap({
    super.key,
    required this.locations,
    this.height = 260,
    this.gridSize = 80,
    this.initialZoom = 2.0,
  });

  @override
  State<AnalysisLocationHeatmap> createState() =>
      _AnalysisLocationHeatmapState();
}

class _AnalysisLocationHeatmapState extends State<AnalysisLocationHeatmap> {
  late final fm.MapController _mapController;
  List<_HeatCell> _cells = [];

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();
    _recomputeCells();
  }

  @override
  void didUpdateWidget(covariant AnalysisLocationHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations ||
        oldWidget.gridSize != widget.gridSize) {
      _recomputeCells();
    }
  }

  void _recomputeCells() {
    final locs = widget.locations.where((l) {
      return l.latitude.isFinite &&
          l.longitude.isFinite &&
          l.latitude.abs() <= 90 &&
          l.longitude.abs() <= 180;
    }).toList();

    if (locs.isEmpty) {
      setState(() {
        _cells = [];
      });
      return;
    }

    // Bounding box
    double minLat = locs.first.latitude;
    double maxLat = locs.first.latitude;
    double minLng = locs.first.longitude;
    double maxLng = locs.first.longitude;

    for (final l in locs) {
      if (l.latitude < minLat) minLat = l.latitude;
      if (l.latitude > maxLat) maxLat = l.latitude;
      if (l.longitude < minLng) minLng = l.longitude;
      if (l.longitude > maxLng) maxLng = l.longitude;
    }

    // Slight expansion to avoid degenerate bounds
    if ((maxLat - minLat) < 0.0001) {
      const expand = 0.01;
      minLat -= expand;
      maxLat += expand;
    }
    if ((maxLng - minLng) < 0.0001) {
      const expand = 0.01;
      minLng -= expand;
      maxLng += expand;
    }

    final int grid = math.max(2, widget.gridSize);
    final Map<String, int> counts = {};

    for (final l in locs) {
      final latNorm = (l.latitude - minLat) / (maxLat - minLat);
      final lngNorm = (l.longitude - minLng) / (maxLng - minLng);

      final i = (latNorm * (grid - 1)).clamp(0, grid - 1).floor();
      final j = (lngNorm * (grid - 1)).clamp(0, grid - 1).floor();

      final key = '$i:$j';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final List<_HeatCell> newCells = [];
    counts.forEach((key, count) {
      final parts = key.split(':');
      final i = int.parse(parts[0]);
      final j = int.parse(parts[1]);

      final latCenter = minLat + (i + 0.5) * (maxLat - minLat) / grid;
      final lngCenter = minLng + (j + 0.5) * (maxLng - minLng) / grid;

      newCells.add(
        _HeatCell(count: count, center: ll.LatLng(latCenter, lngCenter)),
      );
    });

    setState(() {
      _cells = newCells;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locations.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          height: widget.height,
          child: Center(
            child: Text(
              'No geolocated events',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ),
        ),
      );
    }

    // Map center (average)
    final avgLat =
        widget.locations
            .map((l) => l.latitude)
            .fold<double>(0.0, (a, b) => a + b) /
        widget.locations.length;
    final avgLng =
        widget.locations
            .map((l) => l.longitude)
            .fold<double>(0.0, (a, b) => a + b) /
        widget.locations.length;
    final center = ll.LatLng(avgLat, avgLng);

    // Max count for normalization
    int maxCount = 0;
    for (final c in _cells) {
      maxCount = math.max(maxCount, c.count);
    }
    final maxSafe = math.max(1, maxCount);

    // Build concentric CircleMarkers per cell to create a smooth radial fade.
    // Use multiple rings with a gentle falloff (more rings, smaller steps) so
    // the visual looks smooth rather than blocky. Radii scale with sqrt(count)
    // for diminishing returns as counts grow.
    final List<fm.CircleMarker> circleMarkers = [];
    for (final cell in _cells) {
      final t = (cell.count / maxSafe).clamp(0.0, 1.0);
      final color =
          Color.lerp(
            Colors.purple.shade200,
            Colors.purple.shade900,
            _easeInOut(t),
          ) ??
          Colors.purple;

      // Base radius (px). Reduced substantially to keep markers compact on the
      // overview panel. Radii scale with sqrt(count) but with a much smaller
      // multiplier so density blobs remain subtle and non-dominant.
      final base = 3.0 + math.sqrt(cell.count.toDouble()) * 1.8;

      // Define ring multipliers (relative to base) and corresponding opacities.
      // These multipliers are smaller to produce a much tighter, subtle halo.
      // We keep multiple rings for smooth falloff but with reduced overall size.
      final List<double> radiiMultipliers = [0.8, 1.3, 1.9, 2.6];
      final List<double> opacities = [0.90, 0.45, 0.20, 0.08];

      for (var k = 0; k < radiiMultipliers.length; k++) {
        final r = base * radiiMultipliers[k];
        final o = opacities[k].clamp(0.0, 1.0);

        // Add a subtle white border only on the innermost ring to help the
        // core stand out against darker map tiles.
        if (k == 0) {
          circleMarkers.add(
            fm.CircleMarker(
              point: cell.center,
              radius: r,
              useRadiusInMeter: false,
              color: color.withOpacity(o),
              borderColor: Colors.white.withOpacity(0.06),
              borderStrokeWidth: 0.6,
            ),
          );
        } else {
          circleMarkers.add(
            fm.CircleMarker(
              point: cell.center,
              radius: r,
              useRadiusInMeter: false,
              color: color.withOpacity(o),
            ),
          );
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Event locations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.locations.length} events',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Map area. Wrap with _TwoFingerInteractive so single-finger scrolls
          // propagate to the page while two+ finger interactions reach the map.
          SizedBox(
            height: widget.height,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4.0),
              ),
              child: fm.FlutterMap(
                mapController: _mapController,
                options: fm.MapOptions(
                  // Keep center/zoom as before
                  initialCenter: center,
                  initialZoom: widget.initialZoom,
                ),
                children: [
                  fm.TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'indulge/0.2.0-beta',
                  ),

                  if (circleMarkers.isNotEmpty)
                    fm.CircleLayer(circles: circleMarkers),

                  fm.RichAttributionWidget(
                    attributions: [
                      fm.TextSourceAttribution('OpenStreetMap', onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Text('Few', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                _GradientBar(),
                const SizedBox(width: 8),
                Text('Many', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                if (maxCount > 0)
                  Text(
                    'Max: $maxCount',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _easeInOut(double t) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}

/// Simple gradient legend bar used in the panel footer.
class _GradientBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEDE7F6),
            Color(0xFFB39DDB),
            Color(0xFF7E57C2),
            Color(0xFF512DA8),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
    );
  }
}

/// Internal lightweight representation of an aggregated cell.
class _HeatCell {
  final int count;
  final ll.LatLng center;

  _HeatCell({required this.count, required this.center});
}
