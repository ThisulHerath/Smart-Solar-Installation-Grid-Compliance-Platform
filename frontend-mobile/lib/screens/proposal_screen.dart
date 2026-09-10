import 'package:flutter/material.dart';
import '../models/proposal.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProposal();
  }

  Future<void> _loadProposal() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.surveyId != null && widget.surveyId!.isNotEmpty) {
        final data = await _apiService.getProposalForSurvey(widget.surveyId!);
        if (data != null) {
          _proposal = EngineeringProposalModel.fromJson(data);
        } else {
          _proposal = null;
        }
      } else {
        // Fetch survey list first to check latest survey proposal
        final surveys = await _apiService.getSurveys();
        if (surveys.isNotEmpty) {
          final firstSurveyId = surveys.first['id']?.toString();
          if (firstSurveyId != null) {
            final data = await _apiService.getProposalForSurvey(firstSurveyId);
            if (data != null) {
              _proposal = EngineeringProposalModel.fromJson(data);
            }
          }
        }
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111726),
        title: const Text(
          'Engineering Proposal Status',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadProposal,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProposal,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _proposal == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.description_outlined, color: Color(0xFF94A3B8), size: 56),
                          const SizedBox(height: 16),
                          const Text(
                            'No Engineering Proposal Found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Complete your solar survey and request an engineering assessment to generate a formal proposal.',
                              style: TextStyle(color: Color(0xFF94A3B8), height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Status Header Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111726),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x1AFFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'PROPOSAL #${_proposal!.id.substring(0, _proposal!.id.length > 8 ? 8 : _proposal!.id.length)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF94A3B8),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    StatusBadge(label: _proposal!.proposalStatus),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'LKR ${_proposal!.estimatedCostLkr.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Estimated System Cost',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Technical Specs Grid
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111726),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x1AFFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Technical Specifications',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _buildSpecTile('Capacity', '${_proposal!.recommendedKw} kW', Icons.bolt),
                                    _buildSpecTile('Panels', '${_proposal!.panelCount} Units', Icons.grid_view),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildSpecTile('Inverter', '${_proposal!.inverterSizeKw} kW', Icons.electrical_services),
                                    _buildSpecTile('Risk Level', _proposal!.riskLevel, Icons.shield),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // AI Recommendation Summary
                          if (_proposal!.recommendationSummary != null && _proposal!.recommendationSummary!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111726),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0x1AFFFFFF)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.smart_toy, color: Color(0xFF8B5CF6), size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'AI Safety & Engineering Analysis',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _proposal!.recommendationSummary!,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Homeowner Information Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x3338BDF8)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This engineering proposal is under review by certified Senior Grid Engineers. Final approval status will automatically update here.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSpecTile(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0D14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x0FFFFFFF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
