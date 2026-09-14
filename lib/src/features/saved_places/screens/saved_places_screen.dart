import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/models/driver_route_location.dart';
import 'package:TaxiApp/src/core/models/saved_place.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/saved_places_provider/saved_places_provider.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:TaxiApp/src/features/my_profile/screens/driver_location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SavedPlacesScreen extends StatelessWidget {
  SavedPlacesScreen({super.key});

  final SavedPlacesProvider _provider = SavedPlacesProvider.create();
  final ActionsProvider _actionsProvider = ActionsProvider.create();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: const HambaGoAppBar(
      title: 'Saved places',
      subtitle: 'Home, work, and places you visit often',
    ),
    floatingActionButton: Obx(
      () => _provider.isSignedIn
          ? FloatingActionButton.extended(
              onPressed: () => Get.to<void>(
                () => SavedPlaceEditorScreen(provider: _provider),
              ),
              backgroundColor: Colours.blueThree,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add place'),
            )
          : const SizedBox.shrink(),
    ),
    body: Obx(() {
      if (!_provider.isSignedIn) {
        return _SavedPlacesEmpty(
          icon: Icons.person_outline_rounded,
          title: 'Sign in to save places',
          message: 'Keep Home, Work, and your regular destinations synced.',
          actionLabel: 'Go to profile',
          onAction: () => Get.toNamed<void>(AppRoutes.myProfile.value),
        );
      }
      if (_provider.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colours.blueThree),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          if (_provider.errorMessage.value != null)
            _SavedPlacesMessage(
              message: _provider.errorMessage.value!,
              onDismiss: () => _provider.errorMessage.value = null,
            ),
          if (_provider.places.isEmpty)
            const _SavedPlacesEmpty(
              icon: Icons.bookmark_add_outlined,
              title: 'Make journeys quicker',
              message:
                  'Save Home, Work, or another destination to plan a journey in one tap.',
            )
          else
            for (final place in _provider.places)
              _SavedPlaceCard(
                place: place,
                onPlan: () => _planJourney(place),
                onEdit: () => Get.to<void>(
                  () =>
                      SavedPlaceEditorScreen(provider: _provider, place: place),
                ),
                onDelete: () => _confirmDelete(context, place),
              ).paddingOnly(bottom: Dimensions.eight),
        ],
      );
    }),
  );

  void _planJourney(SavedPlace place) {
    Get.offAllNamed<void>(AppRoutes.root.value);
    _actionsProvider.planJourney(place.destination);
  }

  Future<void> _confirmDelete(BuildContext context, SavedPlace place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove saved place?'),
        content: Text('${place.label} will no longer appear in quick search.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colours.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _provider.delete(place);
    }
  }
}

class SavedPlaceEditorScreen extends StatefulWidget {
  const SavedPlaceEditorScreen({required this.provider, this.place, super.key});

  final SavedPlacesProvider provider;
  final SavedPlace? place;

  @override
  State<SavedPlaceEditorScreen> createState() => _SavedPlaceEditorScreenState();
}

