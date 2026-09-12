import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final ApiService? api;
  const RegisterScreen({super.key, this.api});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _phone = TextEditingController(), _password = TextEditingController();
  bool _busy = false;
  String? _error;
  final _code = TextEditingController();
  String? _challengeId, _maskedEmail;
  int _resendSeconds = 0;
  Timer? _timer;
  @override
  void dispose() { _timer?.cancel(); _code.dispose(); _name.dispose(); _email.dispose(); _phone.dispose(); _password.dispose(); super.dispose(); }
  Future<void> _requestCode() async {
    if (_challengeId == null && !_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final result = await (widget.api ?? ApiService()).post('/api/auth/register/request-otp', {'fullName': _name.text.trim(), 'email': _email.text.trim(), 'phoneNumber': _phone.text.trim(), 'password': _password.text}, requiresAuth: false);
      if (!mounted) return;
      setState(() { _challengeId = result['challengeId']; _maskedEmail = result['maskedEmail']; _resendSeconds = result['resendAfterSeconds']; _code.clear(); });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) { if (!mounted || _resendSeconds <= 0) { timer.cancel(); return; } setState(() { _resendSeconds--; }); });
    } catch (e) { if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); }); }
    finally { if (mounted) setState(() { _busy = false; }); }
  }
  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    final auth = context.read<AuthProvider>();
    try {
      await (widget.api ?? ApiService()).post('/api/auth/register', {'challengeId': _challengeId, 'code': _code.text.trim()}, requiresAuth: false);
      final success = await auth.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (success) { Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false); }
      else { setState(() { _error = 'Account created. Please return to sign in.'; }); }
    } catch (e) { if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); }); }
    finally { if (mounted) setState(() { _busy = false; }); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Create homeowner account')), body: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Start your rooftop solar assessment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      if (_challengeId == null) ...[
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null),
      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()) ? 'Enter a valid email' : null),
      TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)', hintText: '+94 77 123 4567')),
      TextFormField(controller: _password, obscureText: true, maxLength: 64, decoration: const InputDecoration(labelText: 'Password'), validator: (v) => v == null || v.length < 12 ? 'Use at least 12 characters' : null),
      ] else ...[
        Text('Enter the six-digit code sent to $_maskedEmail. It expires in 10 minutes. Check your spam folder too.'),
        TextFormField(controller: _code, keyboardType: TextInputType.number, autofillHints: const [AutofillHints.oneTimeCode], maxLength: 6, decoration: const InputDecoration(labelText: 'Email verification code'), validator: (v) => v == null || !RegExp(r'^\d{6}$').hasMatch(v) ? 'Enter the six-digit code' : null),
        TextButton(onPressed: _busy || _resendSeconds > 0 ? null : _requestCode, child: Text(_resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Send a new code')),
        TextButton(onPressed: _busy ? null : () => setState(() { _challengeId = null; _error = null; }), child: const Text('Edit details')),
      ],
      const SizedBox(height: 24), if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      ElevatedButton(onPressed: _busy ? null : _challengeId == null ? _requestCode : _register, child: Text(_busy ? 'Please wait…' : _challengeId == null ? 'Send verification code' : 'Verify & create account')),
    ])),
  ));
}
