import 'package:TaxiApp/src/core/models/driver_route_location.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:TaxiApp/src/core/widgets/hamba_map.dart';
import 'package:TaxiApp/src/core/services/osm_geocoding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class DriverLocationPickerScreen extends StatefulWidget {
  const DriverLocationPickerScreen({
    required this.title,
    required this.markerColor,
    this.initialLocation,
    super.key,
  });

  final String title;
  final Color markerColor;
  final DriverRouteLocation? initialLocation;

  @override
  State<DriverLocationPickerScreen> createState() =>
      _DriverLocationPickerScreenState();
}

class _DriverLocationPickerScreenState
    extends State<DriverLocationPickerScreen> {
  static const _fallback = LatLng(-25.7479, 28.2293);
  final OsmGeocodingService _geocoding = OsmGeocodingService();

  late LatLng _selectedPosition;
  String _selectedLabel = 'Tap the map to choose a location';
  bool _isResolvingAddress = false;
  int _selectionGeneration = 0;
  late bool _hasSelectedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final currentPosition = UserLocationProvider.create().userLocation.value;
    _selectedPosition =
        widget.initialLocation?.position ??
        (currentPosition == null
            ? _fallback
            : LatLng(currentPosition.latitude, currentPosition.longitude));
    _hasSelectedLocation = widget.initialLocation != null;
    if (widget.initialLocation != null) {
      _selectedLabel = widget.initialLocation!.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUserLocation =
        UserLocationProvider.create().userLocation.value != null;
    return Scaffold(
      appBar: HambaGoAppBar(
        title: widget.title,
        subtitle: 'Tap the map to choose a location',
        leadingIcon: Icons.close_rounded,
      ),
      body: Stack(
        children: [
          HambaMap(
            controller: _mapController,
            center: _selectedPosition,
            zoom: 15,
            onTap: _selectPosition,
            markers: [
              HambaMapMarker(
                position: _selectedPosition,
                label: 'Selected location',
                color: widget.markerColor,
              ),
            ],
            userLocation: hasUserLocation
                ? LatLng(
                    UserLocationProvider.create().userLocation.value!.latitude,
                    UserLocationProvider.create().userLocation.value!.longitude,
                  )
                : null,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(Dimensions.twelve),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.twelve,
                  vertical: Dimensions.eight,
                ),
                decoration: BoxDecoration(
                  color: Colours.primaryOne.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(Dimensions.eight),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tap the map to set the location',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(Dimensions.twelve),
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(Dimensions.twelve),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.twelve),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colours.blueThree,
                          ),
                          const SizedBox(width: Dimensions.eight),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected location',
                                  style: TextStyle(
                                    color: Colours.charcoalLight,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                _isResolvingAddress
                                    ? const LinearProgressIndicator(
                                        minHeight: 3,
                                      )
                                    : Text(
                                        _selectedLabel,
                                        style: const TextStyle(
                                          color: Colours.primaryOne,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          if (hasUserLocation)
                            IconButton(
                              onPressed: _moveToUser,
                              tooltip: 'My location',
                              icon: const Icon(Icons.my_location_rounded),
                              color: Colours.blueThree,
                            ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.twelve),
                      FilledButton.icon(
                        onPressed: _isResolvingAddress || !_hasSelectedLocation
                            ? null
                            : () => Get.back(
                                result: DriverRouteLocation(
                                  label: _selectedLabel,
                                  position: _selectedPosition,
                                ),
                              ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Use this location'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPosition(LatLng position) async {
    final generation = ++_selectionGeneration;
    setState(() {
      _selectedPosition = position;
      _isResolvingAddress = true;
      _hasSelectedLocation = true;
    });
    _mapController.move(position, _mapController.camera.zoom);

    String? place;
    try {
      place = await _geocoding.reverse(position);
    } catch (_) {
      // The selected coordinates can still be used if lookup fails.
    }
    if (!mounted || generation != _selectionGeneration) {
      return;
    }
    setState(() {
      _selectedLabel = place ?? _coordinateLabel(position);
      _isResolvingAddress = false;
    });
  }

  Future<void> _moveToUser() async {
    final position = UserLocationProvider.create().userLocation.value;
    if (position == null) {
      return;
    }
    await _selectPosition(LatLng(position.latitude, position.longitude));
  }

  String _coordinateLabel(LatLng position) =>
      '${position.latitude.toStringAsFixed(6)}, '
      '${position.longitude.toStringAsFixed(6)}';

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
