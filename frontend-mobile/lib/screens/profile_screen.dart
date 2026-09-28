import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/solar_theme.dart';
import '../widgets/record_reference.dart';
import 'account_screen.dart';
import 'chat_inbox_screen.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';

const _profileInk = SolarColors.text;
const _profileMuted = SolarColors.muted;
const _profileLine = SolarColors.border;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const LoginScreen();

    final initials = user.fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final joined = '${_monthName(user.createdAt.month)} ${user.createdAt.year}';

    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        backgroundColor: SolarColors.background,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SolarColors.primary, Color(0xFF214F50)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x28173E44),
                        blurRadius: 25,
                        offset: Offset(0, 10)),
                  ],
                ),
                child: Column(children: [
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: .34))),
                    child: CircleAvatar(
                      backgroundColor: SolarColors.lime,
                      child: Text(initials.isEmpty ? 'U' : initials,
                          style: const TextStyle(
                              color: SolarColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(user.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(user.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFD8E7E4), fontSize: 11)),
                  const SizedBox(height: 13),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 7,
                    runSpacing: 7,
                    children: user.roles
                        .map((role) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: .2))),
                              child: Text(_friendlyRole(role),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ))
                        .toList(),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.calendar_month_outlined,
                    label: 'MEMBER SINCE',
                    value: joined,
                    color: SolarColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: _ProfileStat(
                    icon: Icons.verified_user_outlined,
                    label: 'ACCOUNT',
                    value: 'Protected',
                    color: SolarColors.limeDark,
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              const Text('Personal information',
                  style: TextStyle(
                      color: _profileInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Your account and contact details',
                  style: TextStyle(color: _profileMuted, fontSize: 10)),
              const SizedBox(height: 12),
              _ProfileCard(
                child: Column(children: [
                  _ProfileDetail(
                      icon: Icons.person_outline_rounded,
                      label: 'Full name',
                      value: user.fullName),
                  const _ProfileDivider(),
                  _ProfileDetail(
                      icon: Icons.alternate_email_rounded,
                      label: 'Email address',
                      value: user.email),
                  const _ProfileDivider(),
                  _ProfileDetail(
                      icon: Icons.phone_outlined,
                      label: 'Phone number',
                      value: user.phoneNumber?.isNotEmpty == true
                          ? user.phoneNumber!
                          : 'Not provided'),
                ]),
              ),
              const SizedBox(height: 14),
              _ProfileAction(
                icon: Icons.shield_outlined,
                iconColor: SolarColors.primary,
                title: 'Account & security',
                subtitle: 'Manage password and account access',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountScreen())),
              ),
              const SizedBox(height: 10),
              _ProfileAction(
                icon: Icons.support_agent_rounded,
                iconColor: SolarColors.limeDark,
                title: 'Help & support',
                subtitle: 'Get assistance with your solar journey',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatInboxScreen())),
              ),
              const SizedBox(height: 20),
              _ProfileCard(
                child: RecordReference(label: 'User reference', value: user.id),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context, auth),
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SolarColors.error,
                  side: const BorderSide(color: Color(0x55B33838)),
                  minimumSize: const Size(double.infinity, 51),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthProvider auth) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content:
            const Text('Are you sure you want to sign out of Smart Solar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SolarColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      }
    }
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ProfileStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => _ProfileCard(
        child: Column(children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: _profileMuted,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8)),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _profileInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ]),
      );
}

class _ProfileCard extends StatelessWidget {
  final Widget child;
  const _ProfileCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SolarColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _profileLine),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10173E44), blurRadius: 18, offset: Offset(0, 7)),
          ],
        ),
        child: child,
      );
}

class _ProfileDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileDetail(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: const Color(0x1207536A),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: SolarColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(color: _profileMuted, fontSize: 9)),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _profileInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ]);
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: _profileLine, height: 1),
      );
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _ProfileAction(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: SolarColors.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _profileLine)),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: _profileInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(
                              color: _profileMuted, fontSize: 10)),
                    ]),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _profileMuted, size: 20),
            ]),
          ),
        ),
      );
}

String _monthName(int month) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month.clamp(1, 12).toInt() - 1];

String _friendlyRole(String role) {
  if (role.toUpperCase() == 'HOMEOWNER') return 'Homeowner';
  return role
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) =>
          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}
