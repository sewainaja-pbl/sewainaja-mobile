import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapMarkerData {
  final LatLng point;
  final bool highlighted;
  const MapMarkerData({required this.point, this.highlighted = false});
}

class ReusableMapCard extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final double? radiusKm;
  final List<MapMarkerData> markers;
  final bool showCenterPin;
  final bool interactive;
  final ValueChanged<LatLng>? onCenterChanged;
  final String? overlayLabel;
  final double height;
  final BorderRadius? borderRadius;

  const ReusableMapCard({
    super.key,
    required this.center,
    this.zoom = 13,
    this.radiusKm,
    this.markers = const [],
    this.showCenterPin = false,
    this.interactive = false,
    this.onCenterChanged,
    this.overlayLabel,
    this.height = 160,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                interactionOptions: InteractionOptions(
                  flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
                onPositionChanged: (camera, hasGesture) {
                  if (interactive && hasGesture && onCenterChanged != null) {
                    onCenterChanged!(camera.center);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sewainaja.app',
                ),
                if (radiusKm != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: center,
                        radius: radiusKm! * 1000,
                        useRadiusInMeter: true,
                        color: const Color(0xFF2F6743).withValues(alpha: 0.18),
                        borderColor: const Color(0xFF012D1D),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: markers
                      .map(
                        (e) => Marker(
                          point: e.point,
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.location_on_rounded,
                            color: e.highlighted
                                ? const Color(0xFF012D1D)
                                : const Color(0xFF7B5804),
                            size: e.highlighted ? 34 : 30,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            if (showCenterPin)
              const Center(
                child: Icon(
                  Icons.place_rounded,
                  size: 36,
                  color: Color(0xFF012D1D),
                ),
              ),
            if (overlayLabel != null)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xCC012D1D),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    overlayLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

