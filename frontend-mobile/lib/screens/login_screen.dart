import '../theme/solar_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    if (email.isEmpty || pass.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(email, pass);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(title: const Text('Log in')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [SolarColors.lime, Color(0xFFE3ECCF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.wb_sunny_rounded, color: SolarColors.text, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome back.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SolarColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your solar journey, all in one place. Sign in to continue.',
                  style: TextStyle(fontSize: 14, color: SolarColors.muted),
                ),
                const SizedBox(height: 28),

                if (auth.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x26EF4444),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x4DEF4444)),
                    ),
                    child: Text(
                      auth.errorMessage!,
                      style: const TextStyle(color: SolarColors.error, fontSize: 13),
                    ),
                  ),

                // Email
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: SolarColors.text),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: const TextStyle(color: SolarColors.muted),
                    prefixIcon: const Icon(Icons.email_outlined, color: SolarColors.muted),
                    filled: true,
                    fillColor: SolarColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: SolarColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: SolarColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: SolarColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: SolarColors.text),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: SolarColors.muted),
                    prefixIcon: const Icon(Icons.lock_outline, color: SolarColors.muted),
                    filled: true,
                    fillColor: SolarColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: SolarColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: SolarColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: SolarColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: auth.status == AuthStatus.authenticating ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SolarColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: auth.status == AuthStatus.authenticating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: SolarColors.onPrimary, strokeWidth: 2),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SolarColors.onPrimary),
                        ),
                ),
                const SizedBox(height: 32),

                TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('New homeowner? Create an account')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
