import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/core/auth/providers/auth_provider.dart';
import 'package:smart_solar_mobile/core/api/api_service.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:smart_solar_mobile/core/utils/validators.dart';
import 'package:smart_solar_mobile/core/widgets/solar_field.dart';
import 'package:smart_solar_mobile/core/navigation/screens/login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();
  String? _action, _challenge, _email, _error;
  bool _busy = false;
  bool _acknowledged = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  int _resend = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _password.dispose();
    _confirm.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (_challenge == null && !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ApiService().post(
          '/api/auth/$_action/request-otp', {'newPassword': _password.text});
      if (!mounted) return;
      setState(() {
        _challenge = result['challengeId'];
        _email = result['maskedEmail'];
        _resend = result['resendAfterSeconds'];
        _code.clear();
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _resend <= 0) {
          timer.cancel();
          return;
        }
        setState(() => _resend--);
      });
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ApiService().post('/api/auth/$_action/confirm',
          {'challengeId': _challenge, 'code': _code.text});
      await auth.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'])));
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resetAction() {
    _timer?.cancel();
    setState(() {
      _action = null;
      _challenge = null;
      _email = null;
      _error = null;
      _acknowledged = false;
      _resend = 0;
      _password.clear();
      _confirm.clear();
      _code.clear();
    });
  }

  InputDecoration _inputDecoration(
          String hint, IconData icon, Widget? suffix) =>
      InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, color: SolarColors.primary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: SolarColors.background,
      );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
        title: const Text('Account & security',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        backgroundColor: SolarColors.background,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(21),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [SolarColors.primary, SolarColors.heroEnd],
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                            color: SolarColors.lime,
                            borderRadius: BorderRadius.circular(17)),
                        child: const Icon(Icons.shield_outlined,
                            color: SolarColors.primary, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.fullName ?? 'Your account',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(user?.email ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: SolarColors.heroText,
                                      fontSize: 10)),
                            ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  if (_action == null) ...[
                    const Text('Security settings',
                        style: TextStyle(
                            color: SolarColors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Protect your login and manage account access.',
                        style:
                            TextStyle(color: SolarColors.muted, fontSize: 10)),
                    const SizedBox(height: 13),
                    _SecurityActionCard(
                      icon: Icons.password_rounded,
                      color: SolarColors.primary,
                      title: 'Change password',
                      subtitle:
                          'Verify your email before setting a new password.',
                      onTap: () => setState(() => _action = 'password'),
                    ),
                    const SizedBox(height: 11),
                    _SecurityActionCard(
                      icon: Icons.delete_outline_rounded,
                      color: SolarColors.error,
                      title: 'Delete account',
                      subtitle:
                          'Permanently remove your sign-in and profile details.',
                      onTap: () => setState(() => _action = 'account-deletion'),
                    ),
                    const SizedBox(height: 18),
                    const _SecurityNotice(),
                  ] else
                    _buildActionPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPanel() {
    final changingPassword = _action == 'password';
    final destructive = _action == 'account-deletion';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SolarColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: SolarColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x10173E44), blurRadius: 18, offset: Offset(0, 7)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: (destructive ? SolarColors.error : SolarColors.primary)
                    .withValues(alpha: .1),
                borderRadius: BorderRadius.circular(13)),
            child: Icon(
                changingPassword
                    ? Icons.password_rounded
                    : Icons.delete_outline_rounded,
                color: destructive ? SolarColors.error : SolarColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(changingPassword ? 'Change password' : 'Delete account',
                style: const TextStyle(
                    color: SolarColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 17),
        if (_challenge != null) ...[
          Text('Enter the six-digit code sent to $_email.',
              style: const TextStyle(
                  color: SolarColors.muted, fontSize: 11, height: 1.4)),
          const SizedBox(height: 13),
          SolarField(
            controller: _code,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration:
                _inputDecoration('Verification code', Icons.pin_outlined, null),
            validator: Validators.code,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy || _resend > 0 ? null : _request,
              child: Text(_resend > 0
                  ? 'Resend available in ${_resend}s'
                  : 'Send a new code'),
            ),
          ),
        ] else if (changingPassword) ...[
          const Text(
              'Choose a strong password. After verification you will be signed out on every device.',
              style: TextStyle(
                  color: SolarColors.muted, fontSize: 11, height: 1.45)),
          const SizedBox(height: 14),
          SolarField(
            controller: _password,
            obscureText: _hidePassword,
            maxLength: 64,
            autofillHints: const [AutofillHints.newPassword],
            decoration: _inputDecoration(
              'New password',
              Icons.lock_outline_rounded,
              IconButton(
                tooltip: _hidePassword ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(_hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            validator: Validators.password,
          ),
          SolarField(
            controller: _confirm,
            obscureText: _hideConfirm,
            decoration: _inputDecoration(
              'Confirm new password',
              Icons.lock_reset_rounded,
              IconButton(
                tooltip: _hideConfirm ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                icon: Icon(_hideConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            validator: (value) => Validators.confirm(value, _password.text),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF4E8),
                borderRadius: BorderRadius.circular(12)),
            child: const Text(
                'Your sign-in and profile details will be removed permanently. Existing installation, survey, safety and approval records remain in the audit history.',
                style: TextStyle(
                    color: SolarColors.warning, fontSize: 11, height: 1.45)),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _acknowledged,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: _busy
                ? null
                : (value) => setState(() => _acknowledged = value ?? false),
            title: const Text('I understand this cannot be undone.',
                style: TextStyle(color: SolarColors.text, fontSize: 11)),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: SolarColors.errorSoft,
                borderRadius: BorderRadius.circular(10)),
            child: Text(_error!,
                style: const TextStyle(
                    color: SolarColors.error, fontSize: 11, height: 1.4)),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _busy || (destructive && !_acknowledged)
                ? null
                : _challenge == null
                    ? _request
                    : _verify,
            style: FilledButton.styleFrom(
              backgroundColor:
                  destructive ? SolarColors.error : SolarColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _busy
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_challenge == null
                    ? 'Send verification code'
                    : changingPassword
                        ? 'Verify & change password'
                        : 'Verify & delete account'),
          ),
        ),
        TextButton(
            onPressed: _busy ? null : _resetAction,
            child: const Text('Cancel')),
      ]),
    );
  }
}

class _SecurityActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SecurityActionCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: SolarColors.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: SolarColors.border)),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: SolarColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                              color: SolarColors.muted,
                              fontSize: 10,
                              height: 1.35)),
                    ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: SolarColors.muted),
            ]),
          ),
        ),
      );
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0x1007536A),
            borderRadius: BorderRadius.circular(13)),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.verified_user_outlined,
              color: SolarColors.primary, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
                'Sensitive account changes require a verification code sent to your registered email.',
                style: TextStyle(
                    color: SolarColors.muted, fontSize: 10, height: 1.45)),
          ),
        ]),
      );
}
