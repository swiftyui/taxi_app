import 'package:TaxiApp/src/core/models/emergency_contact.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/safety_provider/safety_provider.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SafetyToolkitScreen extends StatelessWidget {
  SafetyToolkitScreen({super.key});

  final SafetyProvider _provider = SafetyProvider.create();
  final ActionsProvider _actionsProvider = ActionsProvider.create();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: const HambaGoAppBar(
      title: 'Safety toolkit',
      subtitle: 'Share your journey and reach help quickly',
    ),
    body: Obx(
      () => ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          _SafetyHero(
            hasJourney: _actionsProvider.journey.value != null,
            onShare: () => _shareJourney(context),
            onSos: () => _confirmSos(context),
            onCall: () => _confirmEmergencyCall(context),
          ),
          if (_provider.errorMessage.value != null)
            _SafetyMessage(
              message: _provider.errorMessage.value!,
              onDismiss: () => _provider.errorMessage.value = null,
            ).paddingOnly(top: Dimensions.twelve),
          _ContactsCard(
            provider: _provider,
            onAdd: () => _showContactDialog(context),
            onEdit: (contact) => _showContactDialog(context, contact: contact),
            onDelete: (contact) => _confirmDelete(context, contact),
          ).paddingOnly(top: Dimensions.twelve),
          const _SafetyDisclaimer().paddingOnly(top: Dimensions.twelve),
        ],
      ),
    ),
  );

  Future<void> _shareJourney(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await _provider.shareJourney(
      shareOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _confirmSos(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.sixteen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.sos_rounded, color: Colours.red, size: 42),
              const Text(
                'Send an SOS message?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colours.primaryOne,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _provider.primaryContact == null
                    ? 'Add an emergency contact first.'
                    : 'This opens a prefilled SMS to '
                          '${_provider.primaryContact!.name} with your '
                          'journey and current location. You must press Send.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colours.charcoalLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _provider.primaryContact == null
                    ? null
                    : () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colours.red),
                child: const Text('Open emergency message'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await _provider.sendSos();
    }
  }

  Future<void> _confirmEmergencyCall(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call emergency services?'),
        content: const Text(
          'This will open the phone app with South Africa’s mobile emergency number, 112.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colours.red),
            icon: const Icon(Icons.call_rounded),
            label: const Text('Call 112'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _provider.callEmergencyServices();
    }
  }

  Future<void> _showContactDialog(
    BuildContext context, {
    EmergencyContact? contact,
  }) async {
    if (!_provider.isSignedIn) {
      await Get.toNamed<void>(AppRoutes.myProfile.value);
      return;
    }
    final nameController = TextEditingController(text: contact?.name);
    final phoneController = TextEditingController(text: contact?.phoneNumber);
    final relationshipController = TextEditingController(
      text: contact?.relationship,
    );
    var isPrimary = contact?.isPrimary ?? _provider.contacts.isEmpty;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            contact == null ? 'Add emergency contact' : 'Edit contact',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter the contact name.'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        (value ?? '').replaceAll(RegExp(r'[^0-9]'), '').length <
                            10
                        ? 'Enter a valid phone number.'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: relationshipController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'Family, friend, partner',
                      prefixIcon: Icon(Icons.people_outline_rounded),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Primary SOS contact'),
                    subtitle: const Text('Receives your prefilled SOS message'),
                    value: isPrimary,
                    onChanged: (value) =>
                        setDialogState(() => isPrimary = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save contact'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      await _provider.saveContact(
        id: contact?.id,
        name: nameController.text,
        phoneNumber: phoneController.text,
        relationship: relationshipController.text,
        isPrimary: isPrimary,
      );
    }
    nameController.dispose();
    phoneController.dispose();
    relationshipController.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove emergency contact?'),
        content: Text('${contact.name} will no longer be available for SOS.'),
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
      await _provider.deleteContact(contact);
    }
  }
}

class _SafetyHero extends StatelessWidget {
  const _SafetyHero({
    required this.hasJourney,
    required this.onShare,
    required this.onSos,
    required this.onCall,
  });

