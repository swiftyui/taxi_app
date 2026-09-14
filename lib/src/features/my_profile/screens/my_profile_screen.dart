import 'package:TaxiApp/src/core/models/travel_log_entry.dart';
import 'package:TaxiApp/src/core/providers/hamba_points_provider/hamba_points_provider.dart';
import 'package:TaxiApp/src/core/providers/driver_account_provider/driver_account_provider.dart';
import 'package:TaxiApp/src/core/providers/favorite_routes_provider/favorite_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/my_profile_provider/my_profile_provider.dart';
import 'package:TaxiApp/src/core/providers/ride_requests_provider/ride_requests_provider.dart';
import 'package:TaxiApp/src/core/providers/safety_provider/safety_provider.dart';
import 'package:TaxiApp/src/core/providers/saved_places_provider/saved_places_provider.dart';
import 'package:TaxiApp/src/core/providers/travel_log_provider/travel_log_provider.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/buttons/primary_button.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:TaxiApp/src/core/widgets/loaders/hambago_shimmer.dart';
import 'package:TaxiApp/src/features/my_profile/widgets/profile_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final MyProfileProvider _provider = MyProfileProvider.create();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _ProfileStyles.background,
    appBar: const HambaGoAppBar(
      title: 'Profile',
      subtitle: 'Account, rewards, and travel',
    ),
    body: Obx(() {
      final user = _provider.user.value;
      return SafeArea(
        top: false,
        child: Column(
          children: [
            _ProfileMessageBanner(provider: _provider),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: user == null
                    ? _SignedOutProfile(provider: _provider)
                    : _SignedInProfile(provider: _provider, user: user),
              ),
            ),
          ],
        ),
      );
    }),
  );
}

class _SignedOutProfile extends StatefulWidget {
  const _SignedOutProfile({required this.provider});

  final MyProfileProvider provider;

  @override
  State<_SignedOutProfile> createState() => _SignedOutProfileState();
}

