import 'package:flutter/material.dart';
import 'package:smart_solar_mobile/features/engineering/models/proposal.dart';
import 'package:smart_solar_mobile/core/api/api_service.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:smart_solar_mobile/features/inventory/widgets/equipment_summary.dart';
import 'package:smart_solar_mobile/core/widgets/record_reference.dart';
import 'package:smart_solar_mobile/core/widgets/status_badge.dart';

class ProposalScreen extends StatefulWidget {
  final String? surveyId;
  const ProposalScreen({super.key, this.surveyId});

  @override
  State<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends State<ProposalScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  String? _error;
  EngineeringProposalModel? _proposal;
  int _refresh = 0;

  @override
  void initState() {
    super.initState();
    _loadProposal();
  }

  Future<void> _loadProposal() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      if (widget.surveyId != null && widget.surveyId!.isNotEmpty) {
        final data = await _apiService.getProposalForSurvey(widget.surveyId!);
        _proposal = data.isEmpty
            ? null
            : EngineeringProposalModel.fromJson(
                await _apiService.getProposal(data.first['id'].toString()));
      } else {
        final surveys = await _apiService.getSurveys();
        if (surveys.isNotEmpty) {
          final surveyId = surveys.first['id']?.toString();
          if (surveyId != null) {
            final data = await _apiService.getProposalForSurvey(surveyId);
            _proposal = data.isEmpty
                ? null
                : EngineeringProposalModel.fromJson(
                    await _apiService.getProposal(data.first['id'].toString()));
          }
        }
      }
    } catch (error) {
      _error = error.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refresh++;
        });
      }
    }
  }

  Future<void> _requestProposal() async {
    final surveyId = widget.surveyId;
    if (surveyId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _apiService.createProposal(surveyId);
      if (mounted) await _loadProposal();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
        backgroundColor: SolarColors.background,
        title: const Text('Project details',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              tooltip: 'Refresh project',
              onPressed: _loading ? null : _loadProposal,
              icon: const Icon(Icons.refresh_rounded,
                  color: SolarColors.primary)),
        ],
      ),
      body: _loading
          ? const _ProjectLoading()
          : _error != null
              ? _ProjectError(message: _error!, onRetry: _loadProposal)
              : _proposal == null
                  ? _EmptyProposal(
                      surveyId: widget.surveyId, onRequest: _requestProposal)
                  : _buildProposal(context),
    );
  }

  Widget _buildProposal(BuildContext context) {
    final proposal = _proposal!;
    final reference =
        proposal.id.length > 8 ? proposal.id.substring(0, 8) : proposal.id;
    final canRetry = ['RevisionRequested', 'Rejected', 'Failed']
        .contains(proposal.proposalStatus);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: RefreshIndicator(
          color: SolarColors.primary,
          onRefresh: _loadProposal,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
            children: [
              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SolarColors.primary, SolarColors.heroEnd],
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x28173E44),
                        blurRadius: 24,
                        offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                              color: SolarColors.lime,
                              borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.solar_power_rounded,
                              color: SolarColors.primary, size: 25),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SOLAR PROJECT',
                                    style: TextStyle(
                                        color: SolarColors.heroText,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1)),
                                const SizedBox(height: 3),
                                Text('Proposal #$reference',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                              ]),
                        ),
                        StatusBadge(
                            label: _friendlyStatus(proposal.proposalStatus),
                            color: const Color(0x3372B83E),
                            textColor: Colors.white),
                      ]),
                      const SizedBox(height: 22),
                      const Text('Estimated project cost',
                          style: TextStyle(
                              color: SolarColors.heroText, fontSize: 10)),
                      const SizedBox(height: 3),
                      Text(_formatLkr(proposal.estimatedCostLkr),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.7)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(11)),
                        child: const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Final pricing is confirmed after engineering and site review.',
                                style: TextStyle(
                                    color: SolarColors.heroText,
                                    fontSize: 9,
                                    height: 1.35)),
                          ),
                        ]),
                      ),
                    ]),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width < 520 ? 2 : 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.22,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ProjectSpec(
                      icon: Icons.bolt_rounded,
                      label: 'CAPACITY',
                      value: '${proposal.recommendedKw} kW',
                      color: SolarColors.limeDark),
                  _ProjectSpec(
                      icon: Icons.grid_view_rounded,
                      label: 'PANELS',
                      value: '${proposal.panelCount}',
                      color: SolarColors.primary),
                  _ProjectSpec(
                      icon: Icons.electrical_services_rounded,
                      label: 'INVERTER',
                      value: '${proposal.inverterSizeKw} kW',
                      color: SolarColors.primary),
                  _ProjectSpec(
                      icon: Icons.health_and_safety_outlined,
                      label: 'RISK',
                      value: _friendlyStatus(proposal.riskLevel),
                      color: _riskColor(proposal.riskLevel)),
                ],
              ),
              const SizedBox(height: 16),
              _ProjectSection(
                title: 'Engineering review',
                subtitle: 'Safety and compliance assessment',
                icon: Icons.engineering_outlined,
                child: Column(children: [
                  _ReviewRow(
                      label: 'Grid compliance',
                      value: _friendlyStatus(proposal.gridComplianceStatus),
                      icon: Icons.power_outlined),
                  const Divider(color: SolarColors.border, height: 23),
                  _ReviewRow(
                      label: 'Safety status',
                      value: _friendlyStatus(proposal.safetyStatus),
                      icon: Icons.shield_outlined),
                ]),
              ),
              if (proposal.recommendationSummary?.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                _ProjectSection(
                  title: 'Smart recommendation',
                  subtitle: 'System summary prepared for your property',
                  icon: Icons.auto_awesome_rounded,
                  child: Text(proposal.recommendationSummary!,
                      style: const TextStyle(
                          color: SolarColors.muted,
                          fontSize: 11,
                          height: 1.55)),
                ),
              ],
              const SizedBox(height: 14),
              EquipmentSummary(
                  key: ValueKey('${proposal.id}-$_refresh'),
                  proposalId: proposal.id),
              const SizedBox(height: 14),
              _ProjectSection(
                title: 'Project references',
                subtitle: 'Use these when contacting the project team',
                icon: Icons.tag_rounded,
                child: Column(children: [
                  RecordReference(
                      label: 'Proposal reference', value: proposal.id),
                  if (widget.surveyId != null)
                    RecordReference(
                        label: 'Survey reference', value: widget.surveyId!),
                ]),
              ),
              if (canRetry) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _requestProposal,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Request updated proposal'),
                  style: FilledButton.styleFrom(
                      backgroundColor: SolarColors.primary,
                      foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectSpec extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ProjectSpec(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: SolarColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SolarColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(label,
              style: const TextStyle(
                  color: SolarColors.muted,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8)),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: SolarColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ]),
      );
}

