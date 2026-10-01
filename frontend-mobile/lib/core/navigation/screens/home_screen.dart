import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/features/assessment/models/solar_survey.dart';
import 'package:smart_solar_mobile/core/auth/providers/auth_provider.dart';
import 'package:smart_solar_mobile/core/api/api_service.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:smart_solar_mobile/core/utils/constants.dart';
import 'package:smart_solar_mobile/core/widgets/solar_brand.dart';
import 'package:smart_solar_mobile/core/widgets/solar_home_icon.dart';
import 'package:smart_solar_mobile/core/navigation/screens/login_screen.dart';
import 'package:smart_solar_mobile/core/widgets/staff_dashboard.dart';
import 'package:smart_solar_mobile/core/chat/screens/chat_inbox_screen.dart';
import 'package:smart_solar_mobile/core/navigation/screens/profile_screen.dart';
import 'package:smart_solar_mobile/features/engineering/screens/proposal_screen.dart';
import 'package:smart_solar_mobile/features/assessment/screens/survey_screen.dart';
import 'package:smart_solar_mobile/features/field_operations/screens/technician_jobs_screen.dart';
import 'package:smart_solar_mobile/features/field_operations/screens/customer_locations_screen.dart';

const _bg = SolarColors.background;
const _panel = SolarColors.surface;
const _gold = SolarColors.lime;
const _cyan = SolarColors.primary;
const _text = SolarColors.text;
const _muted = SolarColors.muted;
const _line = SolarColors.border;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _unreadMessages = 0;
  Timer? _chatTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadMessages();
    _chatTimer = Timer.periodic(
        const Duration(seconds: 12), (_) => _loadUnreadMessages());
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadMessages() async {
    try {
      final count = await ApiService().getChatUnreadCount();
      if (mounted) setState(() => _unreadMessages = count);
    } catch (_) {}
  }

  Future<void> _openMessages() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ChatInboxScreen()));
    await _loadUnreadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const LoginScreen();
    final homeowner = user.roles.contains(AppConstants.roleHomeowner);
    final fieldTechnician =
        user.roles.contains(AppConstants.roleFieldTechnician);
    final fieldStaff = user.roles.any([
      AppConstants.roleFieldTechnician,
      AppConstants.roleSeniorEngineer,
      AppConstants.roleAdministrator,
    ].contains);
    final locationStaff = user.roles.any([
      AppConstants.roleSeniorEngineer,
      AppConstants.roleAdministrator,
    ].contains);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: Theme.of(context).colorScheme.copyWith(
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
                  unreadMessages: _unreadMessages,
                  onNotifications: _openMessages,
                  onProfile: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
                const SizedBox(height: 24),
                if (homeowner)
                  _HomeownerProjects(
                    showProjectList: _selectedTab == 1,
                    onViewProjects: () => setState(() => _selectedTab = 1),
                  )
                else
                  StaffDashboard(roles: user.roles, name: user.fullName),
                if (!homeowner) const SizedBox(height: 22),
                if (!homeowner)
                  const Text('Quick actions',
                      style: TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                if (!homeowner) const SizedBox(height: 12),
                if (fieldStaff)
                  _ActionTile(
                    icon: Icons.engineering_rounded,
                    title: 'Site jobs & inspections',
                    subtitle: 'View assigned field work',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const TechnicianJobsScreen())),
                  ),
                if (locationStaff)
                  _ActionTile(
                    icon: Icons.map_rounded,
                    title: 'Customer location map',
                    subtitle: 'View confirmed solar installation sites',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CustomerLocationsScreen())),
                  ),
                if (!homeowner)
                  _ActionTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile & security',
                    subtitle: 'Manage your account information',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ProfileScreen())),
                  ),
              ]),
            ),
          ]),
        ),
        bottomNavigationBar: _BottomNav(
          homeowner: homeowner,
          fieldTechnician: fieldTechnician,
          locationStaff: locationStaff,
          selectedIndex: homeowner ? _selectedTab : 0,
          unreadMessages: _unreadMessages,
          onDashboard: () => setState(() => _selectedTab = 0),
          onProjects: () => setState(() => _selectedTab = 1),
          onJobs: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TechnicianJobsScreen())),
          onLocations: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerLocationsScreen())),
          onChat: _openMessages,
          onProfile: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
        ),
      ),
    );
  }
}

