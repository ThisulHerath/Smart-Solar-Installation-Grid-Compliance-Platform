import '../theme/solar_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/status_badge.dart';
import 'login_screen.dart';
import 'survey_screen.dart';
import 'technician_jobs_screen.dart';
import 'profile_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const LoginScreen();
    final roles = user.roles;
    final homeowner = roles.contains(AppConstants.roleHomeowner);
    final fieldStaff = roles.any([
      AppConstants.roleFieldTechnician,
      AppConstants.roleSeniorEngineer,
      AppConstants.roleAdministrator,
    ].contains);
    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
        title: const Text('Smart Solar'),
        actions: [
          IconButton(
            tooltip: 'My profile',
            icon: const Icon(Icons.manage_accounts),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
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
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          children: [
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE3ECCF), SolarColors.background],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: SolarColors.border)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: SolarColors.lime,
                                borderRadius: BorderRadius.circular(16)),
                            child:
                                const Icon(Icons.wb_sunny_outlined, size: 30)),
                        const SizedBox(width: 12),
                        const Expanded(
                            child: Text('YOUR SOLAR WORKSPACE',
                                style: TextStyle(
                                    letterSpacing: 1.8,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)))
                      ]),
                      const SizedBox(height: 24),
                      Text('Hello, ${user.fullName.split(' ').first}.',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1)),
                      const SizedBox(height: 8),
                      Text(
                          homeowner
                              ? 'A brighter home starts with a clear plan.'
                              : 'Your next site visit. Every detail in reach.',
                          style: const TextStyle(
                              color: SolarColors.muted,
                              fontSize: 16,
                              height: 1.5)),
                      const SizedBox(height: 20),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              roles.map((r) => StatusBadge(label: r)).toList()),
                    ])),
            const SizedBox(height: 28),
            const Text('Ready for your next step?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (homeowner) ...[
              const Text('Plan solar for your home',
                  style: TextStyle(fontSize: 20, color: SolarColors.text)),
              const SizedBox(height: 12),
              const Text(
                  'Create a survey, add roof photos, and follow your engineering proposal and equipment estimate.',
                  style: TextStyle(color: SolarColors.muted, height: 1.5)),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SurveyScreen())),
                  icon: const Icon(Icons.home_work),
                  label: const Text('My solar surveys')),
            ],
            if (fieldStaff) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TechnicianJobsScreen())),
                  icon: const Icon(Icons.engineering),
                  label: const Text('Site jobs and inspections')),
            ],
            const SizedBox(height: 20),
            Card(
                child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Your profile'),
                    subtitle: const Text(
                        'Contact details, references and account security'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ProfileScreen())))),
            const SizedBox(height: 8),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                        homeowner
                            ? 'Estimates are in Sri Lankan rupees. An engineer reviews the proposal before equipment can be reserved. Grid connection remains subject to the relevant utility’s approval.'
                            : 'Use the staff web portal for engineering approvals, inventory management, and operational reports. The mobile app supports field inspections and site photos.',
                        style: const TextStyle(height: 1.5)))),
          ]),
    );
  }
}
