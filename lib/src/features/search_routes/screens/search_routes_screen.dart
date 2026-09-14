import 'dart:async';

import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/saved_places_provider/saved_places_provider.dart';
import 'package:TaxiApp/src/core/models/saved_place.dart';
import 'package:TaxiApp/src/core/services/destination_search_service.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:TaxiApp/src/core/widgets/loaders/hambago_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchRoutesScreen extends StatefulWidget {
  const SearchRoutesScreen({super.key});

  @override
  State<SearchRoutesScreen> createState() => _SearchRoutesScreenState();
}

class _SearchRoutesScreenState extends State<SearchRoutesScreen> {
  final TaxiRoutesProvider _taxiRoutesProvider = TaxiRoutesProvider.create();
  final SavedPlacesProvider _savedPlacesProvider = SavedPlacesProvider.create();
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
                return const SearchRoutesShimmer();
              }
              final error = _errorMessage.value;
              if (error != null) {
                return _SearchMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Search unavailable',
                  message: error,
                  actionLabel: 'Dismiss',
                  onAction: () => _errorMessage.value = null,
                );
              }
              if (_results.isEmpty) {
                if (_searchController.text.trim().length < 3 &&
                    _savedPlacesProvider.places.isNotEmpty) {
                  return _SavedPlaceSuggestions(
                    places: _savedPlacesProvider.places,
                    onSelected: (place) => Get.back(result: place.destination),
                  );
                }
                return _SearchMessage(
                  icon: _searchController.text.trim().length < 3
                      ? Icons.travel_explore_rounded
                      : Icons.location_off_outlined,
                  title: _searchController.text.trim().length < 3
                      ? 'Where are you heading?'
                      : 'No destinations found',
                  message: _searchController.text.trim().length < 3
                      ? Get.appLocalizations.searchAtLeastThreeCharacters
                      : Get.appLocalizations.noDestinationsFound,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return _SearchResultCard(
                    result: result,
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

class _SavedPlaceSuggestions extends StatelessWidget {
  const _SavedPlaceSuggestions({
    required this.places,
    required this.onSelected,
  });

  final List<SavedPlace> places;
  final ValueChanged<SavedPlace> onSelected;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
    children: [
      const Text(
        'Saved places',
        style: TextStyle(
          color: Colours.primaryOne,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Text(
        'Start a journey with one tap',
        style: TextStyle(color: Colours.charcoalLight, fontSize: 10),
      ),
      const SizedBox(height: 10),
      for (final place in places)
        _SearchResultCard(
          result: place.destination,
          icon: switch (place.type) {
            SavedPlaceType.home => Icons.home_rounded,
            SavedPlaceType.work => Icons.work_rounded,
            SavedPlaceType.custom => Icons.star_rounded,
          },
          onTap: () => onSelected(place),
        ),
    ],
  );
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
    required this.onTap,
    this.icon = Icons.location_on_rounded,
  });

  final DestinationSearchResult result;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: Dimensions.eight),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFDCE7EA)),
      boxShadow: [
        BoxShadow(
          color: Colours.primaryOne.withValues(alpha: 0.07),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colours.primaryOne, Colours.blueThree, Colours.yellow],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Expanded(
            child: ListTile(
              minTileHeight: 76,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F1F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colours.blueThree, size: 21),
              ),
              title: Text(
                result.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colours.primaryOne,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: result.subtitle.isEmpty
                  ? null
                  : Text(
                      result.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colours.charcoalLight,
                        fontSize: 11,
                      ),
                    ),
              trailing: const Icon(
                Icons.arrow_forward_rounded,
                color: Colours.blueThree,
                size: 18,
              ),
              onTap: onTap,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: Container(
      margin: const EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7EA)),
        boxShadow: [
          BoxShadow(
            color: Colours.primaryOne.withValues(alpha: 0.07),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colours.primaryOne, Colours.blueThree, Colours.yellow],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Dimensions.sixteen),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F1F5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 23, color: Colours.blueThree),
                ),
                const SizedBox(width: Dimensions.twelve),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colours.primaryOne,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colours.charcoalLight,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: Colours.blueThree,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(actionLabel!),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