class _HomeownerProjects extends StatefulWidget {
  final bool showProjectList;
  final VoidCallback onViewProjects;
  const _HomeownerProjects(
      {required this.showProjectList, required this.onViewProjects});

  @override
  State<_HomeownerProjects> createState() => _HomeownerProjectsState();
}

class _HomeownerProjectsState extends State<_HomeownerProjects> {
  final ApiService _api = ApiService();
  List<SolarSurvey> _projects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await _api.getSurveys();
      final projects = response
          .map((item) =>
              SolarSurvey.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((survey) => survey.surveyStatus.toUpperCase() != 'DRAFT')
          .toList();
      if (mounted) setState(() => _projects = projects);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'We could not load your projects. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSurveys() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SurveyScreen()));
    await _loadProjects();
  }

  Future<void> _openProject(SolarSurvey survey) async {
    final status = survey.surveyStatus.toUpperCase();
    final canOpenProposal = status == 'ANALYSISCOMPLETE' ||
        status == 'APPROVED' ||
        status == 'COMPLETED';
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => canOpenProposal
            ? ProposalScreen(surveyId: survey.id)
            : const SurveyScreen()));
    await _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    final processing = _projects.where((project) {
      final status = project.surveyStatus.toUpperCase();
      return status == 'SUBMITTED' ||
          status == 'PROCESSING' ||
          status == 'UNDERREVIEW';
    }).length;
    final ready = _projects.where((project) {
      final status = project.surveyStatus.toUpperCase();
      return status == 'ANALYSISCOMPLETE' ||
          status == 'APPROVED' ||
          status == 'COMPLETED';
    }).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!widget.showProjectList) ...[
        if (_loading && _projects.isEmpty)
          const _ProjectsLoading()
        else if (_error != null)
          _ProjectsError(message: _error!, onRetry: _loadProjects)
        else
          _FeaturedProject(
            survey: _projects.isEmpty ? null : _projects.first,
            onOpen: _projects.isEmpty
                ? _openSurveys
                : () => _openProject(_projects.first),
          ),
      ],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
            child: _ProjectMetric(
                icon: Icons.folder_copy_outlined,
                value: _loading || _error != null ? '?' : '${_projects.length}',
                label: 'Total projects',
                color: SolarColors.primary)),
        const SizedBox(width: 10),
        Expanded(
            child: _ProjectMetric(
                icon: Icons.autorenew_rounded,
                value: _loading || _error != null ? '?' : '$processing',
                label: 'In review',
                color: _cyan)),
        const SizedBox(width: 10),
        Expanded(
            child: _ProjectMetric(
                icon: Icons.task_alt_rounded,
                value: _loading || _error != null ? '?' : '$ready',
                label: 'Proposal ready',
                color: _gold)),
      ]),
      if (widget.showProjectList) ...[
        const SizedBox(height: 22),
        Row(children: [
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My projects',
                  style: TextStyle(
                      color: _text, fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 3),
              Text('Surveys you have submitted',
                  style: TextStyle(color: _muted, fontSize: 11)),
            ]),
          ),
          IconButton(
            tooltip: 'Refresh projects',
            onPressed: _loading ? null : _loadProjects,
            icon: const Icon(Icons.refresh_rounded),
            color: SolarColors.primary,
          ),
        ]),
        const SizedBox(height: 11),
        if (_loading && _projects.isEmpty)
          const _ProjectsLoading()
        else if (_error != null)
          _ProjectsError(message: _error!, onRetry: _loadProjects)
        else if (_projects.isEmpty)
          _EmptyProjects(onCreate: _openSurveys)
        else ...[
          ..._projects.map((project) => _ProjectCard(
                survey: project,
                onTap: () => _openProject(project),
              )),
          TextButton.icon(
            onPressed: _openSurveys,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('View all surveys'),
            style: TextButton.styleFrom(foregroundColor: SolarColors.primary),
          ),
        ],
      ] else ...[
        const SizedBox(height: 22),
        const Text('Quick actions',
            style: TextStyle(
                color: _text, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _ActionTile(
            icon: Icons.add_home_work_outlined,
            title: 'New survey',
            subtitle: 'Assess another property',
            onTap: _openSurveys),
        _ActionTile(
            icon: Icons.folder_open_outlined,
            title: 'My projects',
            subtitle: 'View all submitted assessments',
            onTap: widget.onViewProjects),
        _ActionTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Contact your team',
            subtitle: 'Get help with your solar project',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatInboxScreen()))),
      ],
    ]);
  }
}

