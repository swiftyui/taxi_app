import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:TaxiApp/src/core/models/driver_route_location.dart';
import 'package:TaxiApp/src/core/providers/driver_account_provider/driver_account_provider.dart';
import 'package:TaxiApp/src/core/providers/driver_reviews_provider/driver_reviews_provider.dart';
import 'package:TaxiApp/src/core/providers/ride_requests_provider/ride_requests_provider.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/pickers/hambago_time_picker.dart';
import 'package:TaxiApp/src/features/my_profile/screens/driver_location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverAccountScreen extends StatefulWidget {
  const DriverAccountScreen({super.key});

  @override
  State<DriverAccountScreen> createState() => _DriverAccountScreenState();
}

class _DriverAccountScreenState extends State<DriverAccountScreen> {
  final DriverAccountProvider _provider = DriverAccountProvider.create();
  final RideRequestsProvider _rideRequestsProvider =
      RideRequestsProvider.create();
  final DriverReviewsProvider _driverReviewsProvider =
      DriverReviewsProvider.create();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: _DriverAppBar(rideRequestsProvider: _rideRequestsProvider),
    body: SafeArea(
      top: false,
      child: Obx(() {
        if (_provider.isLoading.value && _provider.profile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RefreshIndicator(
              onRefresh: _provider.loadDriverAccount,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                children: [
                  _DriverHero(isDriver: _provider.isDriver),
                  if (_provider.isDriver)
                    _DriverReviewsCard(
                      provider: _driverReviewsProvider,
                    ).paddingOnly(top: Dimensions.twelve),
                  if (_provider.errorMessage.value != null)
                    _DriverMessage(
                      message: _provider.errorMessage.value!,
                      isError: true,
                    ).paddingOnly(top: Dimensions.twelve),
                  if (_provider.successMessage.value != null)
                    _DriverMessage(
                      message: _provider.successMessage.value!,
                    ).paddingOnly(top: Dimensions.twelve),
                  _DriverDetailsForm(
                    provider: _provider,
                    profile: _provider.profile.value,
                  ).paddingOnly(top: Dimensions.twelve),
                  if (_provider.isDriver)
                    _RideRequestsCard(
                      provider: _rideRequestsProvider,
                    ).paddingOnly(top: Dimensions.twelve),
                  if (_provider.isDriver)
                    _DriverRoutesCard(
                      provider: _provider,
                    ).paddingOnly(top: Dimensions.twelve),
                ],
              ),
            ),
          ),
        );
      }),
    ),
  );
}

class _DriverReviewsCard extends StatelessWidget {
  const _DriverReviewsCard({required this.provider});

  final DriverReviewsProvider provider;

  @override
  Widget build(BuildContext context) => Obx(() {
    final reviews = provider.reviews;
    return _DriverCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.twelve),
            child: Row(
              children: [
                const Expanded(
                  child: _DriverSectionTitle(
                    icon: Icons.star_rounded,
                    title: 'Driver reviews',
                    subtitle: 'Feedback from completed HambaGo journeys.',
                  ),
                ),
                if (reviews.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colours.yellow,
                            size: 18,
                          ),
                          Text(
                            provider.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colours.primaryOne,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colours.charcoalLight,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (provider.isLoading.value && reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(22),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Your traveller reviews will appear here after completed rides.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colours.charcoalLight, fontSize: 11),
              ),
            )
          else
            for (final review in reviews.take(5))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.reviewerName,
                            style: const TextStyle(
                              color: Colours.primaryOne,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        for (var star = 1; star <= 5; star++)
                          Icon(
                            star <= review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colours.yellow,
                            size: 14,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${review.originName} → ${review.destinationName}'
                      '${review.updatedAt == null ? '' : ' · ${DateFormat('d MMM').format(review.updatedAt!)}'}',
                      style: const TextStyle(
                        color: Colours.charcoalLight,
                        fontSize: 10,
                      ),
                    ),
                    if (review.comment.isNotEmpty)
                      Text(
                        review.comment,
                        style: const TextStyle(fontSize: 12, height: 1.35),
                      ).paddingOnly(top: 5),
                  ],
                ),
              ),
        ],
      ),
    );
  });
}

