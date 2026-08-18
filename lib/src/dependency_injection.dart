import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';

Future<void> dependencyInjection() async {
  TaxiRoutesProvider.create();
}
