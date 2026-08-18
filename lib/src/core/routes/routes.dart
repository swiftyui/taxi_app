import 'package:TaxiApp/src/features/landing/screens/landing_screen.dart';
import 'package:get/get.dart';

enum AppRoutes {
  root('/');

  const AppRoutes(this.value);

  final String value;
}

final initialRoute = AppRoutes.root.value;

final pages = [
  GetPage(name: AppRoutes.root.value, page: () => const LandingScreen()),
];
