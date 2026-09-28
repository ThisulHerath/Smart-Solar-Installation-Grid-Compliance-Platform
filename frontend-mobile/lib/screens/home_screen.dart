import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/solar_theme.dart';
import '../utils/constants.dart';
import '../widgets/solar_brand.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'survey_screen.dart';
import 'technician_jobs_screen.dart';
import 'welcome_screen.dart';

const _bg = SolarColors.background;
const _panel = SolarColors.surface;
const _gold = SolarColors.lime;
const _cyan = Color(0xFF087D75);
const _text = SolarColors.text;
const _muted = SolarColors.muted;
const _line = SolarColors.border;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const LoginScreen();
    final homeowner = user.roles.contains(AppConstants.roleHomeowner);
    final fieldStaff = user.roles.any([
      AppConstants.roleFieldTechnician,
      AppConstants.roleSeniorEngineer,
      AppConstants.roleAdministrator,
    ].contains);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.light(
            primary: SolarColors.primary, secondary: _gold, surface: _panel),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              sliver: SliverList.list(children: [
                _Header(
                  name: user.fullName,
                  onProfile: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
                const SizedBox(height: 24),
                const _SystemStrip(),
                const SizedBox(height: 16),
                const _PowerHero(),
                const SizedBox(height: 14),
                const Row(children: [
                  Expanded(child: _BatteryCard()),
                  SizedBox(width: 12),
                  Expanded(child: _SavingsCard()),
                ]),
                const SizedBox(height: 14),
                const _EnergyFlowCard(),
                const SizedBox(height: 14),
                const _GenerationCard(),
                const SizedBox(height: 22),
                const Text('Quick actions',
                    style: TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (homeowner)
                  _ActionTile(
                    icon: Icons.roofing_rounded,
                    title: 'My solar surveys',
                    subtitle: 'Assess your roof and track proposals',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SurveyScreen())),
                  ),
                if (fieldStaff)
                  _ActionTile(
                    icon: Icons.engineering_rounded,
                    title: 'Site jobs & inspections',
                    subtitle: 'View assigned field work',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const TechnicianJobsScreen())),
                  ),
                _ActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile & security',
                  subtitle: 'Manage your account information',
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _signOut(context, auth),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                  style: TextButton.styleFrom(foregroundColor: _muted),
                ),
              ]),
            ),
          ]),
        ),
        bottomNavigationBar: const _BottomNav(),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Sign out', style: TextStyle(color: _text)),
        content: const Text('Are you sure you want to sign out of Smart Solar?',
            style: TextStyle(color: _muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (_) => false);
      }
    }
  }
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onProfile;
  const _Header({required this.name, required this.onProfile});
  @override
  Widget build(BuildContext context) => Row(children: [
        const SolarBrand(size: 18),
        const Spacer(),
        IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            color: _muted),
        InkWell(
          onTap: onProfile,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 7, 7, 7),
            decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line)),
            child: Row(children: [
              Text(name.split(' ').first,
                  style: const TextStyle(
                      color: _text, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const CircleAvatar(
                  radius: 14,
                  backgroundColor: _gold,
                  child: Icon(Icons.person_rounded, color: _bg, size: 17)),
            ]),
          ),
        ),
      ]);
}

class _SystemStrip extends StatelessWidget {
  const _SystemStrip();
  @override
  Widget build(BuildContext context) => const Row(children: [
        Expanded(
            child: _MiniStatus(
                icon: Icons.check_circle_rounded,
                color: _cyan,
                label: 'SYSTEM',
                value: 'All healthy')),
        SizedBox(width: 10),
        Expanded(
            child: _MiniStatus(
                icon: Icons.wb_sunny_rounded,
                color: _gold,
                label: 'IRRADIANCE',
                value: '0.82 kW/m²')),
      ]);
}

class _MiniStatus extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _MiniStatus(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
  @override
  Widget build(BuildContext context) => _Glass(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        color: _muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 3),
                Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ])),
        ]),
      );
}

