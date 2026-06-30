import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapMarkerData {
  final LatLng point;
  final bool highlighted;
  const MapMarkerData({required this.point, this.highlighted = false});
}

class ReusableMapCard extends StatefulWidget {
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
  State<ReusableMapCard> createState() => _ReusableMapCardState();
}

class _ReusableMapCardState extends State<ReusableMapCard> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.center;
  }

  @override
  void didUpdateWidget(covariant ReusableMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the parent updates the center prop, move the map to match
    if (oldWidget.center != widget.center) {
      _currentCenter = widget.center;
      try {
        _mapController.move(widget.center, _mapController.camera.zoom);
      } catch (_) {
        // MapController might not be ready yet on first frame
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.center,
                  initialZoom: widget.zoom,
                  interactionOptions: InteractionOptions(
                    flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
                  ),
                  onPositionChanged: (camera, hasGesture) {
                    if (widget.interactive && hasGesture && widget.onCenterChanged != null) {
                      _currentCenter = camera.center;
                      widget.onCenterChanged!(camera.center);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sewainaja.app',
                  ),
                  if (widget.radiusKm != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _currentCenter,
                          radius: widget.radiusKm! * 1000,
                          useRadiusInMeter: true,
                          color: const Color(0xFF2F6743).withValues(alpha: 0.18),
                          borderColor: const Color(0xFF012D1D),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: widget.markers
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
              if (widget.showCenterPin)
                const Center(
                  child: Icon(
                    Icons.place_rounded,
                    size: 36,
                    color: Color(0xFF012D1D),
                  ),
                ),
              if (widget.overlayLabel != null && widget.overlayLabel!.isNotEmpty)
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
                      widget.overlayLabel!,
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
      ),
    );
  }
}
