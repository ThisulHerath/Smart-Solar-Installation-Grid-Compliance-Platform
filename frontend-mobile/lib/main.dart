import 'theme/solar_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartSolarApp());
}

class SmartSolarApp extends StatelessWidget {
  const SmartSolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Solar Platform',
        debugShowCheckedModeBanner: false,
        theme: buildSolarTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