class _SignedOutProfileState extends State<_SignedOutProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _createAccount = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        key: const ValueKey('signed-out-profile'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthProfileHero(createAccount: _createAccount),
            _ProfileCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthModeSelector(
                      createAccount: _createAccount,
                      onChanged: (createAccount) => setState(() {
                        _createAccount = createAccount;
                        widget.provider.clearMessages();
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _createAccount ? 'Create your account' : 'Welcome back',
                      style: _ProfileStyles.sectionTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _createAccount
                          ? 'Save your details and keep your journeys synced.'
                          : 'Log in to manage your profile and travel history.',
                      style: _ProfileStyles.supportingText,
                    ),
                    const SizedBox(height: 14),
                    if (_createAccount)
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Enter your name.'
                            : null,
                        decoration: _profileInputDecoration(
                          label: 'Full name',
                          icon: Icons.person_outline_rounded,
                        ),
                      ).paddingOnly(bottom: Dimensions.twelve),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                      decoration: _profileInputDecoration(
                        label: 'Email address',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ).paddingOnly(bottom: Dimensions.twelve),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: [
                        _createAccount
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      validator: (value) => value == null || value.length < 6
                          ? 'Password must be at least 6 characters.'
                          : null,
                      decoration: _profileInputDecoration(
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (!_createAccount)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showPasswordReset,
                          style: TextButton.styleFrom(
                            foregroundColor: _ProfileStyles.blue,
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    Obx(
                      () => PrimaryButton(
                        text: _createAccount ? 'Create account' : 'Log in',
                        buttonColor: _ProfileStyles.blue,
                        borderColor: _ProfileStyles.blue,
                        buttonHeight: 44,
                        borderRadius: BorderRadius.circular(Dimensions.eight),
                        isLoading: widget.provider.isBusy.value,
                        onTap: _submit,
                      ),
                    ).paddingOnly(top: _createAccount ? 16 : 4),
                    const _OrDivider(),
                    Obx(
                      () => _ProviderSignInButton(
                        provider: SocialSignInProvider.google,
                        isLoading:
                            widget.provider.activeSocialProvider.value ==
                            SocialSignInProvider.google,
                        isDisabled: widget.provider.isBusy.value,
                        onPressed: widget.provider.signInWithGoogle,
                      ),
                    ),
                    Obx(
                      () => _ProviderSignInButton(
                        provider: SocialSignInProvider.apple,
                        isLoading:
                            widget.provider.activeSocialProvider.value ==
                            SocialSignInProvider.apple,
                        isDisabled: widget.provider.isBusy.value,
                        onPressed: widget.provider.signInWithApple,
                      ),
                    ).paddingOnly(top: Dimensions.eight),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: _ProfileStyles.textSecondary,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Secure sign-in powered by Firebase',
                          style: TextStyle(
                            color: _ProfileStyles.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ).paddingOnly(top: Dimensions.twelve),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_createAccount) {
      await widget.provider.createAccount(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      await widget.provider.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  Future<void> _showPasswordReset() async {
    final emailController = TextEditingController(text: _emailController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const _DialogTitle(
          icon: Icons.lock_reset_rounded,
          title: 'Reset password',
          subtitle: 'We will send a reset link to your email address.',
        ),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: _profileInputDecoration(
            label: 'Email address',
            icon: Icons.mail_outline_rounded,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, emailController.text),
            child: const Text('Send reset email'),
          ),
        ],
      ),
    );
    emailController.dispose();
    if (result != null && _validateEmail(result) == null) {
      await widget.provider.sendPasswordReset(result);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }
}

class _SignedInProfile extends StatefulWidget {
  const _SignedInProfile({required this.provider, required this.user});

  final MyProfileProvider provider;
  final User user;

  @override
  State<_SignedInProfile> createState() => _SignedInProfileState();
}

class _SignedInProfileState extends State<_SignedInProfile> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant _SignedInProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _nameController.text = widget.user.displayName ?? '';
    _emailController.text = widget.user.email ?? '';
  }

  void _initializeControllers() {
    _nameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        key: ValueKey('profile-${widget.user.uid}'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SignedInHeader(user: widget.user),
            _HambaPointsCard(
              provider: HambaPointsProvider.create(),
            ).paddingOnly(top: Dimensions.twelve),
            if (widget.user.email != null && !widget.user.emailVerified)
              _EmailVerificationCard(
                onVerify: widget.provider.sendVerificationEmail,
              ).paddingOnly(top: Dimensions.sixteen),
            _TravelLogCard(
              provider: TravelLogProvider.create(),
            ).paddingOnly(top: Dimensions.sixteen),
            _FavoriteRoutesProfileCard(
              provider: FavoriteRoutesProvider.create(),
            ).paddingOnly(top: Dimensions.sixteen),
            _SavedPlacesProfileCard(
              provider: SavedPlacesProvider.create(),
            ).paddingOnly(top: Dimensions.sixteen),
            _SafetyProfileCard(
              provider: SafetyProvider.create(),
            ).paddingOnly(top: Dimensions.sixteen),
            _RideRequestsProfileCard(
              provider: RideRequestsProvider.create(),
            ).paddingOnly(top: Dimensions.sixteen),
            _DriverAccountCard(
              provider: DriverAccountProvider.create(),
            ).paddingOnly(top: Dimensions.sixteen),
            _ProfileCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeading(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal details',
                      subtitle: 'Update how your profile appears.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? 'Enter your name.'
                          : null,
                      decoration: _profileInputDecoration(
                        label: 'Full name',
                        icon: Icons.person_outline_rounded,
                      ),
                    ).paddingOnly(bottom: Dimensions.twelve),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid email address.'
                          : null,
                      decoration: _profileInputDecoration(
                        label: 'Email address',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ).paddingOnly(bottom: Dimensions.sixteen),
                    Obx(
                      () => PrimaryButton(
                        text: 'Save changes',
                        buttonColor: _ProfileStyles.blue,
                        borderColor: _ProfileStyles.blue,
                        buttonHeight: 44,
                        borderRadius: BorderRadius.circular(Dimensions.eight),
                        isLoading: widget.provider.isBusy.value,
                        onTap: _saveProfile,
                      ),
                    ),
                  ],
                ),
              ),
            ).paddingOnly(top: Dimensions.sixteen),
            _ProfileCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _SectionHeading(
                      icon: Icons.shield_outlined,
                      title: 'Security and login',
                      subtitle: 'Manage how you access your account.',
                    ),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change password',
                    subtitle: _supportsPasswordSignIn
                        ? 'Choose a new account password'
                        : 'Available for email accounts',
                    onTap: _supportsPasswordSignIn ? _showChangePassword : null,
                  ),
                  const Divider(height: 1, indent: 64),
                  _SettingsTile(
                    icon: Icons.key_rounded,
                    title: 'Sign-in methods',
                    subtitle: _providerNames,
                  ),
                ],
              ),
            ).paddingOnly(top: Dimensions.sixteen),
            TextButton.icon(
              onPressed: widget.provider.isBusy.value
                  ? null
                  : widget.provider.signOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
              style: TextButton.styleFrom(
                foregroundColor: Colours.errorColour,
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ).paddingOnly(top: Dimensions.sixteen),
          ],
        ),
      ),
    ),
  );

  bool get _supportsPasswordSignIn => widget.user.providerData.any(
    (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
  );

  String get _providerNames {
    final names = widget.user.providerData
        .map(
          (provider) => switch (provider.providerId) {
            'password' => 'Email and password',
            'google.com' => 'Google',
            'apple.com' => 'Apple',
            _ => provider.providerId,
          },
        )
        .toSet();
    return names.isEmpty ? 'Firebase account' : names.join(', ');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await widget.provider.updateAccountDetails(
      name: _nameController.text,
      email: _emailController.text,
    );
  }

  Future<void> _showChangePassword() async {
    final passwordController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const _DialogTitle(
          icon: Icons.password_rounded,
          title: 'Change password',
          subtitle: 'Choose a secure password with at least 6 characters.',
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: _profileInputDecoration(
            label: 'New password',
            icon: Icons.lock_outline_rounded,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text('Update password'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    if (result != null && result.length >= 6) {
      await widget.provider.updatePassword(result);
    }
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({
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
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: _ProfileStyles.blueSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _ProfileStyles.blue, size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _ProfileStyles.sectionTitle),
            const SizedBox(height: 2),
            Text(subtitle, style: _ProfileStyles.supportingText),
          ],
        ),
      ),
    ],
  );
}

