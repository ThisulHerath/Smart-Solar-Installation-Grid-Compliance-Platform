import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/solar_survey.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/solar_theme.dart';
import '../utils/constants.dart';
import '../widgets/solar_brand.dart';
import 'login_screen.dart';
import 'chat_inbox_screen.dart';
import 'profile_screen.dart';
import 'proposal_screen.dart';
import 'survey_screen.dart';
import 'technician_jobs_screen.dart';
import 'welcome_screen.dart';
import 'customer_locations_screen.dart';

const _bg = SolarColors.background;
const _panel = SolarColors.surface;
const _gold = SolarColors.lime;
const _cyan = Color(0xFF087D75);
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
                  unreadMessages: _unreadMessages,
                  onNotifications: _openMessages,
                  onProfile: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
                const SizedBox(height: 24),
                if (homeowner)
                  _HomeownerProjects(
                    firstName: user.fullName.split(' ').first,
                    showProjectList: _selectedTab == 1,
                    onViewProjects: () => setState(() => _selectedTab = 1),
                  )
                else ...[
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
                ],
                if (!homeowner || _selectedTab == 0) const SizedBox(height: 22),
                if (!homeowner || _selectedTab == 0)
                  const Text('Quick actions',
                      style: TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                if (!homeowner || _selectedTab == 0) const SizedBox(height: 12),
                if (homeowner && _selectedTab == 0)
                  _ActionTile(
                    icon: Icons.add_home_work_outlined,
                    title: 'Create a new survey',
                    subtitle: 'Start another solar assessment',
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
                if (locationStaff)
                  _ActionTile(
                    icon: Icons.map_rounded,
                    title: 'Customer location map',
                    subtitle: 'View confirmed solar installation sites',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CustomerLocationsScreen())),
                  ),
                if (!homeowner || _selectedTab == 0)
                  _ActionTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile & security',
                    subtitle: 'Manage your account information',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ProfileScreen())),
                  ),
                if (!homeowner || _selectedTab == 0) const SizedBox(height: 10),
                if (!homeowner || _selectedTab == 0)
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

class _HomeownerProjects extends StatefulWidget {
  final String firstName;
  final bool showProjectList;
  final VoidCallback onViewProjects;
  const _HomeownerProjects(
      {required this.firstName,
      required this.showProjectList,
      required this.onViewProjects});

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
      if (!widget.showProjectList)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SolarColors.primary, Color(0xFF214F50)],
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x28173E44),
                  blurRadius: 24,
                  offset: Offset(0, 10)),
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: _gold, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.solar_power_rounded,
                  color: SolarColors.primary, size: 25),
            ),
            const SizedBox(height: 18),
            Text('Hello ${widget.firstName},',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            const Text('Your solar journey',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.12,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            const Text(
                'Track every submitted site survey and continue your installation from one place.',
                style: TextStyle(
                    color: Color(0xFFD8E7E4), fontSize: 12, height: 1.5)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openSurveys,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Start a new survey'),
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: SolarColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ]),
        ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
            child: _ProjectMetric(
                icon: Icons.folder_copy_outlined,
                value: '${_projects.length}',
                label: 'Total projects',
                color: SolarColors.primary)),
        const SizedBox(width: 10),
        Expanded(
            child: _ProjectMetric(
                icon: Icons.autorenew_rounded,
                value: '$processing',
                label: 'In progress',
                color: _cyan)),
        const SizedBox(width: 10),
        Expanded(
            child: _ProjectMetric(
                icon: Icons.task_alt_rounded,
                value: '$ready',
                label: 'Ready',
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
      ] else
        _DashboardInsights(
          projects: _projects,
          totalProjects: _projects.length,
          processingProjects: processing,
          readyProjects: ready,
          onCreateSurvey: _openSurveys,
          onViewProjects: widget.onViewProjects,
        ),
    ]);
  }
}

class _DashboardInsights extends StatelessWidget {
  final List<SolarSurvey> projects;
  final int totalProjects;
  final int processingProjects;
  final int readyProjects;
  final VoidCallback onCreateSurvey;
  final VoidCallback onViewProjects;
  const _DashboardInsights({
    required this.projects,
    required this.totalProjects,
    required this.processingProjects,
    required this.readyProjects,
    required this.onCreateSurvey,
    required this.onViewProjects,
  });

