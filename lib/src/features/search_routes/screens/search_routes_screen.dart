import 'dart:async';

import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/services/destination_search_service.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchRoutesScreen extends StatefulWidget {
  const SearchRoutesScreen({super.key});

  @override
  State<SearchRoutesScreen> createState() => _SearchRoutesScreenState();
}

class _SearchRoutesScreenState extends State<SearchRoutesScreen> {
  final TaxiRoutesProvider _taxiRoutesProvider = TaxiRoutesProvider.create();
  final DestinationSearchService _searchService = DestinationSearchService();
  final RxList<DestinationSearchResult> _results =
      <DestinationSearchResult>[].obs;
  final RxBool _isSearching = false.obs;
  final RxnString _errorMessage = RxnString();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  int _searchGeneration = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      _searchGeneration++;
      _results.clear();
      _errorMessage.value = null;
      _isSearching.value = false;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(value));
  }

  Future<void> _search(String value) async {
    final generation = ++_searchGeneration;
    _isSearching.value = true;
    _errorMessage.value = null;

    try {
      final results = await _searchService.search(
        query: value,
        taxiRoutes: _taxiRoutesProvider.taxiRoutes,
      );
      if (generation == _searchGeneration) {
        _results.assignAll(results);
      }
    } on DestinationSearchException catch (error) {
      if (generation == _searchGeneration) {
        _results.clear();
        _errorMessage.value = error.message;
      }
    } finally {
      if (generation == _searchGeneration) {
        _isSearching.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: const HambaGoAppBar(
      title: 'Search routes',
      subtitle: 'Find a destination or taxi route',
    ),
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
                Expanded(
                  child: TextField(
                    autofocus: true,
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: _search,
                    textInputAction: TextInputAction.search,
                    style: Get.textTheme.labelLarge?.copyWith(
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: Get.appLocalizations.searchDestination,
                      border: InputBorder.none,
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _search(_searchController.text),
                  icon: const Icon(Icons.search, color: Colors.black),
                ),
              ],
            ),
          ).paddingSymmetric(horizontal: Dimensions.sixteen),
          Expanded(
            child: Obx(() {
              if (_isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final error = _errorMessage.value;
              if (error != null) {
                return _SearchMessage(icon: Icons.cloud_off, message: error);
              }
              if (_results.isEmpty) {
                return _SearchMessage(
                  icon: Icons.place_outlined,
                  message: _searchController.text.trim().length < 3
                      ? Get.appLocalizations.searchAtLeastThreeCharacters
                      : Get.appLocalizations.noDestinationsFound,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(top: Dimensions.sixteen),
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: Colours.primaryOne,
                    ),
                    title: Text(result.label),
                    subtitle: result.subtitle.isEmpty
                        ? null
                        : Text(
                            result.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => Get.back(result: result),
                  );
                },
              );
            }),
          ),
        ],
      ),
    ),
  );
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 42, color: Colours.charcoalLight),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colours.charcoalLight,
          ),
        ).paddingAll(Dimensions.sixteen),
      ],
    ),
  );
}