class _PowerHero extends StatelessWidget {
  const _PowerHero();
  @override
  Widget build(BuildContext context) => Container(
        height: 246,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF2F8EF), _panel, Color(0xFFE7F3E1)]),
          border: Border.all(color: const Color(0x6672B83E)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A173E44), blurRadius: 26, offset: Offset(0, 10))
          ],
        ),
        child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('CURRENT POWER OUTPUT',
                    style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700)),
                Spacer(),
                _LivePill(),
              ]),
              SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('4.82',
                    style: TextStyle(
                        color: _text,
                        fontSize: 46,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2)),
                Padding(
                    padding: EdgeInsets.only(left: 7, bottom: 5),
                    child: Text('kW',
                        style: TextStyle(
                            color: _gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w700))),
                Spacer(),
                Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('↑ 12.4%',
                        style: TextStyle(
                            color: _cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w700))),
              ]),
              SizedBox(height: 10),
              Expanded(
                  child: CustomPaint(
                      painter: _LineChartPainter(), size: Size.infinite)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('6 AM', style: TextStyle(color: _muted, fontSize: 9)),
                Text('12 PM', style: TextStyle(color: _muted, fontSize: 9)),
                Text('6 PM', style: TextStyle(color: _muted, fontSize: 9)),
              ]),
            ]),
      );
}

class _LivePill extends StatelessWidget {
  const _LivePill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(0x16087D75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x44087D75))),
        child: const Row(children: [
          CircleAvatar(radius: 3, backgroundColor: _cyan),
          SizedBox(width: 6),
          Text('LIVE',
              style: TextStyle(
                  color: _cyan, fontSize: 9, fontWeight: FontWeight.w800))
        ]),
      );
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard();
  @override
  Widget build(BuildContext context) => const _Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.battery_charging_full_rounded, color: _cyan, size: 18),
            SizedBox(width: 7),
            Text('BATTERY',
                style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700))
          ]),
          SizedBox(height: 14),
          Center(
              child: SizedBox(
                  width: 92,
                  height: 92,
                  child: CustomPaint(
                      painter: _RingPainter(.76),
                      child: Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('76%',
                            style: TextStyle(
                                color: _text,
                                fontSize: 23,
                                fontWeight: FontWeight.w800)),
                        Text('CHARGING',
                            style: TextStyle(
                                color: _cyan, fontSize: 7, letterSpacing: .8))
                      ]))))),
          SizedBox(height: 11),
          Center(
              child: Text('3h 20m until full',
                  style: TextStyle(color: _muted, fontSize: 10))),
        ]),
      );
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard();
  @override
  Widget build(BuildContext context) => _Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.savings_outlined, color: _gold, size: 18),
            SizedBox(width: 7),
            Text('THIS MONTH',
                style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700))
          ]),
          const SizedBox(height: 19),
          const Text('LKR 18,420',
              style: TextStyle(
                  color: _text,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6)),
          const SizedBox(height: 5),
          const Text('estimated savings',
              style: TextStyle(color: _muted, fontSize: 10)),
          const SizedBox(height: 18),
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                  value: .68,
                  minHeight: 7,
                  backgroundColor: _line,
                  valueColor: AlwaysStoppedAnimation(_gold))),
          const SizedBox(height: 11),
          const Text('68% self-powered',
              style: TextStyle(
                  color: _gold, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _EnergyFlowCard extends StatelessWidget {
  const _EnergyFlowCard();
  @override
  Widget build(BuildContext context) => const _Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Energy flow',
                style: TextStyle(
                    color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
            Spacer(),
            Text('Real time', style: TextStyle(color: _cyan, fontSize: 10))
          ]),
          SizedBox(height: 22),
          Row(children: [
            Expanded(
                child: _FlowNode(
                    icon: Icons.solar_power_rounded,
                    label: 'SOLAR',
                    value: '4.82 kW',
                    color: _gold)),
            _FlowArrow(),
            Expanded(
                child: _FlowNode(
                    icon: Icons.battery_charging_full_rounded,
                    label: 'BATTERY',
                    value: '+1.20 kW',
                    color: _cyan)),
            _FlowArrow(),
            Expanded(
                child: _FlowNode(
                    icon: Icons.home_rounded,
                    label: 'HOME',
                    value: '3.62 kW',
                    color: SolarColors.primary)),
          ]),
        ]),
      );
}