class _DriverAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DriverAppBar({required this.rideRequestsProvider});

  final RideRequestsProvider rideRequestsProvider;

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: preferredSize.height,
    backgroundColor: Colours.lightSurface,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    leadingWidth: 66,
    leading: Padding(
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colours.primaryOne.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          onPressed: Get.back,
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colours.primaryOne,
            size: 22,
          ),
        ),
      ),
    ),
    titleSpacing: 12,
    title: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver account',
          style: TextStyle(
            color: Colours.primaryOne,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Manage your HambaGo taxi',
          style: TextStyle(
            color: Colours.charcoalLight,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    actions: [
      Obx(() {
        final requestCount = rideRequestsProvider.driverRequests.length;
        return Padding(
          padding: const EdgeInsets.only(top: 10, right: 12, bottom: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Dimensions.twelve),
                  boxShadow: [
                    BoxShadow(
                      color: Colours.primaryOne.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () =>
                      Get.toNamed<void>(AppRoutes.rideRequests.value),
                  tooltip: 'Ride requests',
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colours.blueThree,
                    size: 22,
                  ),
                ),
              ),
              if (requestCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colours.red,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      requestCount > 99 ? '99+' : '$requestCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    ],
  );
}

class _RideRequestsCard extends StatelessWidget {
  const _RideRequestsCard({required this.provider});

  final RideRequestsProvider provider;

  @override
  Widget build(BuildContext context) => Obx(
    () => _DriverCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => Get.toNamed<void>(AppRoutes.rideRequests.value),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F1F5),
            borderRadius: BorderRadius.circular(Dimensions.eight),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: Colours.blueThree,
          ),
        ),
        title: const Text(
          'Ride requests',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          provider.driverRequests.isEmpty
              ? 'Requests from riders will appear here.'
              : '${provider.driverRequests.length} '
                    '${provider.driverRequests.length == 1 ? 'request' : 'requests'} available',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    ),
  );
}

class _DriverHero extends StatelessWidget {
  const _DriverHero({required this.isDriver});

  final bool isDriver;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.sixteen),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colours.primaryOne, Colours.blueThree],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(Dimensions.eight),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_taxi_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: Dimensions.twelve),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDriver ? 'Your driver account' : 'Become a driver',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isDriver
                    ? 'Manage your taxi, routes, and incoming ride requests.'
                    : 'Tell us about you and your taxi to get started.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DriverDetailsForm extends StatefulWidget {
  const _DriverDetailsForm({required this.provider, required this.profile});

  final DriverAccountProvider provider;
  final DriverProfile? profile;

  @override
  State<_DriverDetailsForm> createState() => _DriverDetailsFormState();
}

