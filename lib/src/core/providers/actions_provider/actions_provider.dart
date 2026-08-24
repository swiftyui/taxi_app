import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/extensions/rx_worker.dart';
import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:get/get.dart';

class ActionsProvider extends GetxController with RxWorkerMixin {
  static ActionsProvider create() => Get.isRegistered<ActionsProvider>()
      ? Get.find<ActionsProvider>()
      : Get.put<ActionsProvider>(ActionsProvider());

  final Rxn<ActionType> selectedAction = Rxn<ActionType>();

  /// Route Selection
  final Rxn<NearbyTaxiRouteModel> selectedRoute = Rxn<NearbyTaxiRouteModel>();
  void setSelectedRoute(NearbyTaxiRouteModel route) {
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
    selectedRoute.value = route;
    selectedAction.value = ActionType.viewRoute;
    final MapsProvider mapsProvider = MapsProvider.create();
    mapsProvider.updateMarkers();
  }
}