class _AuthProfileHero extends StatelessWidget {
  const _AuthProfileHero({required this.createAccount});

  final bool createAccount;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.bottomCenter,
    clipBehavior: Clip.none,
    children: [
      Container(
        width: double.infinity,
        height: 142,
        margin: const EdgeInsets.only(bottom: 36),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colours.primaryOne, Colours.blueThree],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Dimensions.eight),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 42),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                createAccount ? 'Join HambaGo' : 'Welcome to HambaGo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                createAccount
                    ? 'Create your travel profile'
                    : 'Your taxi journeys, in one place',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colours.primaryOne.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const ProfileImage(size: 70),
      ),
    ],
  ).paddingOnly(bottom: Dimensions.twelve);
}

class _AuthModeSelector extends StatelessWidget {
  const _AuthModeSelector({
    required this.createAccount,
    required this.onChanged,
  });

  final bool createAccount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Colours.searchBarBackground,
      borderRadius: BorderRadius.circular(Dimensions.eight),
    ),
    child: Row(
      children: [
        Expanded(
          child: _AuthModeOption(
            label: 'Log in',
            selected: !createAccount,
            onTap: () => onChanged(false),
          ),
        ),
        Expanded(
          child: _AuthModeOption(
            label: 'Create account',
            selected: createAccount,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    ),
  );
}

class _AuthModeOption extends StatelessWidget {
  const _AuthModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? Colors.white : Colors.transparent,
    borderRadius: BorderRadius.circular(6),
    elevation: selected ? 1 : 0,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colours.blueThree : Colours.charcoalLight,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

class _SignedInHeader extends StatelessWidget {
  const _SignedInHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName?.trim();
    return Container(
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
          const ProfileImage(size: 76, editable: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName?.isNotEmpty == true
                      ? displayName!
                      : 'HambaGo traveller',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                if (user.email?.isNotEmpty == true) ...[
                  const SizedBox(height: 7),
                  Text(
                    user.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.emailVerified
                        ? 'Verified account'
                        : 'Email unverified',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
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
          color: _ProfileStyles.blueSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _ProfileStyles.blue, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _ProfileStyles.sectionTitle),
            const SizedBox(height: 2),
            Text(subtitle, style: _ProfileStyles.supportingText),
          ],
        ),
      ),
    ],
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    leading: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: _ProfileStyles.blueSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _ProfileStyles.blue, size: 18),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: _ProfileStyles.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      subtitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: _ProfileStyles.supportingText,
    ),
    trailing: onTap == null
        ? null
        : const Icon(
            Icons.chevron_right_rounded,
            color: _ProfileStyles.textSecondary,
          ),
    onTap: onTap,
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Expanded(child: Divider(color: _ProfileStyles.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(color: _ProfileStyles.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: _ProfileStyles.border)),
      ],
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.child,
    this.padding = const EdgeInsets.all(Dimensions.twelve),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 1,
    shadowColor: Colours.primaryOne.withValues(alpha: 0.18),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
      side: BorderSide(color: _ProfileStyles.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class _HambaPointsCard extends StatelessWidget {
  const _HambaPointsCard({required this.provider});

  final HambaPointsProvider provider;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF8E5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Dimensions.eight),
      side: const BorderSide(color: Color(0xFFF0D88B)),
    ),
    child: InkWell(
      onTap: provider.reloadPoints,
      borderRadius: BorderRadius.circular(Dimensions.eight),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.twelve),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colours.yellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colours.primaryOne,
                size: 22,
              ),
            ),
            const SizedBox(width: Dimensions.twelve),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HambaPoints',
                    style: TextStyle(
                      color: Colours.primaryOne,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Earn rewards by helping the taxi community.',
                    style: TextStyle(
                      color: Colours.charcoalLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => provider.isLoading.value
                  ? const HambaGoShimmer(
                      child: ShimmerBlock(width: 38, height: 24, radius: 12),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${provider.points.value}',
                          style: const TextStyle(
                            color: Colours.primaryOne,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'points',
                          style: TextStyle(
                            color: Colours.charcoalLight,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RideRequestsProfileCard extends StatelessWidget {
  const _RideRequestsProfileCard({required this.provider});

  final RideRequestsProvider provider;

  @override
  Widget build(BuildContext context) => Obx(
    () => _ProfileCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Get.toNamed<void>(AppRoutes.rideRequests.value),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.twelve),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F1F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hail_rounded,
                  color: Colours.blueThree,
                  size: 22,
                ),
              ),
              const SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My ride requests',
                      style: TextStyle(
                        color: Colours.primaryOne,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.myRequests.isEmpty
                          ? 'View and manage rides you request.'
                          : '${provider.myRequests.length} request'
                                '${provider.myRequests.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colours.charcoalLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colours.charcoalLight,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FavoriteRoutesProfileCard extends StatelessWidget {
  const _FavoriteRoutesProfileCard({required this.provider});

  final FavoriteRoutesProvider provider;

  @override
  Widget build(BuildContext context) => Obx(
    () => _ProfileCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Get.toNamed<void>(AppRoutes.favoriteRoutes.value),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.twelve),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF2D0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colours.red,
                  size: 21,
                ),
              ),
              const SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Favourite routes',
                      style: TextStyle(
                        color: Colours.primaryOne,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.favorites.isEmpty
                          ? 'Keep your regular routes easy to find.'
                          : '${provider.favorites.length} saved route'
                                '${provider.favorites.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colours.charcoalLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colours.charcoalLight,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SavedPlacesProfileCard extends StatelessWidget {
  const _SavedPlacesProfileCard({required this.provider});

  final SavedPlacesProvider provider;

  @override
  Widget build(BuildContext context) => Obx(
    () => _ProfileShortcutCard(
      icon: Icons.bookmark_rounded,
      iconColor: Colours.blueThree,
      iconBackground: const Color(0xFFE6F1F5),
      title: 'Saved places',
      subtitle: provider.places.isEmpty
          ? 'Add Home, Work, and regular destinations.'
          : '${provider.places.length} saved place'
                '${provider.places.length == 1 ? '' : 's'}',
      onTap: () => Get.toNamed<void>(AppRoutes.savedPlaces.value),
    ),
  );
}

class _SafetyProfileCard extends StatelessWidget {
  const _SafetyProfileCard({required this.provider});

  final SafetyProvider provider;

  @override
  Widget build(BuildContext context) => Obx(
    () => _ProfileShortcutCard(
      icon: Icons.health_and_safety_rounded,
      iconColor: Colours.red,
      iconBackground: const Color(0xFFFFEBEE),
      title: 'Safety toolkit',
      subtitle: provider.contacts.isEmpty
          ? 'Add emergency contacts and share journeys.'
          : '${provider.contacts.length} emergency contact'
                '${provider.contacts.length == 1 ? '' : 's'} ready',
      onTap: () => Get.toNamed<void>(AppRoutes.safetyToolkit.value),
    ),
  );
}

class _ProfileShortcutCard extends StatelessWidget {
  const _ProfileShortcutCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ProfileCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.twelve),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 21),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colours.charcoalLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colours.charcoalLight,
            ),
          ],
        ),
      ),
    ),
  );
}

