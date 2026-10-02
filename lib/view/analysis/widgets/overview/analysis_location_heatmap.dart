import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:indulge/data/models.dart';

// ── Web Mercator tile-coordinate helpers ──────────────────────────────────────

double _tileX(double lng, double zoom) {
  final n = math.pow(2.0, zoom).toDouble();
  return (lng + 180.0) / 360.0 * n;
}

double _tileY(double lat, double zoom) {
  final n = math.pow(2.0, zoom).toDouble();
  final latRad = lat * math.pi / 180.0;
  return (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
      2.0 *
      n;
}

/// Clustering radius in tile units.  0.5 tiles ≈ 128 px on a 256 px tile grid.
const double _kClusterRadius = 0.5;

/// Duration of the cross-fade animation when clusters change.
const Duration _kAnimDuration = Duration(milliseconds: 400);

// ── Data model ────────────────────────────────────────────────────────────────

class _HeatCell {
  final int count;
  final ll.LatLng center;

  const _HeatCell({required this.count, required this.center});
}

/// A cell that is mid-transition.  Carries both the "from" and "to" state so
/// the builder can interpolate between them for the current animation progress.
class _AnimCell {
  /// Geographic position — tweened from [fromCenter] to [toCenter].
  final ll.LatLng fromCenter;
  final ll.LatLng toCenter;

  /// Count — tweened from [fromCount] to [toCount].
  final int fromCount;
  final int toCount;

  /// Opacity multiplier — 0 → 1 for entering cells, 1 → 0 for leaving cells,
  /// 1 → 1 for persisting cells.
  final double fromOpacity;
  final double toOpacity;

  const _AnimCell({
    required this.fromCenter,
    required this.toCenter,
    required this.fromCount,
    required this.toCount,
    required this.fromOpacity,
    required this.toOpacity,
  });

  ll.LatLng lerpCenter(double t) => ll.LatLng(
    _lerp(fromCenter.latitude, toCenter.latitude, t),
    _lerp(fromCenter.longitude, toCenter.longitude, t),
  );

  int lerpCount(double t) =>
      _lerp(fromCount.toDouble(), toCount.toDouble(), t).round();

  double lerpOpacity(double t) =>
      _lerp(fromOpacity, toOpacity, t).clamp(0.0, 1.0);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Displays a density heatmap of [locations] on a flutter_map tile map.
///
/// Clustering is zoom-adaptive: points are bucketed by Web Mercator tile
/// coordinates so the same ~128 px pixel radius applies at every zoom level.
/// When the cluster layout changes (on [MapEventMoveEnd]) the transition is
/// animated — new clusters scale in, removed clusters scale out, and surviving
/// clusters smoothly move and resize.
class AnalysisLocationHeatmap extends StatefulWidget {
  final List<Location> locations;
  final double height;
  final double initialZoom;

  const AnalysisLocationHeatmap({
    super.key,
    required this.locations,
    this.height = 260,
    this.initialZoom = 2.0,
  });

  @override
  State<AnalysisLocationHeatmap> createState() =>
      _AnalysisLocationHeatmapState();
}

class _AnalysisLocationHeatmapState extends State<AnalysisLocationHeatmap>
    with SingleTickerProviderStateMixin {
  late final fm.MapController _mapController;
  late final AnimationController _animController;
  late final Animation<double> _anim;

  /// The cluster set currently being transitioned FROM.
  List<_HeatCell> _fromCells = [];

  /// The cluster set currently being transitioned TO (the "target" layout).
  List<_HeatCell> _toCells = [];

  /// Pre-built list of per-cell animation descriptors for the active transition.
  List<_AnimCell> _animCells = [];

  double _currentZoom = 2.0;

  // ── Max count across _toCells for colour normalisation ────────────────────
  int _maxCount = 1;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialZoom;
    _mapController = fm.MapController();

    _animController = AnimationController(
      vsync: this,
      duration: _kAnimDuration,
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    // Compute initial cells with no animation (jump straight to end state).
    final initial = _computeCells(_currentZoom);
    _fromCells = initial;
    _toCells = initial;
    _animCells = _buildAnimCells(_fromCells, _toCells);
    _maxCount = _toCells.fold(1, (m, c) => math.max(m, c.count));
    _animController.value = 1.0; // start fully at end state
  }

  @override
  void didUpdateWidget(covariant AnalysisLocationHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      _transitionTo(_computeCells(_currentZoom));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Map events ─────────────────────────────────────────────────────────────

  void _onMapEvent(fm.MapEvent event) {
    if (event is fm.MapEventMoveEnd) {
      _currentZoom = _mapController.camera.zoom;
      _transitionTo(_computeCells(_currentZoom));
    }
  }

  // ── Clustering ─────────────────────────────────────────────────────────────

  List<_HeatCell> _computeCells(double zoom) {
    final locs = widget.locations.where((l) {
      return l.latitude.isFinite &&
          l.longitude.isFinite &&
          l.latitude.abs() <= 90 &&
          l.longitude.abs() <= 180;
    }).toList();

    if (locs.isEmpty) return [];

    final Map<String, List<Location>> buckets = {};
    for (final l in locs) {
      final tx = _tileX(l.longitude, zoom);
      final ty = _tileY(l.latitude, zoom);
      final bx = (tx / _kClusterRadius).floor();
      final by = (ty / _kClusterRadius).floor();
      final key = '$bx:$by';
      buckets.putIfAbsent(key, () => []).add(l);
    }

    return buckets.values.map((pts) {
      final avgLat =
          pts.map((l) => l.latitude).fold(0.0, (a, b) => a + b) / pts.length;
      final avgLng =
          pts.map((l) => l.longitude).fold(0.0, (a, b) => a + b) / pts.length;
      return _HeatCell(count: pts.length, center: ll.LatLng(avgLat, avgLng));
    }).toList();
  }

  // ── Animation helpers ──────────────────────────────────────────────────────

  /// Start a transition from the last fully-computed target to [next].
  void _transitionTo(List<_HeatCell> next) {
    if (!mounted) return;

    // Always transition from _toCells — the last clean, fully-computed cluster
    // set.  Snapshotting mid-animation interpolated cells produces one phantom
    // cell per _AnimCell entry (including fading-out ghosts), which then all
    // get re-matched in _buildAnimCells and explode into a large number of
    // spurious clusters before recombining.
    _animController.stop();

    setState(() {
      _fromCells = _toCells;
      _toCells = next;
      _animCells = _buildAnimCells(_fromCells, _toCells);
      _maxCount = next.fold(1, (m, c) => math.max(m, c.count));
    });

    _animController.forward(from: 0);
  }

  /// Pair up old and new cells so each gets a smooth tween partner.
  ///
  /// Strategy:
  /// - For each new cell, find the nearest old cell (by geographic distance)
  ///   that hasn't been claimed yet.  This cell will tween FROM the old
  ///   position/count TO the new one with full opacity on both ends.
  /// - Remaining old cells (no partner in new set) fade out in place.
  /// - New cells that couldn't be matched (new set larger) fade in from the
  ///   nearest surviving old cell's position.
  List<_AnimCell> _buildAnimCells(List<_HeatCell> from, List<_HeatCell> to) {
    if (from.isEmpty && to.isEmpty) return [];

    // ── Greedy nearest-neighbour matching ─────────────────────────────────
    final unmatched = List<_HeatCell>.of(from);
    final paired = <({_HeatCell from, _HeatCell to})>[];
    final unpairedTo = <_HeatCell>[];

    for (final toCell in to) {
      if (unmatched.isEmpty) {
        unpairedTo.add(toCell);
        continue;
      }
      // Pick the closest unmatched old cell.
      int bestIdx = 0;
      double bestDist = _geoDist(unmatched[0].center, toCell.center);
      for (var i = 1; i < unmatched.length; i++) {
        final d = _geoDist(unmatched[i].center, toCell.center);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      paired.add((from: unmatched.removeAt(bestIdx), to: toCell));
    }

    final result = <_AnimCell>[];

    // Cells with a match: tween position, count, full opacity.
    for (final p in paired) {
      result.add(
        _AnimCell(
          fromCenter: p.from.center,
          toCenter: p.to.center,
          fromCount: p.from.count,
          toCount: p.to.count,
          fromOpacity: 1.0,
          toOpacity: 1.0,
        ),
      );
    }

    // Old cells with no match: fade out in place.
    for (final old in unmatched) {
      result.add(
        _AnimCell(
          fromCenter: old.center,
          toCenter: old.center,
          fromCount: old.count,
          toCount: old.count,
          fromOpacity: 1.0,
          toOpacity: 0.0,
        ),
      );
    }

    // New cells with no old partner: find closest surviving "to" cell to spawn
    // from, or use own position if no match available.
    for (final newCell in unpairedTo) {
      ll.LatLng spawnFrom = newCell.center;
      if (paired.isNotEmpty) {
        // Spawn from the closest matched destination cell.
        _HeatCell? closest;
        double bestDist = double.infinity;
        for (final p in paired) {
          final d = _geoDist(p.to.center, newCell.center);
          if (d < bestDist) {
            bestDist = d;
            closest = p.to;
          }
        }
        if (closest != null) spawnFrom = closest.center;
      }
      result.add(
        _AnimCell(
          fromCenter: spawnFrom,
          toCenter: newCell.center,
          fromCount: 0,
          toCount: newCell.count,
          fromOpacity: 0.0,
          toOpacity: 1.0,
        ),
      );
    }

    return result;
  }

  static double _geoDist(ll.LatLng a, ll.LatLng b) {
    final dlat = a.latitude - b.latitude;
    final dlng = a.longitude - b.longitude;
    return dlat * dlat + dlng * dlng; // squared — only used for comparison
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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

    // Map centre (average of all locations — fixed, not animated).
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
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

          // ── Map ───────────────────────────────────────────────────────
          SizedBox(
            height: widget.height,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4.0),
              ),
              child: fm.FlutterMap(
                mapController: _mapController,
                options: fm.MapOptions(
                  initialCenter: center,
                  initialZoom: widget.initialZoom,
                  onMapEvent: _onMapEvent,
                ),
                children: [
                  fm.TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'indulge/0.3.0-beta',
                  ),

                  // Animated cluster layer — rebuilds on every anim tick.
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (context, _) {
                      final t = _anim.value;
                      final circles = <fm.CircleMarker>[];
                      final labels = <fm.Marker>[];

                      for (final ac in _animCells) {
                        final opacity = ac.lerpOpacity(t);
                        if (opacity <= 0.0) continue;

                        final count = ac.lerpCount(t);
                        final pos = ac.lerpCenter(t);

                        final norm = (count / _maxCount)
                            .clamp(0.0, 1.0)
                            .toDouble();
                        final color =
                            Color.lerp(
                              Colors.purple.shade200,
                              Colors.purple.shade900,
                              _easeInOut(norm),
                            ) ??
                            Colors.purple;

                        final base = math.max(
                          14.0,
                          6.0 + math.sqrt(count.toDouble()) * 2.2,
                        );

                        const radiiMult = [0.8, 1.3, 1.9, 2.6];
                        const baseOpacities = [0.90, 0.45, 0.20, 0.08];

                        for (var k = 0; k < radiiMult.length; k++) {
                          final r = base * radiiMult[k];
                          final o = (baseOpacities[k] * opacity).clamp(
                            0.0,
                            1.0,
                          );
                          circles.add(
                            fm.CircleMarker(
                              point: pos,
                              radius: r,
                              useRadiusInMeter: false,
                              color: color.withOpacity(o),
                              borderColor: k == 0
                                  ? Colors.white.withOpacity(0.06 * opacity)
                                  : Colors.transparent,
                              borderStrokeWidth: k == 0 ? 0.6 : 0,
                            ),
                          );
                        }

                        // Count label
                        final diameter = (base * 0.8 * 2).clamp(28.0, 64.0);
                        final fontSize = count >= 100
                            ? 9.0
                            : count >= 10
                            ? 11.0
                            : 13.0;
                        labels.add(
                          fm.Marker(
                            point: pos,
                            width: diameter,
                            height: diameter,
                            child: Opacity(
                              opacity: opacity,
                              child: Center(
                                child: Text(
                                  count > 0 ? '$count' : '',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Stack(
                        children: [
                          if (circles.isNotEmpty)
                            fm.CircleLayer(circles: circles),
                          if (labels.isNotEmpty)
                            fm.MarkerLayer(markers: labels),
                        ],
                      );
                    },
                  ),

                  fm.RichAttributionWidget(
                    attributions: [
                      fm.TextSourceAttribution('OpenStreetMap', onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Legend ────────────────────────────────────────────────────
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
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    return Text(
                      'Max: $_maxCount',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
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

// ── Gradient legend bar ───────────────────────────────────────────────────────

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
