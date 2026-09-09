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
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await _api.getTechnicianJobs(
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      );
      setState(() {
        _jobs = raw.map((item) => FieldJob.fromJson(Map<String, dynamic>.from(item))).toList();
        _loading = false;
      });
    } catch (e) {
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
        return const Color(0xFF10B981);
      case 'COMPLIANCEPROCESSING':
      case 'COMPLIANCE_PROCESSING':
      case 'INPROGRESS':
      case 'IN_PROGRESS':
        return const Color(0xFFF59E0B);
      case 'SUBMITTED':
        return const Color(0xFF06B6D4);
      case 'FAILED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF60A5FA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111726),
        title: const Text(
          'Field Technician Jobs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadJobs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['ALL', 'Assigned', 'InProgress', 'Submitted', 'ComplianceComplete'].map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      status == 'ALL' ? 'All Jobs' : status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedStatus = status);
                      _loadJobs();
                    },
                    backgroundColor: const Color(0xFF111726),
                    selectedColor: const Color(0xFF10B981),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF10B981) : const Color(0x1AFFFFFF),
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadJobs, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _jobs.isEmpty
                        ? const Center(
                            child: Text(
                              'No assigned jobs found.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadJobs,
                            color: const Color(0xFF10B981),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _jobs.length,
                              itemBuilder: (context, idx) {
                                final job = _jobs[idx];
                                return Card(
                                  color: const Color(0xFF111726),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(color: Color(0x1AFFFFFF)),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => JobDetailScreen(jobId: job.id),
                                        ),
                                      );
                                      _loadJobs();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  job.customerName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              StatusBadge(
                                                label: job.status,
                                                color: _getStatusColor(job.status),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF06B6D4)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  job.propertyAddress,
                                                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Priority: ${job.priority}',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                                              ),
                                              Text(
                                                '${job.monthlyKwh.toStringAsFixed(0)} kWh/mo',
                                                style: const TextStyle(fontSize: 12, color: Colors.white70),
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