class _DriverAccountCard extends StatelessWidget {
  const _DriverAccountCard({required this.provider});

  final DriverAccountProvider provider;

  @override
  Widget build(BuildContext context) => Obx(() {
    final profile = provider.profile.value;
    final routeCount = provider.routes.length;
    return _ProfileCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.driverAccount.value),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.twelve),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  color: Color(0xFF8A5A00),
                  size: 22,
                ),
              ),
              const SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile == null ? 'Become a driver' : 'Driver account',
                      style: const TextStyle(
                        color: Colours.primaryOne,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile == null
                          ? 'Register your taxi and create new routes.'
                          : '${profile.vehicleRegistration} · '
                                '$routeCount submitted '
                                'route${routeCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colours.charcoalLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colours.charcoalLight,
              ),
            ],
          ),
        ),
      ),
    );
  });
}

class _TravelLogCard extends StatelessWidget {
  const _TravelLogCard({required this.provider});

  final TravelLogProvider provider;

  @override
  Widget build(BuildContext context) => _ProfileCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 6),
          child: Row(
            children: [
              const Expanded(
                child: _SectionHeading(
                  icon: Icons.history_rounded,
                  title: 'Travel log',
                  subtitle: 'Your taxi journeys, all in one place.',
                ),
              ),
              IconButton(
                onPressed: provider.reloadEntries,
                tooltip: 'Refresh travel log',
                icon: const Icon(Icons.refresh_rounded),
                color: _ProfileStyles.blue,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Obx(() {
          if (provider.isLoading.value && provider.entries.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (provider.entries.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.route_outlined,
                    size: 30,
                    color: _ProfileStyles.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No journeys yet',
                    style: TextStyle(
                      color: _ProfileStyles.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Trips appear here when you start a taxi journey.',
                    textAlign: TextAlign.center,
                    style: _ProfileStyles.supportingText,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              for (var index = 0; index < provider.entries.length; index++) ...[
                _TravelLogTile(entry: provider.entries[index]),
                if (index < provider.entries.length - 1)
                  const Divider(height: 1, indent: 64),
              ],
              if (provider.errorMessage.value != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    provider.errorMessage.value!,
                    style: const TextStyle(
                      color: Colours.errorColour,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    ),
  );
}

class _TravelLogTile extends StatelessWidget {
  const _TravelLogTile({required this.entry});

  final TravelLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final isComplete = entry.status == TravelLogStatus.completed;
    final totalFare = entry.routes.fold<double>(
      0,
      (total, route) => total + route.fare,
    );
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isComplete ? const Color(0xFFE7F6EC) : const Color(0xFFFFF4D6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isComplete ? Icons.check_rounded : Icons.navigation_rounded,
          color: isComplete ? Colours.green : const Color(0xFF8A5A00),
          size: 18,
        ),
      ),
      title: Text(
        entry.destinationName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ProfileStyles.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        '${DateFormat('d MMM yyyy, HH:mm').format(entry.startedAt.toLocal())}'
        ' · ${entry.routes.length} taxi '
        'route${entry.routes.length == 1 ? '' : 's'}',
        maxLines: 2,
        style: _ProfileStyles.supportingText,
      ),
      children: [
        Row(
          children: [
            _TravelLogStatus(
              label: isComplete ? 'Completed' : 'In progress',
              isComplete: isComplete,
            ),
            const Spacer(),
            if (totalFare > 0)
              Text(
                'Listed fare R${totalFare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < entry.routes.length; index++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: _ProfileStyles.blueSurface,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: _ProfileStyles.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.routes[index].originName} to '
                      '${entry.routes[index].destinationName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (entry.routes[index].associationName.isNotEmpty)
                      Text(
                        entry.routes[index].associationName,
                        style: _ProfileStyles.supportingText,
                      ),
                  ],
                ),
              ),
            ],
          ).paddingOnly(bottom: 8),
      ],
    );
  }
}

class _TravelLogStatus extends StatelessWidget {
  const _TravelLogStatus({required this.label, required this.isComplete});

  final String label;
  final bool isComplete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: isComplete ? const Color(0xFFE7F6EC) : const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: isComplete ? Colours.green : const Color(0xFF8A5A00),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ProviderSignInButton extends StatelessWidget {
  const _ProviderSignInButton({
    required this.provider,
    required this.onPressed,
    required this.isLoading,
    required this.isDisabled,
  });

  final SocialSignInProvider provider;
  final Future<bool> Function() onPressed;
  final bool isLoading;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final isApple = provider == SocialSignInProvider.apple;
    final foregroundColor = isApple ? Colors.white : Colours.primaryOne;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isDisabled && !isLoading ? 0.55 : 1,
      child: Material(
        color: isApple ? Colours.primaryOne : Colors.white,
        elevation: isApple ? 0 : 1,
        shadowColor: Colours.primaryOne.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isApple ? Colours.primaryOne : const Color(0xFFD8E1E4),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 9),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isApple
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFF3F7F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foregroundColor,
                          ),
                        )
                      : Icon(
                          isApple ? Icons.apple : Icons.g_mobiledata_rounded,
                          color: isApple
                              ? Colors.white
                              : const Color(0xFF4285F4),
                          size: isApple ? 23 : 30,
                        ),
                ),
                Expanded(
                  child: Text(
                    isApple ? 'Continue with Apple' : 'Continue with Google',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: foregroundColor.withValues(alpha: 0.62),
                  size: 18,
                ),
                const SizedBox(width: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailVerificationCard extends StatelessWidget {
  const _EmailVerificationCard({required this.onVerify});

  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.twelve),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(Dimensions.eight),
      border: Border.all(color: const Color(0xFFFFD66B)),
    ),
    child: Row(
      children: [
        const Icon(Icons.mark_email_unread_outlined, color: Color(0xFF8A5A00)),
        Expanded(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify your email',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'Confirm your address to secure your account.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ).paddingOnly(left: Dimensions.twelve),
        ),
        TextButton(
          onPressed: onVerify,
          style: TextButton.styleFrom(foregroundColor: _ProfileStyles.blue),
          child: const Text('Send'),
        ),
      ],
    ),
  );
}

