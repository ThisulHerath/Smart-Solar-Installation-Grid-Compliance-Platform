import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _phone = TextEditingController(), _password = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _name.dispose(); _email.dispose(); _phone.dispose(); _password.dispose(); super.dispose(); }
  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    final auth = context.read<AuthProvider>();
    try {
      await ApiService().post('/api/auth/register', {'fullName': _name.text.trim(), 'email': _email.text.trim(), 'phoneNumber': _phone.text.trim(), 'password': _password.text}, requiresAuth: false);
      final success = await auth.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (success) { Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false); }
      else { setState(() { _error = 'Account created. Please return to sign in.'; }); }
    } catch (_) { if (mounted) setState(() { _error = 'Could not create your account. Check your details or try another email.'; }); }
    finally { if (mounted) setState(() { _busy = false; }); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Create homeowner account')), body: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Start your rooftop solar assessment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null),
      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()) ? 'Enter a valid email' : null),
      TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)', hintText: '+94 77 123 4567')),
      TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password'), validator: (v) => v == null || v.length < 8 ? 'Use at least 8 characters' : null),
      const SizedBox(height: 24), if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      ElevatedButton(onPressed: _busy ? null : _register, child: Text(_busy ? 'Creating account…' : 'Create account')),
    ])),
  ));
}
