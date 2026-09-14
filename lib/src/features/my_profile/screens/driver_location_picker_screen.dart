import 'package:TaxiApp/src/core/models/driver_route_location.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverLocationPickerScreen extends StatefulWidget {
  const DriverLocationPickerScreen({
    required this.title,
    required this.markerHue,
    this.initialLocation,
    super.key,
  });

  final String title;
  final double markerHue;
  final DriverRouteLocation? initialLocation;

  @override
  State<DriverLocationPickerScreen> createState() =>
      _DriverLocationPickerScreenState();
}

class _DriverLocationPickerScreenState
    extends State<DriverLocationPickerScreen> {
  static const _fallback = LatLng(-25.7479, 28.2293);
  final Geocoding _geocoding = Geocoding();

  late LatLng _selectedPosition;
  String _selectedLabel = 'Tap the map to choose a location';
  bool _isResolvingAddress = false;
  late bool _hasSelectedLocation;
  GoogleMapController? _mapController;

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
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colours.primaryOne,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _selectPosition,
            myLocationEnabled: hasUserLocation,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('driver_route_location'),
                position: _selectedPosition,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(widget.markerHue),
                onDragEnd: _selectPosition,
              ),
            },
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
                        'Tap the map or drag the pin to set the location',
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
    setState(() {
      _selectedPosition = position;
      _isResolvingAddress = true;
      _hasSelectedLocation = true;
    });
    await _mapController?.animateCamera(CameraUpdate.newLatLng(position));

    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedLabel = placemarks.isEmpty
            ? _coordinateLabel(position)
            : _placemarkLabel(placemarks.first, position);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _selectedLabel = _coordinateLabel(position));
      }
    } finally {
      if (mounted) {
        setState(() => _isResolvingAddress = false);
      }
    }
  }

  Future<void> _moveToUser() async {
    final position = UserLocationProvider.create().userLocation.value;
    if (position == null) {
      return;
    }
    await _selectPosition(LatLng(position.latitude, position.longitude));
  }

  String _placemarkLabel(Placemark place, LatLng fallback) {
    final components =
        [place.name, place.street, place.subLocality, place.locality]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false);
    return components.isEmpty
        ? _coordinateLabel(fallback)
        : components.join(', ');
  }

  String _coordinateLabel(LatLng position) =>
      '${position.latitude.toStringAsFixed(6)}, '
      '${position.longitude.toStringAsFixed(6)}';

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
