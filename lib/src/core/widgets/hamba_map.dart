import 'dart:async';
import 'dart:math' as math;

import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart'
    as vector;
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
    this.routeBadges = const [],
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
  final List<HambaMapRouteBadge> routeBadges;
  final LatLng? userLocation;
  final bool showAttribution;

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
          backgroundColor: const Color(0xFFF7F9F8),
          onMapReady: onReady,
          onTap: (_, point) => onTap?.call(point),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          const _HambaBasemap(),
          if (paths.isNotEmpty)
            PolylineLayer(
              polylines: [
                for (final path in paths)
                  Polyline(
                    points: path.points,
                    color: path.color,
                    strokeWidth: path.width,
                    borderColor: path.borderColor,
                    borderStrokeWidth:
                        path.borderWidth ?? (path.dashed ? 2 : 4),
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
          if (routeBadges.isNotEmpty)
            MarkerLayer(
              markers: [
                for (final badge in routeBadges)
                  Marker(
                    point: badge.position,
                    width: 122,
                    height: 63,
                    alignment: badge.aboveRoute
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
                    rotate: true,
                    child: _MapRouteCallout(badge: badge),
                  ),
              ],
            ),
        ],
      ),
      if (showAttribution)
        const Positioned(
          left: 8,
          right: 8,
          top: 64,
          child: Align(
            alignment: Alignment.centerRight,
            child: OsmAttribution(includeVectorCredits: true),
          ),
        ),
    ],
  );
}

class _MapRouteCallout extends StatelessWidget {
  const _MapRouteCallout({required this.badge});

  final HambaMapRouteBadge badge;

  @override
  Widget build(BuildContext context) {
    final selected = badge.selected;
    final background = selected ? Colours.journeyPurple : Colors.white;
    final foreground = selected ? Colors.white : const Color(0xFF44296E);
    final border = selected ? Colours.journeyPurple : const Color(0xFFD6C6EA);
    return Align(
      alignment: badge.aboveRoute
          ? Alignment.bottomCenter
          : Alignment.topCenter,
      child: Semantics(
        button: true,
        selected: selected,
        label:
            'Route ${badge.optionNumber}, about ${badge.minutes} minutes'
            '${badge.recommended ? ', recommended' : ''}',
        excludeSemantics: true,
        onTap: badge.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: badge.aboveRoute ? null : 2,
              bottom: badge.aboveRoute ? 2 : null,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: background,
                    border: Border.all(color: border),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: badge.aboveRoute ? 0 : 6,
                bottom: badge.aboveRoute ? 6 : 0,
              ),
              child: Material(
                color: background,
                elevation: selected ? 4 : 2,
                shadowColor: const Color(0xFF4A2E6D).withValues(alpha: .36),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: border),
                  borderRadius: BorderRadius.circular(13),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: badge.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '≈ ${badge.minutes} min',
                          style: TextStyle(
                            color: foreground,
                            fontSize: selected ? 16 : 14,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        if (selected)
                          Text(
                            badge.recommended ? 'Recommended' : 'Selected',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                      ],
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

class _HambaBasemap extends StatefulWidget {
  const _HambaBasemap();

  @override
  State<_HambaBasemap> createState() => _HambaBasemapState();
}

class _HambaBasemapState extends State<_HambaBasemap> {
  static const _rasterFilter = ColorFilter.matrix(<double>[
    0.358, 0.423, 0.043, 0, 37, // Red
    0.126, 0.655, 0.043, 0, 41, // Green
    0.126, 0.423, 0.275, 0, 40, // Blue
    0, 0, 0, 1, 0, // Alpha
  ]);

  vector.Style? _style;
  Timer? _fallbackTimer;
  bool _showRaster = false;

  @override
  void initState() {
    super.initState();
    _fallbackTimer = Timer(const Duration(seconds: 4), _showRasterMap);
    unawaited(_loadStyle());
  }

  Future<void> _loadStyle() async {
    try {
      final style = await const vector.StyleReader(
        uri: 'asset://assets/map/hambago-streets.json',
      ).read();
      if (!mounted || style.providers.providers.isEmpty) {
        style.dispose();
        _showRasterMap();
        return;
      }
      setState(() => _style = style);
    } catch (_) {
      _showRasterMap();
    } finally {
      _fallbackTimer?.cancel();
    }
  }

  void _showRasterMap() {
    if (mounted && !_showRaster) {
      setState(() => _showRaster = true);
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _style?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    if (style != null) {
      return vector.VectorTileLayer(
        theme: style.theme,
        tileProviders: style.providers,
        glyphs: style.glyphs,
        tileOffset: vector.TileOffset.none,
      );
    }
    if (_showRaster) {
      return ColorFiltered(
        colorFilter: _rasterFilter,
        child: TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hambago.taxiapp',
          maxNativeZoom: 19,
        ),
      );
    }
    return const SizedBox.shrink();
  }
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
  const OsmAttribution({this.includeVectorCredits = false, super.key});

  final bool includeVectorCredits;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .92),
    borderRadius: BorderRadius.circular(4),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        alignment: WrapAlignment.end,
        children: [
          _credit(
            '© OpenStreetMap contributors',
            'https://www.openstreetmap.org/copyright',
          ),
          if (includeVectorCredits) ...[
            _credit('OpenFreeMap', 'https://openfreemap.org'),
            _credit('© OpenMapTiles', 'https://openmaptiles.org'),
          ],
        ],
      ),
    ),
  );

  Widget _credit(String label, String url) => InkWell(
    onTap: () => launchUrl(Uri.parse(url)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF25363A), fontSize: 10),
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
    this.borderColor = Colors.white,
    this.borderWidth,
  });
  final List<LatLng> points;
  final Color color;
  final double width;
  final bool dashed;
  final Color borderColor;
  final double? borderWidth;
}

class HambaMapRouteBadge {
  const HambaMapRouteBadge({
    required this.position,
    required this.minutes,
    required this.optionNumber,
    required this.selected,
    required this.recommended,
    required this.aboveRoute,
    required this.onTap,
  });

  final LatLng position;
  final int minutes;
  final int optionNumber;
  final bool selected;
  final bool recommended;
  final bool aboveRoute;
  final VoidCallback onTap;
}
