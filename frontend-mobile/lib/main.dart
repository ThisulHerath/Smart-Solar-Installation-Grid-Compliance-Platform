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
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final isWide = media.size.width > 600;
          final appWidth = isWide ? 520.0 : media.size.width;
          final textScale = media.textScaler.scale(1).clamp(.9, 1.25);

          return ColoredBox(
            color: const Color(0xFFE7EEE8),
            child: Center(
              child: Container(
                width: appWidth,
                height: media.size.height,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: SolarColors.background,
                  boxShadow: isWide
                      ? const [
                          BoxShadow(
                            color: Color(0x24173E44),
                            blurRadius: 32,
                            spreadRadius: 3,
                          ),
                        ]
                      : null,
                ),
                child: MediaQuery(
                  data: media.copyWith(
                    size: Size(appWidth, media.size.height),
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