class _FlowNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _FlowNode(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color.withValues(alpha: .4))),
            child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 9),
        Text(label,
            style:
                const TextStyle(color: _muted, fontSize: 8, letterSpacing: 1)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: _text, fontSize: 10, fontWeight: FontWeight.w700)),
      ]);
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.only(bottom: 32),
      child: Icon(Icons.arrow_forward_rounded, color: _cyan, size: 17));
}

class _GenerationCard extends StatelessWidget {
  const _GenerationCard();
  @override
  Widget build(BuildContext context) => _Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Text('Generation vs grid',
                style: TextStyle(
                    color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
            Spacer(),
            Text('LAST 7 DAYS',
                style: TextStyle(color: _muted, fontSize: 8, letterSpacing: 1))
          ]),
          const SizedBox(height: 18),
          SizedBox(
              height: 100,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    const solar = [66.0, 78.0, 58.0, 88.0, 73.0, 94.0, 82.0];
                    const grid = [28.0, 22.0, 35.0, 18.0, 27.0, 13.0, 20.0];
                    return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                    width: 8,
                                    height: solar[i],
                                    decoration: BoxDecoration(
                                        color: _gold,
                                        borderRadius:
                                            BorderRadius.circular(6))),
                                const SizedBox(width: 3),
                                Container(
                                    width: 8,
                                    height: grid[i],
                                    decoration: BoxDecoration(
                                        color: _cyan,
                                        borderRadius:
                                            BorderRadius.circular(6))),
                              ]),
                          const SizedBox(height: 6),
                          Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                              style:
                                  const TextStyle(color: _muted, fontSize: 8)),
                        ]);
                  }))),
          const SizedBox(height: 13),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(radius: 3, backgroundColor: _gold),
            SizedBox(width: 5),
            Text('Solar', style: TextStyle(color: _muted, fontSize: 9)),
            SizedBox(width: 16),
            CircleAvatar(radius: 3, backgroundColor: _cyan),
            SizedBox(width: 5),
            Text('Grid', style: TextStyle(color: _muted, fontSize: 9))
          ]),
        ]),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
            color: _panel,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(children: [
                    Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: const Color(0x1872B83E),
                            borderRadius: BorderRadius.circular(13)),
                        child: Icon(icon, color: _gold, size: 21)),
                    const SizedBox(width: 13),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: const TextStyle(
                                  color: _text, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(subtitle,
                              style:
                                  const TextStyle(color: _muted, fontSize: 11))
                        ])),
                    const Icon(Icons.chevron_right_rounded, color: _muted),
                  ])),
            )),
      );
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Glass({required this.child, this.padding = const EdgeInsets.all(17)});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x12173E44),
                  blurRadius: 18,
                  offset: Offset(0, 7))
            ]),
        child: child,
      );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            color: SolarColors.surface,
            border: Border(top: BorderSide(color: _line))),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: const SafeArea(
            top: false,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      selected: true),
                  _NavItem(icon: Icons.analytics_outlined, label: 'Analytics'),
                  _NavItem(icon: Icons.solar_power_outlined, label: 'Devices'),
                  _NavItem(icon: Icons.assignment_outlined, label: 'Reports'),
                ])),
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _NavItem(
      {required this.icon, required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? _gold : _muted, size: 21),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: selected ? _gold : _muted,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500))
      ]));
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _line
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final values = [.08, .16, .28, .45, .66, .58, .79, .72, .91, .78, .64, .42];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(
          size.width * i / (values.length - 1), size.height * (1 - values[i]));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x5572B83E), Color(0x0072B83E)])
              .createShader(Offset.zero & size));
    canvas.drawPath(
        path,
        Paint()
          ..color = _gold
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingPainter extends CustomPainter {
  final double value;
  const _RingPainter(this.value);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawArc(
        rect.deflate(7),
        -.5 * math.pi,
        2 * math.pi,
        false,
        Paint()
          ..color = _line
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke);
    canvas.drawArc(
        rect.deflate(7),
        -.5 * math.pi,
        2 * math.pi * value,
        false,
        Paint()
          ..color = _cyan
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value;
}
