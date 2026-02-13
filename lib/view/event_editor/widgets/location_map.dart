import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;

/// Reusable location map used by the event editor. The map renders OSM raster
/// tiles, shows a center-fixed pin, and reports center changes via
/// [onCenterChanged]. Any selection should be considered editor-local; the
/// caller is responsible for persisting changes.
class LocationMap extends StatelessWidget {
  final fm.MapController mapController;
  final double latitude;
  final double longitude;
  final double zoom;
  final bool isFetching;
  final void Function(double latitude, double longitude) onCenterChanged;

  const LocationMap({
    super.key,
    required this.mapController,
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.isFetching,
    required this.onCenterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
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
            fm.FlutterMap(
              mapController: mapController,
              options: fm.MapOptions(
                initialCenter: ll.LatLng(latitude, longitude),
                initialZoom: zoom,
                onPositionChanged: (pos, hasGesture) {
                  final center = pos.center;
                  onCenterChanged(center.latitude, center.longitude);
                },
              ),
              children: [
                fm.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: fm.NetworkTileProvider(
                    headers: {
                      // Replace with a production UA per OSM tile usage policy.
                      'User-Agent': 'indulge/0.0.2-beta (you@yourdomain.com)',
                    },
                  ),
                ),
                fm.RichAttributionWidget(
                  attributions: [
                    fm.TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),

            // Center-fixed visual pin.
            const Positioned(
              top: (220 / 2) - 24,
              child: Icon(Icons.location_pin, size: 48, color: Colors.red),
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
