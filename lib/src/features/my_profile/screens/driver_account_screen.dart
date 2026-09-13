import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:TaxiApp/src/core/providers/driver_account_provider/driver_account_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DriverAccountScreen extends StatefulWidget {
  const DriverAccountScreen({super.key});

  @override
  State<DriverAccountScreen> createState() => _DriverAccountScreenState();
}

class _DriverAccountScreenState extends State<DriverAccountScreen> {
  final DriverAccountProvider _provider = DriverAccountProvider.create();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: AppBar(
      title: const Text(
        'Driver account',
        style: TextStyle(
          color: Colours.primaryOne,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
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
            color: Colours.yellow,
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
                    ? 'Manage your taxi and submit routes for review.'
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
                    subtitle: 'Create and track submitted taxi routes.',
                  ),
                ),
                IconButton.filled(
                  onPressed: () => _showCreateRoute(context),
                  tooltip: 'Create route',
                  icon: const Icon(Icons.add_rounded),
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
            for (final route in provider.routes) _DriverRouteTile(route: route),
        ],
      ),
    ),
  );

  Future<void> _showCreateRoute(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateDriverRouteSheet(provider: provider),
    );
  }
}

class _DriverRouteTile extends StatelessWidget {
  const _DriverRouteTile({required this.route});

  final DriverRoute route;

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
      '${route.serviceDays.join(', ')}'
      '${route.createdAt == null ? '' : ' · ${DateFormat('d MMM').format(route.createdAt!)}'}',
      maxLines: 2,
      style: const TextStyle(fontSize: 11),
    ),
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Pending',
        style: TextStyle(
          color: Color(0xFF8A5A00),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _CreateDriverRouteSheet extends StatefulWidget {
  const _CreateDriverRouteSheet({required this.provider});

  final DriverAccountProvider provider;

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
            const _DriverSectionTitle(
              icon: Icons.add_road_rounded,
              title: 'Create a taxi route',
              subtitle:
                  'Routes are checked before they are added to public journey planning.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _originController,
              textCapitalization: TextCapitalization.words,
              validator: _requiredLocation,
              decoration: const InputDecoration(
                labelText: 'Origin or taxi rank',
                prefixIcon: Icon(Icons.trip_origin_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destinationController,
              textCapitalization: TextCapitalization.words,
              validator: _requiredLocation,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.location_on_outlined),
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
                    onSelected: (selected) => setState(() {
                      selected
                          ? _selectedDays.add(day)
                          : _selectedDays.remove(day);
                    }),
                  ),
              ],
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
              () => FilledButton.icon(
                onPressed: widget.provider.isSaving.value ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  widget.provider.isSaving.value
                      ? 'Validating route…'
                      : 'Submit route',
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
    final saved = await widget.provider.createRoute(
      originName: _originController.text,
      destinationName: _destinationController.text,
      fare: double.parse(_fareController.text),
      serviceDays: _days.where(_selectedDays.contains).toList(growable: false),
      notes: _notesController.text,
    );
    if (saved) {
      Get.back<void>();
    }
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
