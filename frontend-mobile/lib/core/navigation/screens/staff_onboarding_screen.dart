import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/core/auth/providers/auth_provider.dart';
import 'package:smart_solar_mobile/core/navigation/screens/login_screen.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:smart_solar_mobile/core/utils/validators.dart';

class StaffOnboardingScreen extends StatefulWidget {
  const StaffOnboardingScreen({super.key});

  @override
  State<StaffOnboardingScreen> createState() => _StaffOnboardingScreenState();
}

class _StaffOnboardingScreenState extends State<StaffOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  String? _challengeId;
  String? _maskedEmail;
  String? _error;
  bool _busy = false;
  bool _showPassword = false;
  int _resendSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _password.dispose();
    _confirmPassword.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await context
          .read<AuthProvider>()
          .requestStaffOnboarding(_password.text);
      if (!mounted) return;
      setState(() {
        _challengeId = result['challengeId']?.toString();
        _maskedEmail = result['maskedEmail']?.toString();
        _resendSeconds = (result['resendAfterSeconds'] as num?)?.toInt() ?? 60;
        _code.clear();
      });
      _startTimer();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _codeFocus.requestFocus());
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCode() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) {
      setState(
          () => _error = 'Enter the complete six-digit verification code.');
      _codeFocus.requestFocus();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context
          .read<AuthProvider>()
          .confirmStaffOnboarding(_challengeId!, _code.text);
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Account secured. Sign in with your new password.'),
      ));
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: SolarColors.primary),
        filled: true,
        fillColor: SolarColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SolarColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SolarColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SolarColors.primary, width: 1.7),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? '';
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SolarColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Row(children: [
            Icon(Icons.wb_sunny_outlined, color: SolarColors.lime),
            SizedBox(width: 8),
            Text('Secure your account'),
          ]),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: _busy
                  ? null
                  : () async {
                      await context.read<AuthProvider>().logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (_) => false);
                    },
              icon: const Icon(Icons.logout_rounded),
            )
          ],
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [SolarColors.primary, Color(0xff227a67)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified_user_outlined,
                              size: 34, color: Colors.white),
                          SizedBox(height: 14),
                          Text('Complete your first sign-in',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 8),
                          Text(
                              'Replace the temporary password and verify your work email before accessing customer and project data.',
                              style:
                                  TextStyle(color: Colors.white, height: 1.45)),
                        ]),
                  ),
                  const SizedBox(height: 18),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: SolarColors.errorSoft,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: SolarColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: SolarColors.error))),
                          ]),
                    ),
                  if (_error != null) const SizedBox(height: 14),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(color: SolarColors.border),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _challengeId == null
                          ? _passwordStep(email)
                          : _verificationStep(),
                    ),
                  ),
                ]),
          )),
        )),
      ),
    );
  }

  Widget _passwordStep(String email) => Form(
        key: _formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('1. Create a permanent password',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: SolarColors.text)),
          const SizedBox(height: 6),
          Text('A six-digit verification code will be sent to $email.',
              style: const TextStyle(color: SolarColors.muted, height: 1.4)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _password,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.password,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration:
                _decoration('New password', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(_showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPassword,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            validator: (value) => Validators.confirm(value, _password.text),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (_) {
              if (!_busy) _requestCode();
            },
            decoration:
                _decoration('Confirm new password', Icons.lock_reset_outlined),
          ),
          const SizedBox(height: 12),
          const _PasswordRequirements(),
          const SizedBox(height: 20),
          SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _busy ? null : _requestCode,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.mark_email_unread_outlined),
                label: const Text('Send verification code'),
              )),
        ]),
      );

  Widget _verificationStep() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('2. Verify your work email',
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: SolarColors.text)),
        const SizedBox(height: 6),
        Text('Enter the code sent to ${_maskedEmail ?? 'your email address'}.',
            style: const TextStyle(color: SolarColors.muted)),
        const SizedBox(height: 20),
        TextField(
          controller: _code,
          focusNode: _codeFocus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6)
          ],
          onSubmitted: (_) {
            if (!_busy) _confirmCode();
          },
          decoration: _decoration('Six-digit code', Icons.pin_outlined),
        ),
        const SizedBox(height: 18),
        SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _confirmCode,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.verified_outlined),
              label: const Text('Verify and secure account'),
            )),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy || _resendSeconds > 0 ? null : _requestCode,
          child: Text(_resendSeconds > 0
              ? 'Send another code in ${_resendSeconds}s'
              : 'Send another code'),
        ),
        TextButton.icon(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _challengeId = null;
                    _code.clear();
                    _error = null;
                  }),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Change password'),
        ),
      ]);
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: const Color(0xffeef5ea),
            borderRadius: BorderRadius.circular(12)),
        child: const Text(
            'Use 12–64 characters with an uppercase letter, lowercase letter, number and symbol.',
            style: TextStyle(color: SolarColors.text, height: 1.4)),
      );
}
