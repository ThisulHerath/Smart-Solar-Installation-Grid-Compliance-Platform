import 'package:flutter/material.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:smart_solar_mobile/core/navigation/screens/login_screen.dart';
import 'package:smart_solar_mobile/core/navigation/screens/register_screen.dart';

const _orange = SolarColors.lime;
const _ink = SolarColors.text;
const _muted = SolarColors.muted;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _processExpanded = false;
  final _processKey = GlobalKey<_HowItWorksState>();

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
          final top = compact ? 75.0 : 90.0;
          final contentHeight =
              (constraints.maxHeight - top - 20).clamp(0.0, double.infinity);
          return _WelcomeViewport(
            expanded: _processExpanded,
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
                        child: const _RooftopSolarIcon(),
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
                                icon: Icons.fact_check_outlined,
                                title: 'Review',
                                subtitle: 'Engineering checks')),
                        SizedBox(width: 10),
                        Expanded(
                            child: _HomeFeature(
                                icon: Icons.trending_up_rounded,
                                title: 'Track',
                                subtitle: 'Follow progress')),
                      ]),
                      const SizedBox(height: 14),
                      _HowItWorks(
                        key: _processKey,
                        onExpansionChanged: (expanded) =>
                            setState(() => _processExpanded = expanded),
                      ),
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

class _WelcomeViewport extends StatelessWidget {
  final bool expanded;
  final EdgeInsets padding;
  final Widget child;

  const _WelcomeViewport(
      {required this.expanded, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return SingleChildScrollView(padding: padding, child: child);
    }
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(width: constraints.maxWidth, child: child),
          ),
        ),
      ),
    );
  }
}

class _RooftopSolarIcon extends StatelessWidget {
  const _RooftopSolarIcon();

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: 54,
          height: 54,
          child: Stack(children: [
            const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.wb_sunny_outlined, color: _orange, size: 21)),
            const Positioned(
                left: 0,
                bottom: 0,
                child: Icon(Icons.home_outlined,
                    color: SolarColors.primary, size: 44)),
            Positioned(
                left: 14,
                bottom: 10,
                child: Container(
                    color: SolarColors.surface,
                    child: const Icon(Icons.grid_view_rounded,
                        color: _orange, size: 18))),
          ]),
        ),
      );
}

class _HowItWorks extends StatefulWidget {
  final ValueChanged<bool> onExpansionChanged;
  const _HowItWorks({super.key, required this.onExpansionChanged});

  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() => _expanded = expanded);
            widget.onExpansionChanged(expanded);
          },
          showTrailingIcon: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: _orange,
          collapsedIconColor: _orange,
          title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('How it works',
                style: TextStyle(
                    color: _orange, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            AnimatedRotation(
                turns: _expanded ? .5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more_rounded,
                    color: _orange, size: 20)),
          ]),
          children: const [
            _ProcessStep(
                number: '01',
                title: 'Assess your rooftop',
                description:
                    'Create an account and submit your property and electricity usage details.'),
            _ProcessStep(
                number: '02',
                title: 'Review your solar plan',
                description:
                    'Follow the site inspection, proposed system, and engineering review.'),
            _ProcessStep(
                number: '03',
                title: 'Track your project',
                description:
                    'Check approvals and project progress, and contact your team from your workspace.'),
          ],
        ),
      );
}

class _ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  const _ProcessStep(
      {required this.number, required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _orange.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(number,
                  style: const TextStyle(
                      color: SolarColors.primary,
                      fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        color: _muted, fontSize: 12, height: 1.5)),
              ])),
        ]),
      );
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
        constraints: const BoxConstraints(minHeight: 126),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
            color: SolarColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _orange.withValues(alpha: .3))),
        child: Column(children: [
          Icon(icon, color: _orange, size: 30),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  color: _ink, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style:
                  const TextStyle(color: _muted, fontSize: 10.5, height: 1.4)),
        ]),
      );
}
