import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/extensions/typed_extensions.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchRoutesScreen extends StatefulWidget {
  const SearchRoutesScreen({super.key});

  @override
  State<SearchRoutesScreen> createState() => _SearchRoutesScreenState();
}

class _SearchRoutesScreenState extends State<SearchRoutesScreen> {
  final TaxiRoutesProvider taxiRoutesProvider = TaxiRoutesProvider.create();

  final RxList<TaxiRouteModel> filteredRoutes = <TaxiRouteModel>[].obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredRoutes.value = taxiRoutesProvider.taxiRoutes;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colours.searchBarBackground,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: [
                const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.black,
                    )
                    .paddingOnly(
                      left: Dimensions.eight,
                      right: Dimensions.eight,
                    )
                    .onTap(() {
                      Get.back();
                    }),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      filteredRoutes.value = taxiRoutesProvider.taxiRoutes
                          .where(
                            (route) => route.properties.destname
                                .toLowerCase()
                                .contains(value.toLowerCase()),
                          )
                          .toList();
                    },
                    style: Get.textTheme.labelLarge?.copyWith(
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: Get.appLocalizations.searchHere,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(Dimensions.eight),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).paddingOnly(left: Dimensions.sixteen, right: Dimensions.sixteen),
          Obx(
            () => Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredRoutes.length,
                itemBuilder: (context, index) {
                  final route = filteredRoutes[index];
                  return Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colours.searchBarBackground,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Destination',
                                        style: Get.textTheme.labelMedium
                                            ?.copyWith(color: Colors.black),
                                      ),
                                      Text(
                                        route.properties.destname,
                                        style: Get.textTheme.labelLarge
                                            ?.copyWith(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ).paddingOnly(bottom: Dimensions.eight),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Origin',
                                        style: Get.textTheme.labelMedium
                                            ?.copyWith(color: Colors.black),
                                      ),
                                      Text(
                                        route.properties.originname,
                                        style: Get.textTheme.labelLarge
                                            ?.copyWith(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ).paddingOnly(bottom: Dimensions.eight),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.pin_drop_outlined,
                              color: Colors.black,
                            ).paddingOnly(
                              left: Dimensions.eight,
                              right: Dimensions.eight,
                            ),
                          ],
                        ),
                      )
                      .paddingOnly(
                        left: Dimensions.sixteen,
                        right: Dimensions.sixteen,
                        top: Dimensions.eight,
                      )
                      .onTap(() {
                        Get.back(result: route);
                      });
                },
              ).paddingOnly(top: Dimensions.sixteen),
            ),
          ),
        ],
      ),
    ),
  );
}
