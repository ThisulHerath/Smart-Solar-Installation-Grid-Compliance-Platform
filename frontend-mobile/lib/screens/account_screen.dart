import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}
class _AccountScreenState extends State<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController(), _confirm = TextEditingController(), _code = TextEditingController();
  String? _action, _challenge, _email, _error;
  bool _busy = false, _acknowledged = false;
  int _resend = 0;
  Timer? _timer;
  @override
  void dispose() { _timer?.cancel(); _password.dispose(); _confirm.dispose(); _code.dispose(); super.dispose(); }
  Future<void> _request() async {
    if (_challenge == null && !_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final result = await ApiService().post('/api/auth/$_action/request-otp', {'newPassword': _password.text});
      if (!mounted) return;
      setState(() { _challenge = result['challengeId']; _email = result['maskedEmail']; _resend = result['resendAfterSeconds']; _code.clear(); });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) { if (!mounted || _resend <= 0) { t.cancel(); return; } setState(() { _resend--; }); });
    } catch (e) { if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); }); }
    finally { if (mounted) setState(() { _busy = false; }); }
  }
  Future<void> _verify() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() { _busy = true; _error = null; });
    try {
      final result = await ApiService().post('/api/auth/$_action/confirm', {'challengeId': _challenge, 'code': _code.text});
      await auth.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } catch (e) { if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); }); }
    finally { if (mounted) setState(() { _busy = false; }); }
  }
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(appBar: AppBar(title: const Text('Account & security')), body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(user?.fullName ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(user?.email ?? ''), const SizedBox(height: 28),
      if (_action == null) ...[
        FilledButton(onPressed: () => setState(() { _action = 'password'; }), child: const Text('Change password')),
        OutlinedButton(onPressed: () => setState(() { _action = 'account-deletion'; }), child: const Text('Delete account')),
      ] else ...[
        Text(_action == 'password' ? 'Change password' : 'Delete account', style: const TextStyle(fontSize: 20)), const SizedBox(height: 16),
        if (_challenge != null) ...[
          Text('Enter the code sent to $_email. It expires in 10 minutes.'),
          TextFormField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, autofillHints: const [AutofillHints.oneTimeCode], decoration: const InputDecoration(labelText: 'Email verification code'), validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'Enter six digits'),
          TextButton(onPressed: _busy || _resend > 0 ? null : _request, child: Text(_resend > 0 ? 'Resend in ${_resend}s' : 'Send a new code')),
        ] else if (_action == 'password') ...[
          const Text('After verification, you will be signed out on every device.'),
          TextFormField(controller: _password, obscureText: true, maxLength: 64, autofillHints: const [AutofillHints.newPassword], decoration: const InputDecoration(labelText: 'New password'), validator: (v) => (v?.length ?? 0) < 12 ? 'Use 12–64 characters' : null),
          TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password'), validator: (v) => v != _password.text ? 'Passwords do not match' : null),
        ] else ...[
          const Text('Your sign-in access and profile contact details will be removed permanently. Installation, survey, safety and approval records remain in the audit history. Deletion does not cancel an installation or erase information already in those records.'),
          CheckboxListTile(value: _acknowledged, onChanged: _busy ? null : (v) => setState(() { _acknowledged = v ?? false; }), title: const Text('I understand this cannot be undone.')),
        ],
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        FilledButton(onPressed: _busy || (_action == 'account-deletion' && !_acknowledged) ? null : _challenge == null ? _request : _verify, child: Text(_busy ? 'Please wait…' : _challenge == null ? 'Send verification code' : _action == 'password' ? 'Verify & change password' : 'Verify & delete my account')),
        TextButton(onPressed: _busy ? null : () => setState(() { _action = null; _challenge = null; _error = null; _acknowledged = false; _password.clear(); _confirm.clear(); _code.clear(); }), child: const Text('Cancel')),
      ],
    ]))));
  }
}
