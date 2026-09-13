import 'package:TaxiApp/src/core/providers/my_profile_provider/my_profile_provider.dart';
import 'package:TaxiApp/src/core/models/travel_log_entry.dart';
import 'package:TaxiApp/src/core/providers/travel_log_provider/travel_log_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/buttons/primary_button.dart';
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
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black26,
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back_rounded),
        color: _ProfileStyles.textPrimary,
      ),
      title: const Text(
        'Profile',
        style: TextStyle(
          color: _ProfileStyles.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
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
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        key: const ValueKey('signed-out-profile'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeHeader(createAccount: _createAccount),
            _ProfileCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _createAccount ? 'Create account' : 'Log in',
                      style: _ProfileStyles.sectionTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _createAccount
                          ? 'Join HambaGo to manage your personal details.'
                          : 'Welcome back. Enter your details to continue.',
                      style: _ProfileStyles.supportingText,
                    ),
                    const SizedBox(height: 20),
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
                        buttonHeight: 50,
                        borderRadius: BorderRadius.circular(10),
                        isLoading: widget.provider.isBusy.value,
                        onTap: _submit,
                      ),
                    ).paddingOnly(top: _createAccount ? 16 : 4),
                    const _OrDivider(),
                    _SocialSignInButton(
                      label: 'Continue with Google',
                      brand: 'G',
                      brandColor: const Color(0xFF4285F4),
                      onPressed: () => widget.provider.signInWithSocialProvider(
                        SocialSignInProvider.google,
                      ),
                    ),
                    _SocialSignInButton(
                      label: 'Continue with Facebook',
                      icon: Icons.facebook,
                      brandColor: _ProfileStyles.blue,
                      onPressed: () => widget.provider.signInWithSocialProvider(
                        SocialSignInProvider.facebook,
                      ),
                    ).paddingOnly(top: Dimensions.eight),
                    _SocialSignInButton(
                      label: 'Continue with Apple',
                      icon: Icons.apple,
                      brandColor: Colors.black,
                      onPressed: () => widget.provider.signInWithSocialProvider(
                        SocialSignInProvider.apple,
                      ),
                    ).paddingOnly(top: Dimensions.eight),
                  ],
                ),
              ),
            ),
            OutlinedButton(
              onPressed: widget.provider.isBusy.value
                  ? null
                  : () => setState(() {
                      _createAccount = !_createAccount;
                      widget.provider.clearMessages();
                    }),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ProfileStyles.blue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _ProfileStyles.blue),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _createAccount
                    ? 'Already have an account? Log in'
                    : 'Create new account',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ).paddingOnly(top: Dimensions.sixteen),
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
        title: const Text('Reset password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Email address'),
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
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        key: ValueKey('profile-${widget.user.uid}'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SignedInHeader(user: widget.user),
            if (widget.user.email != null && !widget.user.emailVerified)
              _EmailVerificationCard(
                onVerify: widget.provider.sendVerificationEmail,
              ).paddingOnly(top: Dimensions.sixteen),
            _TravelLogCard(
              provider: TravelLogProvider.create(),
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
                    const SizedBox(height: 20),
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
                        buttonHeight: 50,
                        borderRadius: BorderRadius.circular(10),
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
            'facebook.com' => 'Facebook',
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
        title: const Text('Change password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New password',
            helperText: 'Use at least 6 characters.',
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

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.createAccount});

  final bool createAccount;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: Dimensions.sixteen),
    padding: const EdgeInsets.all(Dimensions.twenty),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_ProfileStyles.blue, Color(0xFF0A5DC2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const ProfileImage(size: 72),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                createAccount ? 'Join HambaGo' : 'Welcome back',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                createAccount
                    ? 'Create a profile for a more personal journey.'
                    : 'Log in to manage your profile and account.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 14,
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

class _SignedInHeader extends StatelessWidget {
  const _SignedInHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName?.trim();
    return Container(
      padding: const EdgeInsets.all(Dimensions.twenty),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_ProfileStyles.blue, Color(0xFF0A5DC2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const ProfileImage(size: 92, editable: true),
          const SizedBox(width: 18),
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
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
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
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
                      fontSize: 12,
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
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: _ProfileStyles.blueSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _ProfileStyles.blue, size: 21),
      ),
      const SizedBox(width: 12),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: _ProfileStyles.blueSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _ProfileStyles.blue, size: 21),
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
    padding: EdgeInsets.symmetric(vertical: 18),
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
    this.padding = const EdgeInsets.all(Dimensions.sixteen),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _ProfileStyles.border),
    ),
    child: child,
  );
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
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
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
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (provider.entries.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.route_outlined,
                    size: 36,
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
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isComplete ? const Color(0xFFE7F6EC) : const Color(0xFFFFF4D6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isComplete ? Icons.check_rounded : Icons.navigation_rounded,
          color: isComplete ? Colours.green : const Color(0xFF8A5A00),
          size: 21,
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

class _SocialSignInButton extends StatelessWidget {
  const _SocialSignInButton({
    required this.label,
    required this.onPressed,
    required this.brandColor,
    this.icon,
    this.brand,
  });

  final String label;
  final IconData? icon;
  final String? brand;
  final VoidCallback onPressed;
  final Color brandColor;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: _ProfileStyles.textPrimary,
      backgroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      side: const BorderSide(color: _ProfileStyles.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 28,
            child: icon != null
                ? Icon(icon, size: 25, color: brandColor)
                : Text(
                    brand!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: brandColor,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _EmailVerificationCard extends StatelessWidget {
  const _EmailVerificationCard({required this.onVerify});

  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.sixteen),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(12),
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
                style: TextStyle(fontSize: 13),
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
  Widget build(BuildContext context) {
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
  }
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
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _ProfileStyles.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _ProfileStyles.blue, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Colours.errorColour),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Colours.errorColour, width: 2),
  ),
  errorStyle: const TextStyle(color: Colours.errorColour),
);

abstract class _ProfileStyles {
  static const blue = Color(0xFF1877F2);
  static const blueSurface = Color(0xFFE7F3FF);
  static const background = Color(0xFFF0F2F5);
  static const inputBackground = Color(0xFFF7F8FA);
  static const border = Color(0xFFDADDE1);
  static const textPrimary = Color(0xFF1C1E21);
  static const textSecondary = Color(0xFF65676B);

  static const sectionTitle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const supportingText = TextStyle(
    color: textSecondary,
    fontSize: 13,
    height: 1.35,
  );
}