  @override
  Widget build(BuildContext context) {
    final title = totalProjects == 0
        ? 'Start your first assessment'
        : readyProjects > 0
            ? '$readyProjects project${readyProjects == 1 ? '' : 's'} ready for review'
            : processingProjects > 0
                ? 'Your solar analysis is in progress'
                : 'Create your next solar project';
    final description = totalProjects == 0
        ? 'Submit your electricity usage, roof area and address to receive a personalised solar recommendation.'
        : readyProjects > 0
            ? 'Open My Projects to review the recommendations and continue with a proposal.'
            : processingProjects > 0
                ? 'We are preparing your system recommendation. You can track its live status in My Projects.'
                : 'Use a new survey whenever you want to assess another property.';

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 20),
      _Glass(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: const Color(0x1872B83E),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(
                  readyProjects > 0
                      ? Icons.task_alt_rounded
                      : processingProjects > 0
                          ? Icons.auto_awesome_rounded
                          : Icons.wb_sunny_outlined,
                  color: _gold,
                  size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('YOUR NEXT STEP',
                  style: TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1)),
            ),
          ]),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  color: _text, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(description,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.5)),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: readyProjects > 0 || processingProjects > 0
                ? onViewProjects
                : onCreateSurvey,
            icon: Icon(
                readyProjects > 0 || processingProjects > 0
                    ? Icons.folder_open_outlined
                    : Icons.add_rounded,
                size: 18),
            label: Text(readyProjects > 0 || processingProjects > 0
                ? 'Open My Projects'
                : 'Create survey'),
            style: FilledButton.styleFrom(
                backgroundColor: SolarColors.primary,
                foregroundColor: Colors.white),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      _ProjectProgressChart(
        total: totalProjects,
        processing: processingProjects,
        ready: readyProjects,
      ),
      const SizedBox(height: 14),
      _EnergyUsageChart(projects: projects),
      const SizedBox(height: 14),
      const _Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How your project moves forward',
              style: TextStyle(
                  color: _text, fontSize: 15, fontWeight: FontWeight.w800)),
          SizedBox(height: 16),
          _JourneyStep(
              number: '1',
              title: 'Submit survey',
              subtitle: 'Tell us about your property and energy needs.'),
          _JourneyLine(),
          _JourneyStep(
              number: '2',
              title: 'Review recommendation',
              subtitle: 'See suggested system size and panel count.'),
          _JourneyLine(),
          _JourneyStep(
              number: '3',
              title: 'Continue to proposal',
              subtitle: 'Track engineering review and project approval.'),
        ]),
      ),
    ]);
  }
}

class _ProjectProgressChart extends StatelessWidget {
  final int total;
  final int processing;
  final int ready;
  const _ProjectProgressChart(
      {required this.total, required this.processing, required this.ready});

  @override
  Widget build(BuildContext context) {
    final other = math.max(0, total - processing - ready);
    return _Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Expanded(
              child: Text('Project progress',
                  style: TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800))),
          Icon(Icons.donut_large_rounded, color: _cyan, size: 19),
        ]),
        const SizedBox(height: 4),
        const Text('Current status of your submitted surveys',
            style: TextStyle(color: _muted, fontSize: 10)),
        const SizedBox(height: 17),
        Row(children: [
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: _ProjectDonutPainter(
                  total: total, processing: processing, ready: ready),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total',
                      style: const TextStyle(
                          color: _text,
                          fontSize: 25,
                          fontWeight: FontWeight.w800)),
                  const Text('PROJECTS',
                      style: TextStyle(
                          color: _muted,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .8)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(children: [
              _ChartLegend(
                  color: _cyan, label: 'Ready', value: ready.toString()),
              const SizedBox(height: 11),
              _ChartLegend(
                  color: const Color(0xFFE09A10),
                  label: 'In progress',
                  value: processing.toString()),
              const SizedBox(height: 11),
              _ChartLegend(
                  color: _line, label: 'Other', value: other.toString()),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _ChartLegend(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: const TextStyle(color: _muted, fontSize: 10))),
        Text(value,
            style: const TextStyle(
                color: _text, fontSize: 11, fontWeight: FontWeight.w800)),
      ]);
}

class _ProjectDonutPainter extends CustomPainter {
  final int total;
  final int processing;
  final int ready;
  const _ProjectDonutPainter(
      {required this.total, required this.processing, required this.ready});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawArc(rect.deflate(8), -.5 * math.pi, 2 * math.pi, false, base);
    if (total <= 0) return;

    const gap = .07;
    var start = -.5 * math.pi;
    void drawSection(int value, Color color) {
      if (value <= 0) return;
      final sweep = (2 * math.pi * value / total) - gap;
      canvas.drawArc(
          rect.deflate(8),
          start,
          math.max(.02, sweep).toDouble(),
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..strokeCap = StrokeCap.round);
      start += 2 * math.pi * value / total;
    }

