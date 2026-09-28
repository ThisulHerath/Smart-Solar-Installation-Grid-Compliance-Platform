import 'package:flutter/material.dart';
import '../theme/solar_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

const _orange = SolarColors.lime;
const _ink = SolarColors.text;
const _muted = SolarColors.muted;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    return Scaffold(
      backgroundColor: SolarColors.background,
      body: Stack(children: [
        const Positioned.fill(bottom: null, child: _HomeHeader()),
        SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxHeight < 680;
          final horizontal = constraints.maxWidth < 340 ? 18.0 : 26.0;
          final top = compact ? 118.0 : 145.0;
          final contentHeight =
              (constraints.maxHeight - top - 20).clamp(0.0, double.infinity);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 20),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: contentHeight),
                child: IntrinsicHeight(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Center(
                          child: Container(
                        width: compact ? 74 : 88,
                        height: compact ? 74 : 88,
                        decoration: BoxDecoration(
                            color: SolarColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: SolarColors.border),
                            boxShadow: [
                              BoxShadow(
                                  color: _orange.withValues(alpha: .18),
                                  blurRadius: 25,
                                  offset: const Offset(0, 8))
                            ]),
                        child: Icon(Icons.solar_power_rounded,
                            color: _orange, size: compact ? 38 : 46),
                      )),
                      SizedBox(height: compact ? 15 : 22),
                      const Text('Your rooftop.\nA brighter tomorrow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _ink,
                              fontSize: 36,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.4)),
                      const SizedBox(height: 14),
                      const Text(
                          'Plan your solar journey, complete your assessment, and follow every project step in one simple workspace.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _muted, fontSize: 13, height: 1.55)),
                      SizedBox(height: compact ? 20 : 28),
                      SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => open(const RegisterScreen()),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 48),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Register',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 17)
                                ]),
                          )),
                      const SizedBox(height: 10),
                      SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () => open(const LoginScreen()),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: _orange,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 46),
                                side: const BorderSide(
                                    color: _orange, width: 1.4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: const Text('Login',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                          )),
                      SizedBox(height: compact ? 20 : 30),
                      const Row(children: [
                        Expanded(
                            child: _HomeFeature(
                                icon: Icons.roofing_rounded,
                                title: 'Assess',
                                subtitle: 'Plan your rooftop')),
                        SizedBox(width: 10),
                        Expanded(
                            child: _HomeFeature(
                                icon: Icons.verified_user_outlined,
                                title: 'Review',
                                subtitle: 'Engineering checks')),
                        SizedBox(width: 10),
                        Expanded(
                            child: _HomeFeature(
                                icon: Icons.insights_rounded,
                                title: 'Track',
                                subtitle: 'Follow progress')),
                      ]),
                      const Spacer(),
                      const SizedBox(height: 22),
                      const Text('SMART SOLAR  ·  SRI LANKA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: SolarColors.muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3)),
                    ])),
              ),
            )),
          );
        })),
      ]),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final height = (size.maxWidth * .42).clamp(135.0, 178.0);
        return ClipPath(
          clipper: _HomeHeaderClipper(),
          child: Container(
            height: height,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SolarColors.primary, _orange])),
            child: const Align(
                alignment: Alignment.topLeft,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 25),
                  SizedBox(width: 6),
                  Text('smartsolar.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.8))
                ])),
          ),
        );
      });
}

class _HomeHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height * .65)
    ..quadraticBezierTo(size.width * .22, size.height * .47, size.width * .44,
        size.height * .67)
    ..quadraticBezierTo(
        size.width * .70, size.height * .92, size.width, size.height * .63)
    ..lineTo(size.width, 0)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HomeFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _HomeFeature(
      {required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
            color: SolarColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SolarColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x10173E44),
                  blurRadius: 16,
                  offset: Offset(0, 6))
            ]),
        child: Column(children: [
          Icon(icon, color: _orange, size: 22),
          const SizedBox(height: 7),
          Text(title,
              style: const TextStyle(
                  color: _ink, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style:
                  const TextStyle(color: _muted, fontSize: 8.5, height: 1.25)),
        ]),
      );
}