class _FeaturedProject extends StatelessWidget {
  final SolarSurvey? survey;
  final VoidCallback onOpen;
  const _FeaturedProject({required this.survey, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final project = survey;
    final status = project?.surveyStatus.toUpperCase();
    final proposalReady =
        ['ANALYSISCOMPLETE', 'APPROVED', 'COMPLETED'].contains(status);
    // These stages describe survey processing; approval is not installation completion.
    final stage = switch (status) {
      'SUBMITTED' || 'PROCESSING' || 'UNDERREVIEW' => 1,
      'ANALYSISCOMPLETE' => 2,
      'APPROVED' || 'COMPLETED' => 3,
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SolarColors.primary, SolarColors.heroEnd]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Row(children: [
          Icon(Icons.solar_power_rounded,
              color: SolarColors.heroAccent, size: 24),
          SizedBox(width: 10),
          Expanded(
              child: Text('YOUR SOLAR PROJECT',
                  style: TextStyle(
                      color: SolarColors.heroText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)))
        ]),
        const SizedBox(height: 18),
        Text(
            project == null
                ? 'Start your solar journey'
                : project.propertyAddress.isEmpty
                    ? 'Your current solar project'
                    : project.propertyAddress,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(
            project == null
                ? 'Tell us about your property and electricity usage to receive a personalised solar recommendation.'
                : _friendlyProjectStatus(project.surveyStatus),
            style: const TextStyle(
                color: SolarColors.heroText, fontSize: 14, height: 1.5)),
        if (project != null) ...[
          const SizedBox(height: 12),
          Text(
              '${project.monthlyKwh.toStringAsFixed(0)} kWh / month${project.recommendedKw == null ? '' : ' ? ${project.recommendedKw!.toStringAsFixed(1)} kW recommended'}',
              style:
                  const TextStyle(color: SolarColors.heroText, fontSize: 13)),
          if (stage != null) ...[
            const SizedBox(height: 20),
            Semantics(
                label:
                    'Project progress: ${_friendlyProjectStatus(project.surveyStatus)}',
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.only(right: i == 3 ? 0 : 8),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                              color: i <= stage
                                                  ? SolarColors.heroAccent
                                                  : Colors.white24,
                                              borderRadius:
                                                  BorderRadius.circular(4))),
                                      const SizedBox(height: 8),
                                      Text(
                                          [
                                            'Submitted',
                                            'In review',
                                            'Proposal',
                                            'Approved'
                                          ][i],
                                          style: TextStyle(
                                              color: i <= stage
                                                  ? Colors.white
                                                  : SolarColors.heroText,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ]))),
                    ])),
          ],
          const SizedBox(height: 12),
          Text(
              status == 'FAILED'
                  ? 'Your assessment needs attention. Open surveys to review it.'
                  : proposalReady
                      ? 'Your recommendation is available. Open your proposal to see the details.'
                      : 'Your assessment is being reviewed. Open surveys to check its status.',
              style: const TextStyle(
                  color: SolarColors.heroText, fontSize: 13, height: 1.5)),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
            onPressed: onOpen,
            icon: Icon(
                project == null
                    ? Icons.add_rounded
                    : Icons.arrow_forward_rounded,
                size: 18),
            label: Text(project == null
                ? 'Start your first survey'
                : proposalReady
                    ? 'View proposal'
                    : 'View survey status'),
            style: FilledButton.styleFrom(
                backgroundColor: SolarColors.heroAccent,
                foregroundColor: SolarColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w800))),
      ]),
    );
  }
}

