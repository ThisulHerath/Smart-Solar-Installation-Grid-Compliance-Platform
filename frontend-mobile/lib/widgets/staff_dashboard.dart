import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/solar_theme.dart';
import '../utils/constants.dart';
import '../screens/technician_jobs_screen.dart';
import '../screens/customer_locations_screen.dart';
import '../screens/chat_inbox_screen.dart';
import 'workspace_header.dart';

/// Role-specific presentation of existing reporting and field-work APIs.
class StaffDashboard extends StatefulWidget {
  final List<String> roles;
  final String name;
  final ApiService? api;
  const StaffDashboard(
      {super.key, required this.roles, required this.name, this.api});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  late final ApiService _api = widget.api ?? ApiService();
  Map<String, dynamic>? _report;
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  bool _failed = false;

  String get _role {
    for (final role in [
      AppConstants.roleAdministrator,
      AppConstants.roleSeniorEngineer,
      AppConstants.roleInventoryOfficer,
      AppConstants.roleFieldTechnician
    ]) {
      if (widget.roles.contains(role)) return role;
    }
    return '';
  }

  bool get _technician => _role == AppConstants.roleFieldTechnician;
  bool get _inventory => _role == AppConstants.roleInventoryOfficer;
  bool get _admin => _role == AppConstants.roleAdministrator;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      if (_technician) {
        final rows = await _api.getTechnicianJobs();
        if (!mounted) return;
        _jobs =
            rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
      } else if (_role.isNotEmpty) {
        final report = await _api.get('/api/reports/overview');
        if (!mounted) return;
        _report = Map<String, dynamic>.from(report as Map);
      }
    } catch (_) {
      if (mounted) _failed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _count(String key) => (_report?[key] as num?)?.toString() ?? '—';
  int _jobCount(List<String> statuses) => _jobs
      .where((job) => statuses.contains(
          (job['status'] as String? ?? '').replaceAll('_', '').toUpperCase()))
      .length;

  @override
  Widget build(BuildContext context) {
    final title = _admin
        ? 'Administration'
        : _inventory
            ? 'Inventory workspace'
            : _technician
                ? 'Field workspace'
                : 'Engineering workspace';
    final description = _admin
        ? 'A clear view of surveys, engineering approvals and equipment readiness.'
        : _inventory
            ? 'Keep equipment availability and project reservations in view.'
            : _technician
                ? 'Your site visits, inspection evidence and next steps, together.'
                : 'Follow solar assessments from site inspection to engineering approval.';
    final metrics = _technician
        ? [
            (
              'Assigned jobs',
              '${_jobs.length}',
              Icons.assignment_outlined,
              SolarColors.primary
            ),
            (
              'To visit',
              '${_jobCount(['ASSIGNED'])}',
              Icons.location_on_outlined,
              SolarColors.warning
            ),
            (
              'In progress',
              '${_jobCount(['INPROGRESS'])}',
              Icons.engineering_outlined,
              SolarColors.info
            ),
            (
              'Compliance complete',
              '${_jobCount(['COMPLIANCECOMPLETE'])}',
              Icons.verified_outlined,
              SolarColors.success
            ),
          ]
        : [
            (
              _inventory ? 'Low stock items' : 'Solar surveys',
              _count(_inventory ? 'lowStockItems' : 'surveyCount'),
              _inventory ? Icons.inventory_2_outlined : Icons.roofing_outlined,
              SolarColors.primary
            ),
            (
              'Awaiting approval',
              _count('pendingApprovals'),
              Icons.pending_actions_rounded,
              SolarColors.warning
            ),
            (
              'Approved proposals',
              _count('approvedProposals'),
              Icons.task_alt_rounded,
              SolarColors.success
            ),
            (
              _inventory ? 'Solar surveys' : 'Low stock items',
              _count(_inventory ? 'surveyCount' : 'lowStockItems'),
              Icons.solar_power_outlined,
              SolarColors.info
            ),
          ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      WorkspaceHeader(
          eyebrow: title,
          title: 'Welcome back, ${widget.name.trim().split(' ').first}',
          description: description,
          icon: _inventory
              ? Icons.inventory_2_outlined
              : _technician
                  ? Icons.engineering_outlined
                  : _admin
                      ? Icons.space_dashboard_outlined
                      : Icons.architecture_rounded),
      const SizedBox(height: 20),
      Row(children: [
        const Expanded(
            child: Text('Your work at a glance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        IconButton(
            tooltip: 'Refresh overview',
            onPressed: _loading ? null : _load,
            icon:
                const Icon(Icons.refresh_rounded, color: SolarColors.primary)),
      ]),
      const SizedBox(height: 8),
      if (_loading)
        const Card(
            child: Padding(
                padding: EdgeInsets.all(28),
                child: Row(children: [
                  SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 16),
                  Expanded(child: Text('Loading your overview…')),
                ])))
      else if (_failed)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          color: SolarColors.muted),
                      const SizedBox(height: 10),
                      const Text('Overview unavailable',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text(
                          'Please try again. Your workspace shortcuts are still available.',
                          style:
                              TextStyle(color: SolarColors.muted, height: 1.5)),
                      TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again')),
                    ])))
      else ...[
        LayoutBuilder(builder: (context, constraints) {
          final singleColumn = constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: metrics
                  .map((metric) => SizedBox(
                      width: singleColumn
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2,
                      child: WorkspaceMetric(
                          label: metric.$1,
                          value: metric.$2,
                          icon: metric.$3,
                          color: metric.$4)))
                  .toList());
        }),
        const SizedBox(height: 18),
        if (_technician) _jobProgress() else _approvalProgress(),
      ],
      const SizedBox(height: 18),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('KEEP WORK MOVING',
                        style: TextStyle(
                            color: SolarColors.limeDark,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(
                        _inventory
                            ? 'Coordinate equipment readiness'
                            : _technician
                                ? 'Make every site visit count'
                                : 'Keep the project team connected',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                        _inventory
                            ? 'Review the stock summary above and coordinate project needs with the team. Catalog edits and reservations are available in the web workspace.'
                            : _technician
                                ? 'Open an assignment to check the site, capture photos and complete your inspection.'
                                : 'Review confirmed customer locations and follow up with the project team. Approvals and staff management are available in the web workspace.',
                        style: const TextStyle(
                            color: SolarColors.muted,
                            fontSize: 13,
                            height: 1.6)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                        onPressed: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute<void>(
                                  builder: (_) => _inventory
                                      ? const ChatInboxScreen()
                                      : _technician
                                          ? const TechnicianJobsScreen()
                                          : const CustomerLocationsScreen()));
                          if (mounted) _load();
                        },
                        icon: Icon(_inventory
                            ? Icons.forum_outlined
                            : _technician
                                ? Icons.assignment_outlined
                                : Icons.map_outlined),
                        label: Text(_inventory
                            ? 'Open messages'
                            : _technician
                                ? 'View site jobs'
                                : 'Explore customer sites')),
                  ]))),
    ]);
  }

  Widget _jobProgress() {
    final complete = _jobCount(['COMPLIANCECOMPLETE']);
    return _progressCard(
        'Inspection progress',
        complete,
        _jobs.length,
        _jobs.isEmpty
            ? 'No assignments yet. New site visits will appear here.'
            : '$complete of ${_jobs.length} jobs have completed compliance.');
  }

  Widget _approvalProgress() {
    final approved = (_report?['approvedProposals'] as num?)?.toInt() ?? 0;
    final pending = (_report?['pendingApprovals'] as num?)?.toInt() ?? 0;
    return _progressCard(
        'Approval snapshot',
        approved,
        approved + pending,
        approved + pending == 0
            ? 'No pending or approved proposals yet.'
            : '$approved approved · $pending awaiting approval');
  }

  Widget _progressCard(String title, int complete, int total, String caption) =>
      Card(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: total == 0 ? 0 : complete / total,
                            minHeight: 9,
                            semanticsLabel: title,
                            semanticsValue:
                                '${total == 0 ? 0 : (100 * complete / total).round()}%')),
                    const SizedBox(height: 10),
                    Text(caption,
                        style: const TextStyle(
                            color: SolarColors.muted,
                            fontSize: 12,
                            height: 1.5)),
                  ])));
}