class _ProfileMessageBanner extends StatelessWidget {
  const _ProfileMessageBanner({required this.provider});

  final MyProfileProvider provider;

  @override
  Widget build(BuildContext context) => Obx(() {
    final error = provider.errorMessage.value;
    final success = provider.successMessage.value;
    if (error == null && success == null) {
      return const SizedBox.shrink();
    }

    return MaterialBanner(
      backgroundColor: error == null
          ? const Color(0xFFE7F3FF)
          : const Color(0xFFFFEBEE),
      content: Text(error ?? success!),
      leading: Icon(
        error == null ? Icons.check_circle_outline : Icons.error_outline,
        color: error == null ? Colours.green : Colours.errorColour,
      ),
      actions: [
        TextButton(
          onPressed: provider.clearMessages,
          child: const Text('Dismiss'),
        ),
      ],
    );
  });
}

InputDecoration _profileInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: _ProfileStyles.textSecondary),
  floatingLabelStyle: const TextStyle(color: _ProfileStyles.blue),
  filled: true,
  fillColor: _ProfileStyles.inputBackground,
  prefixIcon: Icon(icon, color: _ProfileStyles.textSecondary, size: 21),
  suffixIcon: suffixIcon,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(Dimensions.eight),
    borderSide: const BorderSide(color: _ProfileStyles.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(Dimensions.eight),
    borderSide: const BorderSide(color: _ProfileStyles.blue, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(Dimensions.eight),
    borderSide: const BorderSide(color: Colours.errorColour),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(Dimensions.eight),
    borderSide: const BorderSide(color: Colours.errorColour, width: 1.5),
  ),
  errorStyle: const TextStyle(color: Colours.errorColour),
);

abstract class _ProfileStyles {
  static const blue = Colours.blueThree;
  static const blueSurface = Color(0xFFE6F1F5);
  static const background = Colours.lightSurface;
  static const inputBackground = Colours.searchBarBackground;
  static const border = Colours.containerOne;
  static const textPrimary = Colours.primaryOne;
  static const textSecondary = Colours.charcoalLight;

  static const sectionTitle = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const supportingText = TextStyle(
    color: textSecondary,
    fontSize: 12,
    height: 1.35,
  );
}
