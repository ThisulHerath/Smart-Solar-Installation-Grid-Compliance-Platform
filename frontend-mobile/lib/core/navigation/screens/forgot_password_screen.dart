import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smart_solar_mobile/core/api/api_service.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:smart_solar_mobile/core/utils/validators.dart';
import 'package:smart_solar_mobile/core/widgets/solar_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final ApiService? api;

  const ForgotPasswordScreen({super.key, this.api});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();

  String? _challengeId;
  String? _maskedEmail;
  String? _error;
  String? _notice;
  bool _busy = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _complete = false;
  int _resendSeconds = 0;
  Timer? _timer;

  ApiService get _api => widget.api ?? ApiService();

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _requestCode() async {
    if (!_form.currentState!.validate()) return;
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final result =
          await _api.requestPasswordReset(_email.text.trim(), _password.text);
      if (!mounted) return;
      final rawChallenge = result['challenge'];
      if (rawChallenge is Map) {
        final challenge = Map<String, dynamic>.from(rawChallenge);
        setState(() {
          _challengeId = challenge['challengeId']?.toString();
          _maskedEmail = challenge['maskedEmail']?.toString();
          _resendSeconds =
              (challenge['resendAfterSeconds'] as num?)?.toInt() ?? 0;
          _notice = result['message']?.toString();
          _code.clear();
        });
        _startTimer();
      } else {
        setState(() => _notice = result['message']?.toString() ??
            'If an account uses that email address, a code was sent.');
      }
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final validation = Validators.code(_code.text);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.confirmPasswordReset(_challengeId!, _code.text);
      if (mounted) setState(() => _complete = true);
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String hint, IconData icon,
          {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: SolarColors.primary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: SolarColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SolarColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SolarColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: SolarColors.primary, width: 1.5)),
      );

  Widget _message(String text, {bool error = false}) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: error ? const Color(0xFFFFECE8) : const Color(0xFFEAF6E5),
            borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: TextStyle(
                color: error ? SolarColors.error : SolarColors.primary,
                fontSize: 12,
                height: 1.4)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SolarColors.background,
        appBar: AppBar(
            backgroundColor: SolarColors.surface,
            title: const Text('Reset password')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              SolarColors.primary,
                              Color(0xFF0A6875)
                            ]),
                            borderRadius: BorderRadius.circular(22)),
                        child: Column(children: [
                          const Icon(Icons.lock_reset_rounded,
                              color: Colors.white, size: 42),
                          const SizedBox(height: 10),
                          Text(
                              _complete
                                  ? 'Password updated'
                                  : _challengeId == null
                                      ? 'Recover your account'
                                      : 'Check your email',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                              _complete
                                  ? 'You can now sign in using your new password.'
                                  : _challengeId == null
                                      ? 'Create a new password and verify it securely by email.'
                                      : 'Enter the six-digit code sent to ${_maskedEmail ?? 'your email'}.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Color(0xFFDDEFF1),
                                  fontSize: 12,
                                  height: 1.45))
                        ]),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) _message(_error!, error: true),
                      if (_notice != null && _error == null) _message(_notice!),
                      if (_complete)
                        FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Back to login'))
                      else if (_challengeId != null)
                        _otpForm()
                      else
                        _resetForm(),
                    ]),
              ),
            ),
          ),
        ),
      );

  Widget _resetForm() => Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Email address',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          SolarField(
              controller: _email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: _decoration(
                  'you@example.com', Icons.alternate_email_rounded)),
          const SizedBox(height: 14),
          const Text('New password',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          SolarField(
              controller: _password,
              validator: Validators.password,
              obscureText: _hidePassword,
              maxLength: 64,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _decoration('Create a new password',
                  Icons.lock_outline_rounded,
                  suffix: IconButton(
                      tooltip: _hidePassword
                          ? 'Show new password'
                          : 'Hide new password',
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined)))),
          const Text('12–64 characters. Try a memorable passphrase.',
              style: TextStyle(color: SolarColors.muted, fontSize: 11)),
          const SizedBox(height: 14),
          const Text('Confirm new password',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          SolarField(
              controller: _confirm,
              validator: (value) => Validators.confirm(value, _password.text),
              obscureText: _hideConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_busy) _requestCode();
              },
              decoration: _decoration('Re-enter your new password',
                  Icons.lock_reset_rounded,
                  suffix: IconButton(
                      tooltip: _hideConfirm
                          ? 'Show confirmed password'
                          : 'Hide confirmed password',
                      onPressed: () =>
                          setState(() => _hideConfirm = !_hideConfirm),
                      icon: Icon(_hideConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined)))),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: _busy ? null : _requestCode,
              child: Text(_busy ? 'Sending code…' : 'Send verification code')),
        ]),
      );

  Widget _otpForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Verification code',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 10),
            decoration: _decoration('000000', Icons.password_rounded)
                .copyWith(counterText: ''),
            onSubmitted: (_) {
              if (!_busy) _verify();
            },
          ),
          const SizedBox(height: 18),
          FilledButton(
              onPressed: _busy ? null : _verify,
              child: Text(_busy ? 'Verifying…' : 'Reset password')),
          const SizedBox(height: 8),
          TextButton(
              onPressed:
                  _busy || _resendSeconds > 0 ? null : _requestCode,
              child: Text(_resendSeconds > 0
                  ? 'Resend code in ${_resendSeconds}s'
                  : 'Send a new code')),
          TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _challengeId = null;
                        _notice = null;
                        _error = null;
                      }),
              child: const Text('Change email or password')),
        ],
      );
}
