import '../widgets/record_reference.dart';
import 'package:flutter/material.dart';
import '../theme/solar_theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'account_screen.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';

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
    return Scaffold(
        appBar: AppBar(title: const Text('My profile')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  Center(
                      child: CircleAvatar(
                          radius: 46,
                          backgroundColor: solarLime,
                          child: Text(initials,
                              style: const TextStyle(
                                  color: solarForest,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 18),
                  Text(user.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: user.roles
                          .map((role) =>
                              Chip(label: Text(role.replaceAll('_', ' '))))
                          .toList()),
                  RecordReference(label: 'User reference', value: user.id),
                  const SizedBox(height: 24),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(children: [
                            ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: const Text('Full name'),
                                subtitle: Text(user.fullName)),
                            ListTile(
                                leading: const Icon(Icons.mail_outline),
                                title: const Text('Email address'),
                                subtitle: Text(user.email)),
                            ListTile(
                                leading: const Icon(Icons.phone_outlined),
                                title: const Text('Phone number'),
                                subtitle: Text(
                                    user.phoneNumber?.isNotEmpty == true
                                        ? user.phoneNumber!
                                        : 'Not provided')),
                            ListTile(
                                leading:
                                    const Icon(Icons.calendar_today_outlined),
                                title: const Text('Member since'),
                                subtitle: Text(
                                    '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}')),
                          ]))),
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      leading: const Icon(Icons.shield_outlined,
                          color: SolarColors.primary),
                      title: const Text('Account & security'),
                      subtitle: const Text(
                          'Manage your password and account access.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const AccountScreen())),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign out'),
                          content: const Text(
                              'Are you sure you want to sign out of Smart Solar?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: SolarColors.error),
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
                            MaterialPageRoute(
                                builder: (_) => const WelcomeScreen()),
                            (_) => false,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ]))));
  }
}
