import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/core/auth/providers/auth_provider.dart';
import 'package:smart_solar_mobile/core/navigation/screens/home_screen.dart';
import 'package:smart_solar_mobile/core/navigation/screens/welcome_screen.dart';
import 'package:smart_solar_mobile/core/navigation/screens/staff_onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.initializeAuth();
    if (mounted) {
      if (auth.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => auth.requiresStaffOnboarding
                  ? const StaffOnboardingScreen()
                  : const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SolarColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: SolarColors.primary,
        ),
      ),
    );
  }
}