class _DriverDetailsFormState extends State<_DriverDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'contact': TextEditingController(),
      'licence': TextEditingController(),
      'permit': TextEditingController(),
      'association': TextEditingController(),
      'registration': TextEditingController(),
      'make': TextEditingController(),
      'model': TextEditingController(),
      'color': TextEditingController(),
      'seats': TextEditingController(),
    };
    _populate(widget.profile);
  }

  @override
  void didUpdateWidget(covariant _DriverDetailsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile == null && widget.profile != null) {
      _populate(widget.profile);
    }
  }

  void _populate(DriverProfile? profile) {
    if (profile == null) {
      return;
    }
    _controllers['contact']!.text = profile.contactNumber;
    _controllers['licence']!.text = profile.driverLicenceNumber;
    _controllers['permit']!.text = profile.operatingPermitNumber;
    _controllers['association']!.text = profile.associationName;
    _controllers['registration']!.text = profile.vehicleRegistration;
    _controllers['make']!.text = profile.vehicleMake;
    _controllers['model']!.text = profile.vehicleModel;
    _controllers['color']!.text = profile.vehicleColor;
    _controllers['seats']!.text = '${profile.seatCapacity}';
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _DriverCard(
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DriverSectionTitle(
            icon: Icons.badge_outlined,
            title: widget.profile == null
                ? 'Driver and taxi details'
                : 'Registered taxi',
            subtitle: 'Use the details shown on your official documents.',
          ),
          const SizedBox(height: Dimensions.sixteen),
          _field(
            keyName: 'contact',
            label: 'Contact number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
              return digits.length < 10
                  ? 'Enter a valid contact number.'
                  : null;
            },
          ),
          _field(
            keyName: 'licence',
            label: 'Driver licence number',
            icon: Icons.credit_card_outlined,
          ),
          _field(
            keyName: 'permit',
            label: 'Operating permit number',
            icon: Icons.description_outlined,
          ),
          _field(
            keyName: 'association',
            label: 'Taxi association',
            icon: Icons.groups_outlined,
          ),
          const Divider(height: 28),
          _field(
            keyName: 'registration',
            label: 'Vehicle registration number',
            icon: Icons.pin_outlined,
            capitalization: TextCapitalization.characters,
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  keyName: 'make',
                  label: 'Make',
                  icon: Icons.local_taxi_outlined,
                ),
              ),
              const SizedBox(width: Dimensions.eight),
              Expanded(
                child: _field(
                  keyName: 'model',
                  label: 'Model',
                  icon: Icons.directions_car_outlined,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  keyName: 'color',
                  label: 'Color',
                  icon: Icons.palette_outlined,
                ),
              ),
              const SizedBox(width: Dimensions.eight),
              Expanded(
                child: _field(
                  keyName: 'seats',
                  label: 'Passenger seats',
                  icon: Icons.airline_seat_recline_normal_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final seats = int.tryParse(value ?? '');
                    return seats == null || seats < 1 || seats > 40
                        ? 'Use 1–40.'
                        : null;
                  },
                ),
              ),
            ],
          ),
          Obx(
            () => FilledButton.icon(
              onPressed: widget.provider.isSaving.value ? null : _save,
              icon: Icon(
                widget.profile == null
                    ? Icons.local_taxi_rounded
                    : Icons.save_outlined,
              ),
              label: Text(
                widget.profile == null
                    ? 'Activate driver account'
                    : 'Update taxi details',
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field({
    required String keyName,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.words,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: _controllers[keyName],
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    validator:
        validator ??
        (value) => value == null || value.trim().length < 2
            ? 'This field is required.'
            : null,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  ).paddingOnly(bottom: Dimensions.twelve);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await widget.provider.saveDriverProfile(
      DriverProfile(
        contactNumber: _controllers['contact']!.text.trim(),
        driverLicenceNumber: _controllers['licence']!.text.trim(),
        operatingPermitNumber: _controllers['permit']!.text.trim(),
        associationName: _controllers['association']!.text.trim(),
        vehicleRegistration: _controllers['registration']!.text
            .trim()
            .toUpperCase(),
        vehicleMake: _controllers['make']!.text.trim(),
        vehicleModel: _controllers['model']!.text.trim(),
        vehicleColor: _controllers['color']!.text.trim(),
        seatCapacity: int.parse(_controllers['seats']!.text),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class _DriverRoutesCard extends StatelessWidget {
  const _DriverRoutesCard({required this.provider});

  final DriverAccountProvider provider;

  @override
  Widget build(BuildContext context) => Obx(
    () => _DriverCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: _DriverSectionTitle(
                    icon: Icons.alt_route_rounded,
                    title: 'Your routes',
                    subtitle: 'Create and manage your active taxi routes.',
                  ),
                ),
                IconButton(
                  onPressed: () => _showCreateRoute(context),
                  tooltip: 'Create route',
                  icon: const Icon(Icons.add_rounded),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colours.blueThree,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colours.containerOne,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.eight),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (provider.routes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.route_outlined,
                    size: 34,
                    color: Colours.containerOne,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No routes submitted',
                    style: TextStyle(
                      color: Colours.primaryOne,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tap + to create your first taxi route.',
                    style: TextStyle(
                      color: Colours.charcoalLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final route in provider.routes)
              _DriverRouteTile(
                route: route,
                onEdit: () => _showRouteSheet(context, route: route),
                onDelete: () => _deleteRoute(context, route),
              ),
        ],
      ),
    ),
  );

  Future<void> _showCreateRoute(BuildContext context) async {
    await _showRouteSheet(context);
  }

  Future<void> _showRouteSheet(
    BuildContext context, {
    DriverRoute? route,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _CreateDriverRouteSheet(provider: provider, initialRoute: route),
    );
  }

  Future<void> _deleteRoute(BuildContext context, DriverRoute route) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete route?'),
            content: Text(
              '${route.originName} to ${route.destinationName} will no longer '
              'be available to riders.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep route'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await provider.deleteRoute(route.id);
    }
  }
}

class _DriverRouteTile extends StatelessWidget {
  const _DriverRouteTile({
    required this.route,
    required this.onEdit,
    required this.onDelete,
  });

  final DriverRoute route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const CircleAvatar(
      backgroundColor: Color(0xFFE6F1F5),
      child: Icon(Icons.route_rounded, color: Colours.blueThree),
    ),
    title: Text(
      '${route.originName} → ${route.destinationName}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      'R${route.fare.toStringAsFixed(2)} · '
      '${_serviceDayLabel(route.serviceDays)}'
      '${route.departureTime.isEmpty ? '' : ' at ${route.departureTime}'}'
      '${route.createdAt == null ? '' : ' · ${DateFormat('d MMM').format(route.createdAt!)}'}',
      maxLines: 2,
      style: const TextStyle(fontSize: 11),
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded),
            title: Text('Delete'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ),
  );

  String _serviceDayLabel(List<String> days) {
    const names = {
      'Mon': 'Mondays',
      'Tue': 'Tuesdays',
      'Wed': 'Wednesdays',
      'Thu': 'Thursdays',
      'Fri': 'Fridays',
      'Sat': 'Saturdays',
      'Sun': 'Sundays',
    };
    return days.map((day) => names[day] ?? day).join(', ');
  }
}

class _CreateDriverRouteSheet extends StatefulWidget {
  const _CreateDriverRouteSheet({required this.provider, this.initialRoute});

  final DriverAccountProvider provider;
  final DriverRoute? initialRoute;

  @override
  State<_CreateDriverRouteSheet> createState() =>
      _CreateDriverRouteSheetState();
}

class _CreateDriverRouteSheetState extends State<_CreateDriverRouteSheet> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _fareController = TextEditingController();
  final _notesController = TextEditingController();
  final Set<String> _selectedDays = {};
  TimeOfDay? _departureTime;
  DriverRouteLocation? _originLocation;
  DriverRouteLocation? _destinationLocation;

  @override
  void initState() {
    super.initState();
    final route = widget.initialRoute;
    if (route == null) {
      return;
    }
    _originController.text = route.originName;
    _destinationController.text = route.destinationName;
    _fareController.text = route.fare.toStringAsFixed(2);
    _notesController.text = route.notes;
    _selectedDays.addAll(route.serviceDays);
    final timeParts = route.departureTime.split(':');
    if (timeParts.length == 2) {
      _departureTime = TimeOfDay(
        hour: int.tryParse(timeParts[0]) ?? 0,
        minute: int.tryParse(timeParts[1]) ?? 0,
      );
    }
    _originLocation = DriverRouteLocation(
      label: route.originName,
      position: LatLng(route.origin.latitude, route.origin.longitude),
    );
    _destinationLocation = DriverRouteLocation(
      label: route.destinationName,
      position: LatLng(route.destination.latitude, route.destination.longitude),
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _fareController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      10,
      16,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colours.containerOne,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DriverSectionTitle(
              icon: Icons.add_road_rounded,
              title: widget.initialRoute == null
                  ? 'Create a taxi route'
                  : 'Edit taxi route',
              subtitle: 'Add the locations, service days, and departure time.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _originController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _originLocation = null,
              validator: _requiredLocation,
              decoration: InputDecoration(
                labelText: 'Origin or taxi rank',
                prefixIcon: const Icon(Icons.trip_origin_rounded),
                suffixIcon: IconButton(
                  onPressed: () => _pickLocation(isOrigin: true),
                  tooltip: 'Choose origin on map',
                  icon: const Icon(Icons.map_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destinationController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _destinationLocation = null,
              validator: _requiredLocation,
              decoration: InputDecoration(
                labelText: 'Destination',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  onPressed: () => _pickLocation(isOrigin: false),
                  tooltip: 'Choose destination on map',
                  icon: const Icon(Icons.map_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fareController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final fare = double.tryParse(value ?? '');
                return fare == null || fare <= 0 ? 'Enter a valid fare.' : null;
              },
              decoration: const InputDecoration(
                labelText: 'Fare',
                prefixText: 'R ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Service days',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final day in _days)
                  FilterChip(
                    label: Text(day),
                    selected: _selectedDays.contains(day),
                    selectedColor: Colours.blueThree,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: _selectedDays.contains(day)
                          ? Colours.blueThree
                          : Colours.containerOne,
                    ),
                    labelStyle: TextStyle(
                      color: _selectedDays.contains(day)
                          ? Colors.white
                          : Colours.primaryOne,
                      fontSize: 12,
                      fontWeight: _selectedDays.contains(day)
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.eight),
                    ),
                    onSelected: (selected) => setState(() {
                      selected
                          ? _selectedDays.add(day)
                          : _selectedDays.remove(day);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDepartureTime,
              borderRadius: BorderRadius.circular(Dimensions.eight),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.twelve,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Dimensions.eight),
                  border: Border.all(color: Colours.containerOne),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Colours.blueThree,
                    ),
                    const SizedBox(width: Dimensions.twelve),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Departure time',
                            style: TextStyle(
                              color: Colours.charcoalLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _departureTime == null
                                ? 'Select a time'
                                : _formatTime(_departureTime!),
                            style: TextStyle(
                              color: _departureTime == null
                                  ? Colours.charcoalLight
                                  : Colours.primaryOne,
                              fontSize: 14,
                              fontWeight: _departureTime == null
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colours.charcoalLight,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Route notes (optional)',
                hintText: 'Pickup point, operating times, landmarks',
                alignLabelWithHint: true,
              ),
            ),
            Obx(() {
              final error = widget.provider.errorMessage.value;
              return error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.twelve),
                      child: Text(
                        error,
                        style: const TextStyle(
                          color: Colours.errorColour,
                          fontSize: 12,
                        ),
                      ),
                    );
            }),
            Obx(
              () => SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: widget.provider.isSaving.value ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colours.blueThree,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colours.blueThree.withValues(
                      alpha: 0.55,
                    ),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.eight),
                    ),
                  ),
                  icon: widget.provider.isSaving.value
                      ? const SizedBox.square(
                          dimension: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 21),
                  label: Text(
                    widget.provider.isSaving.value
                        ? 'Saving route…'
                        : widget.initialRoute == null
                        ? 'Add route'
                        : 'Save changes',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String? _requiredLocation(String? value) =>
      value == null || value.trim().length < 3
      ? 'Enter a more specific location.'
      : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDays.isEmpty) {
      widget.provider.errorMessage.value = 'Select at least one service day.';
      return;
    }
    if (_departureTime == null) {
      widget.provider.errorMessage.value = 'Select a departure time.';
      return;
    }
    final serviceDays = _days
        .where(_selectedDays.contains)
        .toList(growable: false);
    final initialRoute = widget.initialRoute;
    final saved = initialRoute == null
        ? await widget.provider.createRoute(
            originName: _originController.text,
            destinationName: _destinationController.text,
            fare: double.parse(_fareController.text),
            serviceDays: serviceDays,
            departureTime: _formatTime(_departureTime!),
            notes: _notesController.text,
            originPosition: _originLocation?.position,
            destinationPosition: _destinationLocation?.position,
          )
        : await widget.provider.updateRoute(
            routeId: initialRoute.id,
            originName: _originController.text,
            destinationName: _destinationController.text,
            fare: double.parse(_fareController.text),
            serviceDays: serviceDays,
            departureTime: _formatTime(_departureTime!),
            notes: _notesController.text,
            originPosition: _originLocation?.position,
            destinationPosition: _destinationLocation?.position,
          );
    if (saved) {
      Get.back<void>();
    }
  }

  Future<void> _pickDepartureTime() async {
    final selectedTime = await showHambaGoTimePicker(
      context: context,
      initialTime: _departureTime ?? TimeOfDay.now(),
    );
    if (selectedTime != null && mounted) {
      setState(() => _departureTime = selectedTime);
    }
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickLocation({required bool isOrigin}) async {
    final initialLocation = isOrigin ? _originLocation : _destinationLocation;
    final result = await Navigator.of(context).push<DriverRouteLocation>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DriverLocationPickerScreen(
          title: isOrigin ? 'Choose route origin' : 'Choose destination',
          markerHue: isOrigin
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed,
          initialLocation: initialLocation,
        ),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      if (isOrigin) {
        _originLocation = result;
        _originController.text = result.label;
      } else {
        _destinationLocation = result;
        _destinationController.text = result.label;
      }
    });
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.child,
    this.padding = const EdgeInsets.all(Dimensions.twelve),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
      side: BorderSide(color: Colours.containerOne),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class _DriverSectionTitle extends StatelessWidget {
  const _DriverSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFFE6F1F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colours.blueThree),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colours.primaryOne,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colours.charcoalLight,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DriverMessage extends StatelessWidget {
  const _DriverMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.twelve),
    decoration: BoxDecoration(
      color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFE7F6EC),
      borderRadius: BorderRadius.circular(Dimensions.eight),
    ),
    child: Row(
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: isError ? Colours.errorColour : Colours.green,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}
