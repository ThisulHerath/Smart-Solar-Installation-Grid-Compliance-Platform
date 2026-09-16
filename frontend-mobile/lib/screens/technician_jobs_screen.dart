import '../widgets/solar_search.dart';
import '../widgets/record_reference.dart';
import '../theme/solar_theme.dart';
import 'package:flutter/material.dart';
import '../models/field_job.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';
import 'job_detail_screen.dart';

class TechnicianJobsScreen extends StatefulWidget {
  const TechnicianJobsScreen({super.key});

  @override
  State<TechnicianJobsScreen> createState() => _TechnicianJobsScreenState();
}

class _TechnicianJobsScreenState extends State<TechnicianJobsScreen> {
  final ApiService _api = ApiService();
  List<FieldJob> _jobs = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int _request = 0;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await _api.getTechnicianJobs(
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _jobs = raw
            .map((item) => FieldJob.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLIANCECOMPLETE':
      case 'COMPLIANCE_COMPLETE':
        return SolarColors.primary;
      case 'COMPLIANCEPROCESSING':
      case 'COMPLIANCE_PROCESSING':
      case 'INPROGRESS':
      case 'IN_PROGRESS':
        return SolarColors.warning;
      case 'SUBMITTED':
        return SolarColors.info;
      case 'FAILED':
        return SolarColors.error;
      default:
        return SolarColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleJobs = _jobs
        .where((j) =>
            '${j.customerName} ${j.propertyAddress} ${j.id} ${j.solarSurveyId}'
                .toLowerCase()
                .contains(_search))
        .toList();
    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
        backgroundColor: SolarColors.surface,
        title: const Text(
          'Field Technician Jobs',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: SolarColors.text),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: SolarColors.muted),
            onPressed: _loadJobs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SolarSearch(
                  label: 'Search site jobs',
                  onChanged: (value) =>
                      setState(() => _search = value.toLowerCase()))),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                'ALL',
                'Assigned',
                'InProgress',
                'Submitted',
                'ComplianceComplete'
              ].map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      status == 'ALL'
                          ? 'All jobs'
                          : status.replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
                              (m) => '${m[1]} ${m[2]}'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected ? SolarColors.text : SolarColors.muted,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedStatus = status);
                      _loadJobs();
                    },
                    backgroundColor: SolarColors.surface,
                    selectedColor: SolarColors.lime,
                    checkmarkColor: SolarColors.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? SolarColors.primary
                            : SolarColors.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: SolarColors.primary))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: SolarColors.error, size: 40),
                              const SizedBox(height: 12),
                              Text(_error!,
                                  style:
                                      const TextStyle(color: SolarColors.muted),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                  onPressed: _loadJobs,
                                  child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : visibleJobs.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching jobs. Try another name or reference, or select all jobs.',
                              style: TextStyle(
                                  color: SolarColors.muted, fontSize: 14),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadJobs,
                            color: SolarColors.primary,
                            child: ListView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.all(16),
                              itemCount: visibleJobs.length,
                              itemBuilder: (context, idx) {
                                final job = visibleJobs[idx];
                                return Card(
                                  color: SolarColors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                        color: SolarColors.border),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              JobDetailScreen(jobId: job.id),
                                        ),
                                      );
                                      _loadJobs();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  job.customerName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: SolarColors.text,
                                                  ),
                                                ),
                                              ),
                                              StatusBadge(
                                                label: job.status,
                                                color:
                                                    _getStatusColor(job.status),
                                              ),
                                            ],
                                          ),
                                          RecordReference(
                                              label: 'Job reference',
                                              value: job.id),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.location_on_outlined,
                                                  size: 14,
                                                  color: SolarColors.info),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  job.propertyAddress,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: SolarColors.muted),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Priority: ${job.priority}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: SolarColors.warning,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              Text(
                                                '${job.monthlyKwh.toStringAsFixed(0)} kWh/mo',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: SolarColors.muted),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