class _ProjectSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  const _ProjectSection(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: SolarColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: SolarColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10173E44), blurRadius: 18, offset: Offset(0, 7)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                  color: const Color(0x1207536A),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: SolarColors.primary, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: SolarColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            color: SolarColors.muted, fontSize: 9)),
                  ]),
            ),
          ]),
          const SizedBox(height: 16),
          child,
        ]),
      );
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReviewRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: SolarColors.muted, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: SolarColors.muted, fontSize: 11))),
        Text(value,
            style: const TextStyle(
                color: SolarColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w800)),
      ]);
}

class _ProjectLoading extends StatelessWidget {
  const _ProjectLoading();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: SolarColors.lime),
          SizedBox(height: 14),
          Text('Loading your project…',
              style: TextStyle(color: SolarColors.muted, fontSize: 11)),
        ]),
      );
}

class _ProjectError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ProjectError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => _CenteredState(
        icon: Icons.cloud_off_rounded,
        color: SolarColors.error,
        title: 'Project unavailable',
        message: message,
        action:
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
      );
}

class _EmptyProposal extends StatelessWidget {
  final String? surveyId;
  final VoidCallback onRequest;
  const _EmptyProposal({required this.surveyId, required this.onRequest});
  @override
  Widget build(BuildContext context) => _CenteredState(
        icon: Icons.description_outlined,
        color: SolarColors.primary,
        title: 'Proposal not created yet',
        message:
            'Your survey is ready. Request an engineering proposal to continue this solar project.',
        action: surveyId == null
            ? null
            : FilledButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Request proposal')),
      );
}

class _CenteredState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? action;
  const _CenteredState(
      {required this.icon,
      required this.color,
      required this.title,
      required this.message,
      this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: SolarColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SolarColors.border)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(19)),
                  child: Icon(icon, color: color, size: 31),
                ),
                const SizedBox(height: 15),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: SolarColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: SolarColors.muted, fontSize: 11, height: 1.5)),
                if (action != null) ...[
                  const SizedBox(height: 17),
                  action!,
                ],
              ]),
            ),
          ),
        ),
      );
}

String _friendlyStatus(String status) {
  if (status.isEmpty) return 'Pending';
  return status
      .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

Color _riskColor(String risk) {
  switch (risk.toUpperCase()) {
    case 'LOW':
      return SolarColors.success;
    case 'HIGH':
    case 'CRITICAL':
      return SolarColors.error;
    default:
      return SolarColors.warning;
  }
}

String _formatLkr(double value) {
  final digits = value.round().toString();
  final formatted =
      digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  return 'LKR $formatted';
}
