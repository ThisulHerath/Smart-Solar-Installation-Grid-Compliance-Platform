import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/field_job.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  FieldJob? _job;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _successMessage;

  // Controllers for site inspection
  final _roofAreaController = TextEditingController();
  final _roofTiltController = TextEditingController();
  final _mainBreakerController = TextEditingController();
  final _safetyNotesController = TextEditingController();
  final _technicianNotesController = TextEditingController();

  // Telemetry controllers
  final _voltageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _vocController = TextEditingController();
  final _iscController = TextEditingController();

  final String _roofOrientation = 'South';
  final String _gridType = 'SinglePhase';
  final int _phaseCount = 1;
  bool _inverterLocationSuitable = true;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  @override
  void dispose() {
    _roofAreaController.dispose();
    _roofTiltController.dispose();
    _mainBreakerController.dispose();
    _safetyNotesController.dispose();
    _technicianNotesController.dispose();
    _voltageController.dispose();
    _frequencyController.dispose();
    _vocController.dispose();
    _iscController.dispose();
    super.dispose();
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getTechnicianJob(widget.jobId);
      setState(() {
        _job = FieldJob.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _handleGpsCheckIn() async {
    setState(() => _saving = true);
    try {
      // Simulate/submit GPS check-in (e.g. 6.9271, 79.8612 for Colombo site)
      final lat = _job?.latitude ?? 6.9271;
      final lng = _job?.longitude ?? 79.8612;

      await _api.checkInJob(widget.jobId, lat, lng);
      setState(() => _successMessage = 'GPS Check-in recorded successfully.');
      await _loadJobDetails();
    } catch (e) {
      setState(() => _error = 'Check-in failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _handleSaveInspection() async {
    setState(() => _saving = true);
    try {
      final roofArea = double.tryParse(_roofAreaController.text.trim());
      final roofTilt = double.tryParse(_roofTiltController.text.trim());
      final mainBreaker = double.tryParse(_mainBreakerController.text.trim());

      await _api.saveInspectionDraft(widget.jobId, {
        'roofAreaMeasuredSqm': roofArea,
        'roofOrientation': _roofOrientation,
        'roofTilt': roofTilt,
        'gridTypeObserved': _gridType,
        'phaseCount': _phaseCount,
        'mainBreakerRating': mainBreaker,
        'inverterLocationSuitable': _inverterLocationSuitable,
        'safetyNotes': _safetyNotesController.text.trim(),
        'technicianNotes': _technicianNotesController.text.trim(),
      });

      // Record Telemetry if entered
      if (_voltageController.text.isNotEmpty) {
        final v = double.tryParse(_voltageController.text.trim());
        if (v != null) await _api.recordTelemetry(widget.jobId, 'GridVoltage', v, 'V');
      }
      if (_frequencyController.text.isNotEmpty) {
        final f = double.tryParse(_frequencyController.text.trim());
        if (f != null) await _api.recordTelemetry(widget.jobId, 'GridFrequency', f, 'Hz');
      }
      if (_vocController.text.isNotEmpty) {
        final voc = double.tryParse(_vocController.text.trim());
        if (voc != null) await _api.recordTelemetry(widget.jobId, 'Voc', voc, 'V');
      }
      if (_iscController.text.isNotEmpty) {
        final isc = double.tryParse(_iscController.text.trim());
        if (isc != null) await _api.recordTelemetry(widget.jobId, 'Isc', isc, 'A');
      }

      setState(() => _successMessage = 'Site inspection draft & telemetry saved.');
      await _loadJobDetails();
    } catch (e) {
      setState(() => _error = 'Failed to save: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _handleUploadPhoto(String photoType) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _saving = true);
      await _api.uploadInspectionPhoto(widget.jobId, picked, photoType);
      setState(() => _successMessage = 'Photo ($photoType) uploaded successfully.');
      await _loadJobDetails();
    } catch (e) {
      setState(() => _error = 'Photo upload failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _handleSubmitInspection() async {
    setState(() => _saving = true);
    try {
      await _handleSaveInspection();
      await _api.submitInspection(widget.jobId);
      setState(() => _successMessage = 'Inspection submitted! Compliance analysis completed.');
      await _loadJobDetails();
    } catch (e) {
      setState(() => _error = 'Submission failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0D14),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    if (_job == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0D14),
        appBar: AppBar(backgroundColor: const Color(0xFF111726), title: const Text('Job Details')),
        body: const Center(child: Text('Job not found.', style: TextStyle(color: Colors.white70))),
      );
    }

    final job = _job!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111726),
        title: Text(
          job.propertyAddress,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status & Customer Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111726),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(job.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      StatusBadge(label: job.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Phone: ${job.customerPhone}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  Text('System Size: ${job.monthlyKwh} kWh/mo', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0x2010B981), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF10B981))),
                child: Text(_successMessage!, style: const TextStyle(color: Color(0xFF10B981), fontSize: 13)),
              ),

            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0x20EF4444), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFEF4444))),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
              ),

            // Step 1: GPS Check-In
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111726),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. GPS Check-in (Site Arrival)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF06B6D4))),
                  const SizedBox(height: 8),
                  const Text('Confirm physical presence at survey site using device GPS coordinates.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _handleGpsCheckIn,
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text('Record GPS Check-in'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 2: Site & Electrical Measurements
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111726),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. Roof & Electrical Inspection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _roofAreaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Measured Roof Area (m²)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _roofTiltController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Roof Tilt Angle (degrees)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _mainBreakerController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Main Breaker Rating (Amps)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Inverter Location Suitable', style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text('Adequate airflow, sheltered, fire safety compliant', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    value: _inverterLocationSuitable,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _inverterLocationSuitable = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 3: Electrical Telemetry
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111726),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('3. Real-Time Electrical Telemetry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFF59E0B))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voltageController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Grid Voltage (V)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _frequencyController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Grid Freq (Hz)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _vocController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Voc (V)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _iscController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Isc (A)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 4: Photo Capture
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111726),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('4. Site Evidence Photographs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Roof', 'Meter', 'ElectricalPanel', 'InverterLocation'].map((type) {
                      return OutlinedButton.icon(
                        onPressed: _saving ? null : () => _handleUploadPhoto(type),
                        icon: const Icon(Icons.camera_alt, size: 14),
                        label: Text(type),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Buttons
            ElevatedButton(
              onPressed: _saving ? null : _handleSaveInspection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Inspection Draft'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _saving ? null : _handleSubmitInspection,
              icon: const Icon(Icons.check_circle),
              label: const Text('Submit Inspection for Grid Compliance Evaluation'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Compliance Assessment View
            if (job.compliance != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: job.compliance!.gridCompliant ? const Color(0x1510B981) : const Color(0x15EF4444),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: job.compliance!.gridCompliant ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grid Compliance Assessment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        StatusBadge(label: job.compliance!.complianceStatus, color: job.compliance!.gridCompliant ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Risk Level: ${job.compliance!.riskLevel}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.bold)),
                    if (job.compliance!.complianceNotes != null) ...[
                      const SizedBox(height: 6),
                      Text(job.compliance!.complianceNotes!, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
