import 'dart:async';

import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/saved_places_provider/saved_places_provider.dart';
import 'package:TaxiApp/src/core/models/saved_place.dart';
import 'package:TaxiApp/src/core/services/destination_query.dart';
import 'package:TaxiApp/src/core/services/destination_search_history.dart';
import 'package:TaxiApp/src/core/services/destination_search_service.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:TaxiApp/src/core/widgets/hamba_map.dart';
import 'package:TaxiApp/src/core/widgets/loaders/hambago_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchRoutesScreen extends StatefulWidget {
  const SearchRoutesScreen({super.key});

  @override
  State<SearchRoutesScreen> createState() => _SearchRoutesScreenState();
}

class _SearchRoutesScreenState extends State<SearchRoutesScreen> {
  static final _searchService = DestinationSearchService();
  static final _history = DestinationSearchHistory();
  final TaxiRoutesProvider _taxiRoutesProvider = TaxiRoutesProvider.create();
  final SavedPlacesProvider _savedPlacesProvider = SavedPlacesProvider.create();
  final RxList<RecentDestinationSearch> _recentSearches =
      <RecentDestinationSearch>[].obs;
  final RxList<DestinationSearchResult> _results =
      <DestinationSearchResult>[].obs;
  final RxString _query = ''.obs;
  final RxBool _isSearching = false.obs;
  final RxBool _hasSubmittedSearch = false.obs;
  final RxnString _errorMessage = RxnString();
  final TextEditingController _searchController = TextEditingController();

  int _searchGeneration = 0;
  Timer? _liveDebounce;
  Completer<void>? _liveRequest;

  @override
  void initState() {
    super.initState();
    unawaited(_showHistory(_history.load()));
  }

  @override
  void dispose() {
    _searchGeneration++;
    _cancelLiveLookup();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final generation = ++_searchGeneration;
    _cancelLiveLookup();
    _query.value = value;
    _results.clear();
    _errorMessage.value = null;
    _hasSubmittedSearch.value = false;
    final query = value.trim();
    final canSearch = DestinationQuery.normalize(query).length >= 3;
    _isSearching.value = canSearch;
    if (canSearch) {
      _liveDebounce = Timer(
        const Duration(milliseconds: 850),
        () => unawaited(_lookupSuggestions(query, generation)),
      );
    }
  }

  void _cancelLiveLookup() {
    _liveDebounce?.cancel();
    _liveRequest?.complete();
    _liveRequest = null;
  }