class _ProjectMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _ProjectMetric(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => _Glass(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 7),
          Text(value,
              style: const TextStyle(
                  color: _text, fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 9)),
        ]),
      );
}

class _ProjectCard extends StatelessWidget {
  final SolarSurvey survey;
  final VoidCallback onTap;
  const _ProjectCard({required this.survey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _friendlyProjectStatus(survey.surveyStatus);
    final color = _projectStatusColor(survey.surveyStatus);
    final reference =
        survey.id.length > 8 ? survey.id.substring(0, 8) : survey.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(13)),
                  child: Icon(Icons.home_work_outlined, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            survey.propertyAddress.isEmpty
                                ? 'Solar project'
                                : survey.propertyAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Project #$reference',
                            style:
                                const TextStyle(color: _muted, fontSize: 10)),
                      ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: _muted),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(status,
                      style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                Text('${survey.monthlyKwh.toStringAsFixed(0)} kWh/mo',
                    style: const TextStyle(
                        color: _text,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Text('${survey.roofAreaSqm.toStringAsFixed(0)} m²',
                    style: const TextStyle(color: _muted, fontSize: 10)),
              ]),
              if (survey.recommendedKw != null) ...[
                const SizedBox(height: 12),
                const Divider(color: _line, height: 1),
                const SizedBox(height: 11),
                Row(children: [
                  const Icon(Icons.bolt_rounded, color: _gold, size: 17),
                  const SizedBox(width: 6),
                  Text(
                      '${survey.recommendedKw!.toStringAsFixed(1)} kW recommended',
                      style: const TextStyle(
                          color: _text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${survey.panelCount ?? '-'} panels',
                      style: const TextStyle(color: _muted, fontSize: 10)),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _ProjectsLoading extends StatelessWidget {
  const _ProjectsLoading();
  @override
  Widget build(BuildContext context) => const _Glass(
        child: SizedBox(
          height: 84,
          child: Center(
              child: CircularProgressIndicator(color: _gold, strokeWidth: 2.5)),
        ),
      );
}

class _ProjectsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ProjectsError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => _Glass(
        child: Column(children: [
          const Icon(Icons.cloud_off_rounded,
              color: SolarColors.error, size: 28),
          const SizedBox(height: 9),
          Text(message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: _muted, fontSize: 11, height: 1.45)),
          const SizedBox(height: 9),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      );
}

class _EmptyProjects extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyProjects({required this.onCreate});
  @override
  Widget build(BuildContext context) => _Glass(
        child: Column(children: [
          Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                  color: const Color(0x1872B83E),
                  borderRadius: BorderRadius.circular(17)),
              child: const Icon(Icons.roofing_rounded, color: _gold, size: 28)),
          const SizedBox(height: 12),
          const Text('No submitted projects yet',
              style: TextStyle(color: _text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          const Text('Complete your first solar survey to start a project.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: onCreate, child: const Text('Create first survey')),
        ]),
      );
}

String _friendlyProjectStatus(String rawStatus) {
  switch (rawStatus.toUpperCase()) {
    case 'SUBMITTED':
      return 'Submitted';
    case 'PROCESSING':
      return 'Analysing';
    case 'ANALYSISCOMPLETE':
      return 'Proposal ready';
    case 'UNDERREVIEW':
      return 'Under review';
    case 'APPROVED':
      return 'Approved';
    case 'COMPLETED':
      return 'Completed';
    case 'FAILED':
      return 'Needs attention';
    default:
      return rawStatus;
  }
}

Color _projectStatusColor(String rawStatus) {
  switch (rawStatus.toUpperCase()) {
    case 'APPROVED':
    case 'COMPLETED':
    case 'ANALYSISCOMPLETE':
      return _cyan;
    case 'FAILED':
      return SolarColors.error;
    case 'SUBMITTED':
    case 'PROCESSING':
    case 'UNDERREVIEW':
      return SolarColors.warning;
    default:
      return _muted;
  }
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final int unreadMessages;
  const _Header(
      {required this.name,
      required this.onProfile,
      required this.onNotifications,
      required this.unreadMessages});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SolarBrand(size: 16),
          const SizedBox(height: 5),
          Text(
              'Hello, ${name.trim().isEmpty ? 'there' : name.trim().split(' ').first}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
        ])),
        Stack(clipBehavior: Clip.none, children: [
          IconButton(
              tooltip: 'Messages & notifications',
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none_rounded),
              color: _muted),
          if (unreadMessages > 0)
            Positioned(
              right: 5,
              top: 4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: SolarColors.error, shape: BoxShape.circle),
                child: Text(unreadMessages > 99 ? '99+' : '$unreadMessages',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
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
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(name.trim().split(' ').first,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))),
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
  final bool homeowner;
  final bool fieldTechnician;
  final bool locationStaff;
  final int selectedIndex;
  final int unreadMessages;
  final VoidCallback onDashboard;
  final VoidCallback onProjects;
  final VoidCallback onJobs;
  final VoidCallback onLocations;
  final VoidCallback onChat;
  final VoidCallback onProfile;
  const _BottomNav({
    required this.homeowner,
    required this.fieldTechnician,
    required this.locationStaff,
    required this.selectedIndex,
    required this.unreadMessages,
    required this.onDashboard,
    required this.onProjects,
    required this.onJobs,
    required this.onLocations,
    required this.onChat,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            color: SolarColors.surface,
            border: Border(top: BorderSide(color: _line))),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: SafeArea(
            top: false,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                      icon: Icons.solar_power_rounded,
                      solarHome: true,
                      label: 'Home',
                      selected: selectedIndex == 0,
                      onTap: onDashboard),
                  if (homeowner) ...[
                    _NavItem(
                        icon: Icons.folder_copy_outlined,
                        label: 'My Projects',
                        selected: selectedIndex == 1,
                        onTap: onProjects),
                    _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        badgeCount: unreadMessages,
                        onTap: onChat),
                    _NavItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        onTap: onProfile),
                  ] else if (fieldTechnician) ...[
                    _NavItem(
                        icon: Icons.assignment_outlined,
                        label: 'My Jobs',
                        onTap: onJobs),
                    _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        badgeCount: unreadMessages,
                        onTap: onChat),
                    _NavItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        onTap: onProfile),
                  ] else if (locationStaff) ...[
                    _NavItem(
                        icon: Icons.map_outlined,
                        label: 'Locations',
                        onTap: onLocations),
                    _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        badgeCount: unreadMessages,
                        onTap: onChat),
                    _NavItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        onTap: onProfile),
                  ] else ...[
                    _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        badgeCount: unreadMessages,
                        onTap: onChat),
                    _NavItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        onTap: onProfile),
                  ],
                ])),
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool solarHome;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback? onTap;
  const _NavItem(
      {required this.icon,
      this.solarHome = false,
      required this.label,
      this.selected = false,
      this.badgeCount = 0,
      this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
          color: selected ? SolarColors.surfaceSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Badge(
                    isLabelVisible: badgeCount > 0,
                    label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                    backgroundColor: SolarColors.error,
                    child: solarHome
                        ? SolarHomeIcon(selected: selected)
                        : Icon(icon,
                            color: selected ? SolarColors.primary : _muted,
                            size: 21),
                  ),
                  const SizedBox(height: 4),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: selected ? SolarColors.primary : _muted,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500))
                ]),
              ),
            ),
          ),
        ),
      );
}
