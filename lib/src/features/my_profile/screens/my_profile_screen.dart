import 'package:TaxiApp/src/core/providers/my_profile_provider/my_profile_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:TaxiApp/src/core/widgets/buttons/primary_button.dart';
import 'package:TaxiApp/src/features/my_profile/widgets/profile_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final MyProfileProvider _provider = MyProfileProvider.create();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: CustomAppBar(
      backButton: true,
      titleText: 'My profile',
      textColor: Colours.primaryOne,
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
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey('signed-out-profile'),
    padding: const EdgeInsets.all(Dimensions.sixteen),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileImage(size: 92),
        Text(
          _createAccount ? 'Create your HambaGo account' : 'Welcome to HambaGo',
          textAlign: TextAlign.center,
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).paddingOnly(top: Dimensions.sixteen),
        Text(
          'Save your profile and keep your account available across devices.',
          textAlign: TextAlign.center,
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colours.charcoalLight,
          ),
        ).paddingOnly(top: Dimensions.eight, bottom: Dimensions.twentyFour),
        _ProfileCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_createAccount)
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter your name.'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ).paddingOnly(bottom: Dimensions.twelve),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
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
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                      child: const Text('Forgot password?'),
                    ),
                  ),
                Obx(
                  () => PrimaryButton(
                    text: _createAccount ? 'Create account' : 'Sign in',
                    buttonColor: Colours.primaryOne,
                    borderColor: Colours.primaryOne,
                    isLoading: widget.provider.isBusy.value,
                    onTap: _submit,
                  ),
                ).paddingOnly(top: Dimensions.eight),
                TextButton(
                  onPressed: widget.provider.isBusy.value
                      ? null
                      : () => setState(() {
                          _createAccount = !_createAccount;
                          widget.provider.clearMessages();
                        }),
                  child: Text(
                    _createAccount
                        ? 'Already have an account? Sign in'
                        : 'New to HambaGo? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.twelve),
              child: Text('or continue with'),
            ),
            Expanded(child: Divider()),
          ],
        ).paddingSymmetric(vertical: Dimensions.twentyFour),
        _SocialSignInButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          onPressed: () => widget.provider.signInWithSocialProvider(
            SocialSignInProvider.google,
          ),
        ),
        _SocialSignInButton(
          label: 'Continue with Facebook',
          icon: Icons.facebook,
          foregroundColor: const Color(0xFF1877F2),
          onPressed: () => widget.provider.signInWithSocialProvider(
            SocialSignInProvider.facebook,
          ),
        ).paddingOnly(top: Dimensions.eight),
        _SocialSignInButton(
          label: 'Continue with Apple',
          icon: Icons.apple,
          foregroundColor: Colors.black,
          onPressed: () => widget.provider.signInWithSocialProvider(
            SocialSignInProvider.apple,
          ),
        ).paddingOnly(top: Dimensions.eight),
      ],
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
  Widget build(BuildContext context) => SingleChildScrollView(
    key: ValueKey('profile-${widget.user.uid}'),
    padding: const EdgeInsets.all(Dimensions.sixteen),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: ProfileImage(size: 116, editable: true)),
        Text(
          widget.user.displayName?.trim().isNotEmpty == true
              ? widget.user.displayName!
              : 'HambaGo traveller',
          textAlign: TextAlign.center,
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).paddingOnly(top: Dimensions.sixteen),
        Text(
          widget.user.email ?? '',
          textAlign: TextAlign.center,
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colours.charcoalLight,
          ),
        ).paddingOnly(bottom: Dimensions.twentyFour),
        if (widget.user.email != null && !widget.user.emailVerified)
          _EmailVerificationCard(
            onVerify: widget.provider.sendVerificationEmail,
          ).paddingOnly(bottom: Dimensions.sixteen),
        _ProfileCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Account details',
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).paddingOnly(bottom: Dimensions.sixteen),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Enter your name.'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ).paddingOnly(bottom: Dimensions.twelve),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email address.'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ).paddingOnly(bottom: Dimensions.sixteen),
                Obx(
                  () => PrimaryButton(
                    text: 'Save changes',
                    buttonColor: Colours.primaryOne,
                    borderColor: Colours.primaryOne,
                    isLoading: widget.provider.isBusy.value,
                    onTap: _saveProfile,
                  ),
                ),
              ],
            ),
          ),
        ),
        _ProfileCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Security',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).paddingOnly(bottom: Dimensions.eight),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset),
                title: const Text('Change password'),
                subtitle: const Text(
                  'Available for accounts that use email and password.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _supportsPasswordSignIn ? _showChangePassword : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Sign-in methods'),
                subtitle: Text(_providerNames),
              ),
            ],
          ),
        ).paddingOnly(top: Dimensions.sixteen),
        OutlinedButton.icon(
          onPressed: widget.provider.isBusy.value
              ? null
              : widget.provider.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colours.errorColour,
            side: const BorderSide(color: Colours.errorColour),
          ),
        ).paddingOnly(top: Dimensions.sixteen),
      ],
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.sixteen),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(Dimensions.sixteen),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class _SocialSignInButton extends StatelessWidget {
  const _SocialSignInButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.foregroundColor = Colors.black,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 26),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      side: const BorderSide(color: Colours.containerOne),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.eight),
      ),
    ),
  );
}

class _EmailVerificationCard extends StatelessWidget {
  const _EmailVerificationCard({required this.onVerify});

  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.twelve),
    decoration: BoxDecoration(
      color: Colours.yellow.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(Dimensions.eight),
    ),
    child: Row(
      children: [
        const Icon(Icons.mark_email_unread_outlined),
        Expanded(
          child: const Text(
            'Verify your email address to secure your account.',
          ).paddingOnly(left: Dimensions.eight),
        ),
        TextButton(onPressed: onVerify, child: const Text('Send email')),
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
          ? Colours.green.withValues(alpha: 0.12)
          : Colours.errorColour.withValues(alpha: 0.1),
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
