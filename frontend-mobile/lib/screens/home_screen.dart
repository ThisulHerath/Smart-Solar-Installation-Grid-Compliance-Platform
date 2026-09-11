import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/status_badge.dart';
import 'login_screen.dart';
import 'survey_screen.dart';
import 'technician_jobs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final roles = user?.roles ?? [];
    final homeowner = roles.contains(AppConstants.roleHomeowner);
    final fieldStaff = roles.any([
      AppConstants.roleFieldTechnician,
      AppConstants.roleSeniorEngineer,
      AppConstants.roleAdministrator,
    ].contains);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        title: const Text('Smart Solar'),
        actions: [IconButton(
          tooltip: 'Sign out', icon: const Icon(Icons.logout),
          onPressed: () async {
            await auth.logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            }
          },
        )],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Icon(Icons.solar_power, color: Color(0xFF10B981), size: 56),
        const SizedBox(height: 20),
        Text('Welcome, ${user?.fullName ?? 'there'}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text(user?.email ?? '', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8,
          children: roles.map((r) => StatusBadge(label: r)).toList()),
        const SizedBox(height: 28),
        if (homeowner) ...[
          const Text('Plan solar for your home', style: TextStyle(fontSize: 20, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Create a survey, add roof photos, and follow your engineering proposal and equipment estimate.',
            style: TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SurveyScreen())),
            icon: const Icon(Icons.home_work), label: const Text('My solar surveys')),
        ],
        if (fieldStaff) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TechnicianJobsScreen())),
            icon: const Icon(Icons.engineering), label: const Text('Site jobs and inspections')),
        ],
        const SizedBox(height: 24),
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(
          homeowner
            ? 'Estimates are in Sri Lankan rupees. An engineer reviews the proposal before equipment can be reserved. Grid connection remains subject to the relevant utility’s approval.'
            : 'Use the staff web portal for engineering approvals, inventory management, and operational reports. The mobile app supports field inspections and site photos.',
          style: const TextStyle(height: 1.5)))),
      ]),
    );
  }
}
