import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/extensions/rx_worker.dart';
import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:TaxiApp/src/core/services/taxi_routing_service.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActionsProvider extends GetxController with RxWorkerMixin {
  static ActionsProvider create() => Get.isRegistered<ActionsProvider>()
      ? Get.find<ActionsProvider>()
      : Get.put<ActionsProvider>(ActionsProvider());

  final Rxn<ActionType> selectedAction = Rxn<ActionType>();
  final Rxn<DestinationSearchResult> selectedDestination =
      Rxn<DestinationSearchResult>();
  final Rxn<TaxiJourney> journey = Rxn<TaxiJourney>();
  final RxBool isPlanningJourney = false.obs;
  final RxnString journeyError = RxnString();

  /// Route Selection
  final Rxn<NearbyTaxiRouteModel> selectedRoute = Rxn<NearbyTaxiRouteModel>();
  void setSelectedRoute(NearbyTaxiRouteModel route) {
    _clearJourneyState();
    selectedRoute.value = route;
    selectedAction.value = ActionType.selectedLocation;
    final MapsProvider mapsProvider = MapsProvider.create();
    mapsProvider.updateMarkers();
  }

  void clearSelectedRoute() {
    selectedRoute.value = null;
    selectedAction.value = null;
    final MapsProvider mapsProvider = MapsProvider.create();
    mapsProvider.updateMarkers();
  }

  void viewRoute(NearbyTaxiRouteModel route) {
    _clearJourneyState();
    selectedRoute.value = route;
    selectedAction.value = ActionType.viewRoute;
    final MapsProvider mapsProvider = MapsProvider.create();
    mapsProvider.updateMarkers();
  }

  Future<void> planJourney(DestinationSearchResult destination) async {
    final mapsProvider = MapsProvider.create();
    selectedRoute.value = null;
    selectedDestination.value = destination;
    journey.value = null;
    journeyError.value = null;
    selectedAction.value = ActionType.planningJourney;
    isPlanningJourney.value = true;
    await mapsProvider.updateMarkers();

    try {
      final locationProvider = UserLocationProvider.create();
      final position =
          locationProvider.userLocation.value ??
          await locationProvider.refreshLocation(requestPermission: true);
      if (position == null) {
        journeyError.value =
            locationProvider.errorMessage.value ??
            'Your current location is required to plan a journey.';
        return;
      }

      final taxiRoutesProvider = TaxiRoutesProvider.create();
      if (taxiRoutesProvider.taxiRoutes.isEmpty) {
        await taxiRoutesProvider.loadRoutes();
      }
      if (taxiRoutesProvider.taxiRoutes.isEmpty) {
        journeyError.value =
            taxiRoutesProvider.errorMessage.value ??
            'Taxi routes are not available right now.';
        return;
      }

      final plannedJourney = const TaxiRoutingService().findBestJourney(
        origin: LatLng(position.latitude, position.longitude),
        destination: destination,
        routes: taxiRoutesProvider.taxiRoutes,
      );
      if (plannedJourney == null) {
        journeyError.value =
            'No direct taxi journey was found within a 5 km walk of both '
            'your location and the destination.';
        return;
      }

      journey.value = plannedJourney;
      selectedAction.value = ActionType.journeyReady;
    } catch (_) {
      journeyError.value = 'Unable to plan this journey. Please try again.';
    } finally {
      isPlanningJourney.value = false;
      await mapsProvider.updateMarkers();
    }
  }

  void startJourney() {
    if (journey.value == null) {
      return;
    }
    selectedAction.value = ActionType.journeyStarted;
    MapsProvider.create().updateMarkers();
  }

  void clearJourney() {
    _clearJourneyState();
    selectedAction.value = null;
    MapsProvider.create().updateMarkers();
  }

  void _clearJourneyState() {
    selectedDestination.value = null;
    journey.value = null;
    journeyError.value = null;
    isPlanningJourney.value = false;
  }
}