  Future<void> _lookupSuggestions(String query, int generation) async {
    final request = Completer<void>();
    _liveRequest = request;
    try {
      final results = await _searchService.liveSuggestions(
        query,
        abortTrigger: request.future,
      );
      if (generation == _searchGeneration) {
        _results.assignAll(results);
      }
    } on Exception {
      if (generation == _searchGeneration) {
        _errorMessage.value =
            Get.appLocalizations.liveDestinationLookupUnavailable;
      }
    } finally {
      if (generation == _searchGeneration) {
        _liveRequest = null;
        _isSearching.value = false;
      }
    }
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (DestinationQuery.normalize(query).length < 3 ||
        (_hasSubmittedSearch.value && _isSearching.value)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final generation = ++_searchGeneration;
    _cancelLiveLookup();
    final onScreen = _searchService.mergeSuggestions(
      query: query,
      local: _suggestions(query),
      online: _results,
    );
    _isSearching.value = true;
    _hasSubmittedSearch.value = true;
    _errorMessage.value = null;
    unawaited(_showHistory(_history.record(query)));

    try {
      final results = await _searchService.search(
        query: query,
        localResults: onScreen,
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

  List<DestinationSearchResult> _suggestions(String query) =>
      _searchService.suggestions(
        query: query,
        taxiRoutes: _taxiRoutesProvider.taxiRoutes,
        savedPlaces: _savedPlacesProvider.places.map(
          (place) => place.destination,
        ),
        recentSearches: _recentSearches,
      );

  Future<void> _showHistory(
    Future<List<RecentDestinationSearch>> update,
  ) async {
    final entries = await update;
    if (mounted) {
      _recentSearches.assignAll(entries);
    }
  }

  void _select(DestinationSearchResult result, {String? query}) {
    unawaited(
      _history.record(
        query ?? (_hasSubmittedSearch.value ? _query.value : result.label),
        destination: result,
      ),
    );
    Get.back(result: result);
  }

  void _selectRecent(RecentDestinationSearch entry) {
    if (entry.destination case final place?) {
      _select(place, query: entry.query);
      return;
    }
    _searchController.value = TextEditingValue(
      text: entry.query,
      selection: TextSelection.collapsed(offset: entry.query.length),
    );
    _onSearchChanged(entry.query);
    unawaited(_search(entry.query));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: const HambaGoAppBar(
      title: 'Search routes',
      subtitle: 'Find a destination or taxi route',
    ),
    bottomNavigationBar: const SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [OsmAttribution()],
      ),
    ),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            height: 52,
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
                    maxLength: 160,
                    style: Get.textTheme.labelLarge?.copyWith(
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: Get.appLocalizations.searchDestination,
                      counterText: '',
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
                Obx(() {
                  if (_query.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    tooltip: Get.appLocalizations.clearDestinationSearch,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colours.charcoalLight,
                    ),
                  );
                }),
                IconButton(
                  onPressed: () => _search(_searchController.text),
                  tooltip: 'Search',
                  icon: const Icon(Icons.search, color: Colors.black),
                ),
              ],
            ),
          ).paddingSymmetric(horizontal: Dimensions.sixteen),
          Expanded(child: Obx(_buildSearchBody)),
        ],
      ),
    ),
  );

  Widget _buildSearchBody() {
    final query = _query.value.trim();
    final l10n = Get.appLocalizations;
    if (query.isEmpty) {
      final places = _savedPlacesProvider.places.toList();
      final recent = _recentSearches.toList();
      if (places.isEmpty && recent.isEmpty) {
        return _SearchMessage(
          icon: Icons.travel_explore_rounded,
          title: 'Where are you heading?',
          message: l10n.searchAtLeastThreeCharacters,
        );
      }
      return _searchList([
        if (places.isNotEmpty) ...[
          _sectionHeading('Saved places'),
          for (final place in places)
            _destinationCard(
              place.destination,
              icon: switch (place.type) {
                SavedPlaceType.home => Icons.home_rounded,
                SavedPlaceType.work => Icons.work_rounded,
                SavedPlaceType.custom => Icons.star_rounded,
              },
            ),
        ],
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _sectionHeading(l10n.recentDestinationSearches)),
              TextButton(
                onPressed: () => _showHistory(_history.clear()),
                child: Text(l10n.clearDestinationHistory),
              ),
            ],
          ),
          for (final entry in recent) _recentCard(entry),
        ],
      ]);
    }

    final submitted = _hasSubmittedSearch.value;
    final searching = _isSearching.value;
    final results = _results.toList();
    final matches = submitted && !searching
        ? results
        : _searchService.mergeSuggestions(
            query: query,
            local: _suggestions(query),
            online: results,
          );
    final matcher = DestinationQuery(query);
    final pastQueries = submitted || matcher.normalized.length < 2
        ? const <RecentDestinationSearch>[]
        : _recentSearches
              .where(
                (entry) =>
                    entry.destination == null &&
                    matcher.score(entry.query) != null,
              )
              .take(4)
              .toList();
    if (matches.isNotEmpty || pastQueries.isNotEmpty) {
      return _searchList([
        if (searching) const LinearProgressIndicator(),
        if (matches.isNotEmpty) ...[
          if (!submitted) _sectionHeading(l10n.destinationSuggestions),
          for (final match in matches) _destinationCard(match),
        ],
        if (pastQueries.isNotEmpty) ...[
          _sectionHeading(l10n.recentDestinationSearches),
          for (final entry in pastQueries) _recentCard(entry),
        ],
      ]);
    }
    if (searching) {
      return const SearchRoutesShimmer();
    }
    final error = _errorMessage.value;
    if (error != null) {
      return _SearchMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Search unavailable',
        message: error,
        actionLabel: l10n.tryAgain,
        onAction: () => submitted ? _search(query) : _onSearchChanged(query),
      );
    }
    return _SearchMessage(
      icon: matcher.normalized.length >= 3
          ? Icons.location_off_outlined
          : Icons.travel_explore_rounded,
      title: matcher.normalized.length >= 3
          ? l10n.noDestinationsFound
          : l10n.whereDoYouWantToGo,
      message: matcher.normalized.length >= 3
          ? l10n.adjustDestinationSearch
          : l10n.searchAtLeastThreeCharacters,
    );
  }

  Widget _searchList(List<Widget> children) => ListView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    children: children,
  );

  Widget _sectionHeading(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: Colours.primaryOne,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _destinationCard(
    DestinationSearchResult result, {
    IconData icon = Icons.location_on_rounded,
  }) => _SearchResultCard(
    label: result.label,
    subtitle: result.subtitle,
    icon: icon,
    onTap: () => _select(result),
  );

  Widget _recentCard(RecentDestinationSearch entry) => _SearchResultCard(
    label: entry.destination?.label ?? entry.query,
    subtitle: entry.destination?.subtitle ?? '',
    icon: Icons.history_rounded,
    onTap: () => _selectRecent(entry),
  );
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.label,
    required this.onTap,
    required this.icon,
    this.subtitle = '',
  });

  final String label;
  final String subtitle;
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
            child: Material(
              type: MaterialType.transparency,
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colours.primaryOne,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: subtitle.isEmpty
                    ? null
                    : Text(
                        subtitle,
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
