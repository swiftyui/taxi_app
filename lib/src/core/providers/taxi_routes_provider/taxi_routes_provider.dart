// https://pta-gis-2-web1.csir.co.za/server2/rest/services/Hosted/Tshwane_Taxi_Routes_shp/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson
import 'dart:convert';

import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';

class TaxiRoutesProvider extends GetxController {
  static TaxiRoutesProvider create() => Get.isRegistered<TaxiRoutesProvider>()
      ? Get.find<TaxiRoutesProvider>()
      : Get.put<TaxiRoutesProvider>(TaxiRoutesProvider());

  final RxList<TaxiRouteParent> _taxiRoutesFeature = <TaxiRouteParent>[].obs;
  final RxList<TaxiRouteModel> taxiRoutes = <TaxiRouteModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getPretoriaRoutes();
  }

  Future<void> getPretoriaRoutes() async {
    try {
      final url = Uri.https(
        'pta-gis-2-web1.csir.co.za',
        '/server2/rest/services/Hosted/Tshwane_Taxi_Routes_shp/FeatureServer/0/query',
        {
          'where': '1=1',
          'outFields': '*',
          'returnGeometry': 'true',
          'f': 'geojson',
        },
      );
      final response = await get(url);

      final data = response.body;
      final taxiRoutesData = TaxiRouteParent.fromJson(jsonDecode(data));
      _taxiRoutesFeature.value = [taxiRoutesData];
      taxiRoutes.value = taxiRoutesData.features;

      print(
        'Pretoria Taxi Routes fetched successfully: ${taxiRoutesData.features.length} routes',
      );
    } catch (e) {
      print('Error fetching Pretoria Taxi Routes: $e');
    }
  }
}
