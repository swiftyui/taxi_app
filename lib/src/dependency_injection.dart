import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/features/permissions_carousel/providers/permissions_carousel_provider.dart';

Future<void> dependencyInjection() async {
  PermissionsCarouselProvider.create();
  TaxiRoutesProvider.create();
}