class _SavedPlaceEditorScreenState extends State<SavedPlaceEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late SavedPlaceType _type;
  DestinationSearchResult? _location;

  @override
  void initState() {
    super.initState();
    final place = widget.place;
    _type = place?.type ?? SavedPlaceType.home;
    _labelController = TextEditingController(
      text: place?.label ?? _defaultLabel(_type),
    );
    if (place != null) {
      _location = place.destination;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: HambaGoAppBar(
      title: widget.place == null ? 'Add saved place' : 'Edit saved place',
      subtitle: 'Choose a shortcut and its location',
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(Dimensions.sixteen),
        children: [
          const Text(
            'Place type',
            style: TextStyle(
              color: Colours.primaryOne,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<SavedPlaceType>(
            segments: const [
              ButtonSegment(
                value: SavedPlaceType.home,
                icon: Icon(Icons.home_outlined),
                label: Text('Home'),
              ),
              ButtonSegment(
                value: SavedPlaceType.work,
                icon: Icon(Icons.work_outline_rounded),
                label: Text('Work'),
              ),
              ButtonSegment(
                value: SavedPlaceType.custom,
                icon: Icon(Icons.star_outline_rounded),
                label: Text('Frequent'),
              ),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              final previousDefault = _defaultLabel(_type);
              setState(() {
                _type = selection.single;
                if (_labelController.text.trim().isEmpty ||
                    _labelController.text == previousDefault) {
                  _labelController.text = _defaultLabel(_type);
                }
              });
            },
          ),
          const SizedBox(height: Dimensions.sixteen),
          TextFormField(
            controller: _labelController,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            validator: (value) => value == null || value.trim().length < 2
                ? 'Enter a name for this place.'
                : null,
            decoration: const InputDecoration(
              labelText: 'Place name',
              prefixIcon: Icon(Icons.label_outline_rounded),
            ),
          ),
          const SizedBox(height: Dimensions.eight),
          _LocationSelectionCard(
            location: _location,
            onSearch: _selectFromSearch,
            onMap: _selectFromMap,
          ),
          Obx(
            () => widget.provider.errorMessage.value == null
                ? const SizedBox.shrink()
                : Text(
                    widget.provider.errorMessage.value!,
                    style: const TextStyle(
                      color: Colours.errorColour,
                      fontSize: 11,
                    ),
                  ).paddingOnly(top: Dimensions.twelve),
          ),
          Obx(
            () => FilledButton.icon(
              onPressed: widget.provider.isSaving.value ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: Colours.blueThree,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: widget.provider.isSaving.value
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bookmark_add_outlined),
              label: Text(widget.place == null ? 'Save place' : 'Save changes'),
            ).paddingOnly(top: Dimensions.sixteen),
          ),
        ],
      ),
    ),
  );

  Future<void> _selectFromSearch() async {
    final result = await Get.toNamed(AppRoutes.searchRoutes.value);
    if (result is DestinationSearchResult && mounted) {
      setState(() => _location = result);
    }
  }

  Future<void> _selectFromMap() async {
    final current = _location;
    final result = await Get.to<DriverRouteLocation>(
      () => DriverLocationPickerScreen(
        title: 'Choose saved place',
        markerHue: BitmapDescriptor.hueAzure,
        initialLocation: current == null
            ? null
            : DriverRouteLocation(
                label: current.subtitle.isEmpty
                    ? current.label
                    : current.subtitle,
                position: current.position,
              ),
      ),
    );
    if (result != null && mounted) {
      setState(
        () => _location = DestinationSearchResult(
          label: _labelController.text.trim(),
          subtitle: result.label,
          position: result.position,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final location = _location;
    if (location == null) {
      widget.provider.errorMessage.value =
          'Search for a location or choose one on the map.';
      return;
    }
    final saved = await widget.provider.save(
      id: widget.place?.id,
      type: _type,
      label: _labelController.text,
      address: location.subtitle.isEmpty ? location.label : location.subtitle,
      position: location.position,
    );
    if (saved) {
      Get.back<void>();
    }
  }

  static String _defaultLabel(SavedPlaceType type) => switch (type) {
    SavedPlaceType.home => 'Home',
    SavedPlaceType.work => 'Work',
    SavedPlaceType.custom => 'Frequent place',
  };
}

class _LocationSelectionCard extends StatelessWidget {
  const _LocationSelectionCard({
    required this.location,
    required this.onSearch,
    required this.onMap,
  });

  final DestinationSearchResult? location;
  final VoidCallback onSearch;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.twelve),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFDCE7EA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.place_outlined, color: Colours.blueThree),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(
                      color: Colours.primaryOne,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    location?.subtitle ??
                        'Search for an address or select it on the map.',
                    style: const TextStyle(
                      color: Colours.charcoalLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onMap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colours.blueThree,
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Use map'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SavedPlaceCard extends StatelessWidget {
  const _SavedPlaceCard({
    required this.place,
    required this.onPlan,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedPlace place;
  final VoidCallback onPlan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onPlan,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.twelve),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F1F5),
                shape: BoxShape.circle,
              ),
              child: Icon(_placeIcon(place.type), color: Colours.blueThree),
            ),
            const SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.label,
                    style: const TextStyle(
                      color: Colours.primaryOne,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    place.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colours.charcoalLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  IconData _placeIcon(SavedPlaceType type) => switch (type) {
    SavedPlaceType.home => Icons.home_rounded,
    SavedPlaceType.work => Icons.work_rounded,
    SavedPlaceType.custom => Icons.star_rounded,
  };
}

class _SavedPlacesMessage extends StatelessWidget {
  const _SavedPlacesMessage({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => MaterialBanner(
    content: Text(message),
    leading: const Icon(Icons.error_outline, color: Colours.errorColour),
    actions: [TextButton(onPressed: onDismiss, child: const Text('Dismiss'))],
  ).paddingOnly(bottom: Dimensions.twelve);
}

class _SavedPlacesEmpty extends StatelessWidget {
  const _SavedPlacesEmpty({
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colours.blueThree, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colours.primaryOne,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colours.charcoalLight, fontSize: 12),
          ),
          if (onAction != null)
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(backgroundColor: Colours.blueThree),
              child: Text(actionLabel!),
            ).paddingOnly(top: Dimensions.sixteen),
        ],
      ),
    ),
  );
}
