import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class HambaMap extends StatelessWidget {
  const HambaMap({
    required this.controller,
    required this.center,
    required this.zoom,
    this.onTap,
    this.onReady,
    this.markers = const [],
    this.paths = const [],
    this.userLocation,
    this.showAttribution = true,
    super.key,
  });

  final MapController controller;
  final LatLng center;
  final double zoom;
  final void Function(LatLng)? onTap;
  final VoidCallback? onReady;
  final List<HambaMapMarker> markers;
  final List<HambaMapPath> paths;
  final LatLng? userLocation;
  final bool showAttribution;

  // Tone down the printed tile colors while keeping roads and labels legible.
  static const _baseMapFilter = ColorFilter.matrix(<double>[
    0.358, 0.423, 0.043, 0, 37, // Red
    0.126, 0.655, 0.043, 0, 41, // Green
    0.126, 0.423, 0.275, 0, 40, // Blue
    0, 0, 0, 1, 0, // Alpha
  ]);
  static final _walkingPattern = StrokePattern.dashed(segments: const [4, 7]);
  static final _pinAnchor = Marker.computePixelAlignment(
    width: 44,
    height: 46,
    left: 22,
    top: 42,
  );

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          backgroundColor: const Color(0xFFE7ECE8),
          onMapReady: onReady,
          onTap: (_, point) => onTap?.call(point),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          ColorFiltered(
            colorFilter: _baseMapFilter,
            child: TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hambago.taxiapp',
              maxNativeZoom: 19,
            ),
          ),
          if (paths.isNotEmpty)
            PolylineLayer(
              polylines: [
                for (final path in paths)
                  Polyline(
                    points: path.points,
                    color: path.color,
                    strokeWidth: path.width,
                    borderColor: Colors.white,
                    borderStrokeWidth: path.dashed ? 2 : 4,
                    pattern: path.dashed
                        ? _walkingPattern
                        : const StrokePattern.solid(),
                  ),
              ],
            ),
          if (markers.isNotEmpty || userLocation != null)
            MarkerLayer(
              markers: [
                for (final marker in markers)
                  Marker(
                    point: marker.position,
                    width: 44,
                    height: 46,
                    alignment: _pinAnchor,
                    rotate: true,
                    child: _MapPin(marker: marker),
                  ),
                if (userLocation != null)
                  Marker(
                    point: userLocation!,
                    width: 32,
                    height: 32,
                    child: const _UserLocationDot(),
                  ),
              ],
            ),
        ],
      ),
      if (showAttribution)
        const Positioned(right: 8, top: 64, child: OsmAttribution()),
    ],
  );
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.marker});

  final HambaMapMarker marker;

  @override
  Widget build(BuildContext context) => Semantics(
    label: marker.label,
    button: marker.onTap != null,
    child: GestureDetector(
      behavior: marker.onTap == null
          ? HitTestBehavior.deferToChild
          : HitTestBehavior.opaque,
      onTap: marker.onTap,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: marker.color,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const SizedBox(width: 3, height: 8),
            ),
          ),
          Positioned(
            bottom: 0,
            child: _PinDisc(color: marker.color, size: 8, borderWidth: 1.5),
          ),
          Positioned(
            bottom: 9,
            child: _PinDisc(
              color: marker.color,
              size: marker.compact ? 27 : 36,
              borderWidth: 2,
              elevation: marker.compact ? 1 : 3,
              child: Icon(
                marker.icon,
                size: marker.compact ? 16 : 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PinDisc extends StatelessWidget {
  const _PinDisc({
    required this.color,
    required this.size,
    required this.borderWidth,
    this.elevation = 0,
    this.child,
  });

  final Color color;
  final double size;
  final double borderWidth;
  final double elevation;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    elevation: elevation,
    shadowColor: Colours.primaryOne.withValues(alpha: .45),
    shape: CircleBorder(
      side: BorderSide(color: Colors.white, width: borderWidth),
    ),
    child: SizedBox.square(
      dimension: size,
      child: Center(child: child),
    ),
  );
}

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  static const _locationBlue = Color(0xFF1465C0);

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Your location',
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _locationBlue.withValues(alpha: .17),
        border: Border.all(color: _locationBlue.withValues(alpha: .34)),
      ),
      child: const Center(
        child: _PinDisc(color: _locationBlue, size: 17, borderWidth: 2.5),
      ),
    ),
  );
}

class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .92),
    borderRadius: BorderRadius.circular(4),
    child: InkWell(
      onTap: () =>
          launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(color: Color(0xFF25363A), fontSize: 10),
        ),
      ),
    ),
  );
}

class HambaMapMarker {
  const HambaMapMarker({
    required this.position,
    required this.label,
    this.color = Colours.red,
    this.icon = Icons.place_rounded,
    this.compact = false,
    this.onTap,
  });
  final LatLng position;
  final String label;
  final Color color;
  final IconData icon;
  final bool compact;
  final VoidCallback? onTap;
}

class HambaMapPath {
  const HambaMapPath({
    required this.points,
    required this.color,
    this.width = 5,
    this.dashed = false,
  });
  final List<LatLng> points;
  final Color color;
  final double width;
  final bool dashed;
}