  final bool hasJourney;
  final VoidCallback onShare;
  final VoidCallback onSos;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colours.primaryOne, Colours.blueThree],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colours.blueThree.withValues(alpha: 0.2),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: hasJourney
                    ? Colours.green.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasJourney
                        ? Icons.radio_button_checked_rounded
                        : Icons.route_outlined,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    hasJourney ? 'Journey ready' : 'No active journey',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Travel with confidence',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasJourney
              ? 'Share your current progress or quickly reach someone you trust.'
              : 'Plan a journey to share your route and current location.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 11,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        _SosAction(onTap: onSos),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SafetyQuickAction(
                icon: Icons.ios_share_rounded,
                title: 'Share journey',
                subtitle: 'Send route & progress',
                onTap: hasJourney ? onShare : null,
                backgroundColor: Colors.white,
                foregroundColor: Colours.blueThree,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SafetyQuickAction(
                icon: Icons.call_rounded,
                title: 'Call 112',
                subtitle: 'Emergency services',
                onTap: onCall,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                borderColor: Colors.white.withValues(alpha: 0.24),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SosAction extends StatelessWidget {
  const _SosAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colours.red,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: const SizedBox(
        height: 58,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.sos_rounded, color: Colors.white, size: 26),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send an SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Message your primary emergency contact',
                      style: TextStyle(color: Colors.white70, fontSize: 9),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SafetyQuickAction extends StatelessWidget {
  const _SafetyQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: onTap == null ? 0.48 : 1,
    duration: const Duration(milliseconds: 180),
    child: Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, color: foregroundColor, size: 21),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foregroundColor.withValues(alpha: 0.66),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({
    required this.provider,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final SafetyProvider provider;
  final VoidCallback onAdd;
  final ValueChanged<EmergencyContact> onEdit;
  final ValueChanged<EmergencyContact> onDelete;

  @override
  Widget build(BuildContext context) => Obx(() {
    final contacts = provider.contacts.toList(growable: false);
    final isLoading = provider.isLoading.value;
    final isSignedIn = provider.isSignedIn;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7EA)),
        boxShadow: [
          BoxShadow(
            color: Colours.primaryOne.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 8, 11),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F1F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.contact_emergency_outlined,
                    color: Colours.blueThree,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency contacts',
                        style: TextStyle(
                          color: Colours.primaryOne,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isSignedIn
                            ? '${contacts.length} trusted contact'
                                  '${contacts.length == 1 ? '' : 's'}'
                            : 'Sign in to sync trusted contacts',
                        style: const TextStyle(
                          color: Colours.charcoalLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  tooltip: 'Add emergency contact',
                  icon: const Icon(Icons.add_rounded, size: 20),
                  color: Colours.blueThree,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE6F1F5),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const LinearProgressIndicator(
              color: Colours.blueThree,
              minHeight: 2,
            )
          else if (contacts.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colours.lightSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Add someone you trust',
                    style: TextStyle(
                      color: Colours.primaryOne,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Your primary contact can receive a prefilled SOS with your route and location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colours.charcoalLight,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onAdd,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colours.blueThree,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        isSignedIn
                            ? Icons.person_add_alt_rounded
                            : Icons.login_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isSignedIn ? 'Add trusted contact' : 'Sign in to add',
                      ),
                    ),
                  ).paddingOnly(top: 10),
                ],
              ),
            )
          else
            for (final contact in contacts) ...[
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: contact.isPrimary
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE6F1F5),
                  child: Icon(
                    contact.isPrimary
                        ? Icons.shield_rounded
                        : Icons.person_outline_rounded,
                    color: contact.isPrimary ? Colours.red : Colours.blueThree,
                  ),
                ),
                title: Text(contact.name),
                subtitle: Text(
                  [
                    contact.phoneNumber,
                    if (contact.relationship.isNotEmpty) contact.relationship,
                    if (contact.isPrimary) 'Primary',
                  ].join(' · '),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) =>
                      value == 'edit' ? onEdit(contact) : onDelete(contact),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  });
}

class _SafetyMessage extends StatelessWidget {
  const _SafetyMessage({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => MaterialBanner(
    content: Text(message),
    leading: const Icon(Icons.error_outline, color: Colours.errorColour),
    actions: [TextButton(onPressed: onDismiss, child: const Text('Dismiss'))],
  );
}

class _SafetyDisclaimer extends StatelessWidget {
  const _SafetyDisclaimer();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.twelve),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2F5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: Colours.blueThree, size: 17),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'HambaGo does not automatically contact emergency services or send '
            'messages. Your phone will always ask you to confirm.',
            style: TextStyle(
              color: Colours.charcoalLight,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
