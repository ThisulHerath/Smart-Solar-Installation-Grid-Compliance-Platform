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
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0D14),
          primaryColor: const Color(0xFF10B981),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF10B981),
            secondary: Color(0xFFF59E0B),
            surface: Color(0xFF111726),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