    drawSection(ready, _cyan);
    drawSection(processing, const Color(0xFFE09A10));
  }

  @override
  bool shouldRepaint(covariant _ProjectDonutPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.processing != processing ||
      oldDelegate.ready != ready;
}

class _EnergyUsageChart extends StatelessWidget {
  final List<SolarSurvey> projects;
  const _EnergyUsageChart({required this.projects});

  @override
  Widget build(BuildContext context) {
    final visible = projects.take(5).toList();
    final values = visible.map((project) => project.monthlyKwh).toList();
    final average =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
    return _Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Energy profile',
                  style: TextStyle(
                      color: _text, fontSize: 15, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Monthly usage across recent projects',
                  style: TextStyle(color: _muted, fontSize: 10)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(average == 0 ? '—' : average.toStringAsFixed(0),
                style: const TextStyle(
                    color: _text, fontSize: 18, fontWeight: FontWeight.w800)),
            const Text('AVG kWh',
                style: TextStyle(
                    color: _muted, fontSize: 7, fontWeight: FontWeight.w700)),
          ]),
        ]),
        const SizedBox(height: 18),
        if (values.isEmpty)
          Container(
            height: 105,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _bg, borderRadius: BorderRadius.circular(13)),
            child: const Text('Create a survey to see your energy chart',
                style: TextStyle(color: _muted, fontSize: 10)),
          )
        else ...[
          SizedBox(
            height: 105,
            width: double.infinity,
            child: CustomPaint(painter: _UsageBarPainter(values)),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(values.length, (index) {
              final reference = visible[index].id;
              return Text(
                  reference.length > 4
                      ? '#${reference.substring(0, 4)}'
                      : '#$reference',
                  style: const TextStyle(color: _muted, fontSize: 8));
            }),
          ),
        ],
      ]),
    );
  }
}

class _UsageBarPainter extends CustomPainter {
  final List<double> values;
  const _UsageBarPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _line
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maxValue = values.fold<double>(1, math.max);
    final slot = size.width / values.length;
    final width = math.min(28.0, slot * .46).toDouble();
    for (var i = 0; i < values.length; i++) {
      final height =
          math.max(8.0, size.height * values[i] / maxValue).toDouble();
      final left = slot * i + (slot - width) / 2;
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - height, width, height),
          const Radius.circular(7));
      canvas.drawRRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [_cyan, _gold]).createShader(rect.outerRect));
    }
  }

  @override
  bool shouldRepaint(covariant _UsageBarPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _JourneyStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  const _JourneyStep(
      {required this.number, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Row(children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: SolarColors.primary,
          child: Text(number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: _text, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 10)),
          ]),
        ),
      ]);
}

class _JourneyLine extends StatelessWidget {
  const _JourneyLine();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(left: 14),
        child: SizedBox(
          height: 15,
          child: VerticalDivider(color: _line, width: 1, thickness: 1),
        ),
      );
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
                            survey.projectName,
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
      return const Color(0xFFE09A10);
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
        const SolarBrand(size: 18),
        const Spacer(),
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
              height: 112,
              child: LayoutBuilder(builder: (context, constraints) {
                const solar = [66.0, 78.0, 58.0, 88.0, 73.0, 94.0, 82.0];
                const grid = [28.0, 22.0, 35.0, 18.0, 27.0, 13.0, 20.0];
                const tallestValue = 94.0;
                final availableBarHeight = constraints.maxHeight - 18;

                double scaledHeight(double value) =>
                    value / tallestValue * availableBarHeight;

                return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (i) {
                      return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                      width: 8,
                                      height: scaledHeight(solar[i]),
                                      decoration: BoxDecoration(
                                          color: _gold,
                                          borderRadius:
                                              BorderRadius.circular(6))),
                                  const SizedBox(width: 3),
                                  Container(
                                      width: 8,
                                      height: scaledHeight(grid[i]),
                                      decoration: BoxDecoration(
                                          color: _cyan,
                                          borderRadius:
                                              BorderRadius.circular(6))),
                                ]),
                            const SizedBox(height: 6),
                            Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                style: const TextStyle(
                                    color: _muted, fontSize: 8)),
                          ]);
                    }));
              })),
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
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
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
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback? onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      this.selected = false,
      this.badgeCount = 0,
      this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
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
                  child: Icon(icon, color: selected ? _gold : _muted, size: 21),
                ),
                const SizedBox(height: 4),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: selected ? _gold : _muted,
                        fontSize: 9,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500))
              ]),
            ),
          ),
        ),
      );
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
