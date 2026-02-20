import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;

/// Reusable location map used by the event editor. The map renders OSM raster
/// tiles, shows a center-fixed pin, and reports center changes via
/// [onCenterChanged]. Any selection should be considered editor-local; the
/// caller is responsible for persisting changes.
///
/// This widget now accepts `height` to control the map height and `pinSize` to
/// control the visual size of the center pin so it can be used as a smaller
/// preview map inside cards.
class LocationMap extends StatelessWidget {
  final fm.MapController mapController;
  final double latitude;
  final double longitude;
  final double zoom;
  final bool isFetching;
  final bool interactive;
  final double height;
  final double pinSize;
  final Color? pinColor;
  final void Function(double latitude, double longitude) onCenterChanged;

  const LocationMap({
    super.key,
    required this.mapController,
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.isFetching,
    required this.onCenterChanged,
    this.interactive = true,
    this.height = 220,
    this.pinSize = 48,
    this.pinColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              ignoring: !interactive,
              child: fm.FlutterMap(
                mapController: mapController,
                options: fm.MapOptions(
                  initialCenter: ll.LatLng(latitude, longitude),
                  initialZoom: zoom,
                  onPositionChanged: (pos, hasGesture) {
                    final center = pos.center;
                    if (interactive) {
                      onCenterChanged(center.latitude, center.longitude);
                    }
                  },
                ),
                children: [
                  fm.TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'indlu/0.2.0-beta',
                  ),
                  fm.RichAttributionWidget(
                    attributions: [
                      fm.TextSourceAttribution('OpenStreetMap', onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),

            // Center-fixed visual pin.
            Positioned(
              top: (height / 2) - (pinSize / 2),
              child: Icon(
                Icons.location_pin,
                size: pinSize,
                color: pinColor ?? Theme.of(context).colorScheme.tertiary,
              ),
            ),

            // Full-map semi-transparent progress overlay while fetching location.
            if (isFetching)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
