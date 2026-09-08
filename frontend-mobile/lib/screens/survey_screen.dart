import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/solar_survey.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _usageController = TextEditingController();
  final _roofController = TextEditingController();
  final _addressController = TextEditingController();
  final _api = ApiService();

  List<SolarSurvey> _surveys = [];
  String _gridType = 'SinglePhase';
  String? _error;
  bool _loading = false;
  bool _fetching = true;
  XFile? _attachedImage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _usageController.dispose();
    _roofController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _hasActiveProcessingSurvey()) {
        _loadSurveys(isSilent: true);
      }
    });
  }

  bool _hasActiveProcessingSurvey() {
    return _surveys.any((s) =>
        s.surveyStatus.toUpperCase() == 'PROCESSING' ||
        s.surveyStatus.toUpperCase() == 'SUBMITTED');
  }

  Future<void> _loadSurveys({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _fetching = true);
    try {
      final data = await _api.getSurveys();
      if (mounted) {
        setState(() {
          _surveys = data.map((e) => SolarSurvey.fromJson(Map<String, dynamic>.from(e))).toList();
          _error = null;
        });
      }
    } catch (e) {
      if (!isSilent && mounted) {
        setState(() => _error = 'Failed to load surveys: ${e.toString()}');
      }
    } finally {
      if (!isSilent && mounted) {
        setState(() => _fetching = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() => _attachedImage = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image picker error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createAndSubmitSurvey() async {
    final usage = double.tryParse(_usageController.text.trim());
    final roof = double.tryParse(_roofController.text.trim());
    final address = _addressController.text.trim();

    if (usage == null || usage <= 0) {
      setState(() => _error = 'Please enter a valid positive monthly usage (kWh).');
      return;
    }
    if (roof == null || roof <= 0) {
      setState(() => _error = 'Please enter a valid positive roof area (m²).');
      return;
    }
    if (address.isEmpty) {
      setState(() => _error = 'Please enter a property address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Step 1: Create Draft Survey
      final created = await _api.createSurvey(
        monthlyKwh: usage,
        roofAreaSqm: roof,
        gridType: _gridType,
        propertyAddress: address,
      );
      final surveyId = created['id'] as String;

      // Step 2: Optional Image Upload (Draft survey only)
      if (_attachedImage != null) {
        await _api.uploadSurveyImage(surveyId, _attachedImage!, 'RoofSite');
      }

      // Step 3: Explicitly Submit Survey for AI Processing
      final submitted = await _api.submitSurvey(surveyId);

      // Reset Form State
      _attachedImage = null;
      _usageController.clear();
      _roofController.clear();
      _addressController.clear();

      await _loadSurveys();

      if (mounted) {
        final status = submitted['surveyStatus'] ?? 'Processing';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Survey submitted successfully! Current status: $status'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Submission failed: ${e.toString().replaceAll('Exception:', '').trim()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ANALYSISCOMPLETE':
      case 'ANALYSIS_COMPLETE':
      case 'COMPLETED':
        return const Color(0xFF10B981);
      case 'PROCESSING':
      case 'SUBMITTED':
        return const Color(0xFFF59E0B);
      case 'FAILED':
        return Colors.redAccent;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111726),
        title: const Text('Homeowner Solar Assessment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => _loadSurveys(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create New Survey Card
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
                      Icon(Icons.add_location_alt, color: Color(0xFF10B981), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Create & Submit Solar Survey',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _usageController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Monthly Consumption (kWh)',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.bolt, color: Color(0xFFF59E0B)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF10B981))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _roofController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Roof Surface Area (m²)',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.square_foot, color: Color(0xFF38BDF8)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF10B981))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: _gridType,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Grid Connection Type',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.power, color: Color(0xFF10B981)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF10B981))),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SinglePhase', child: Text('Single Phase (230V)')),
                      DropdownMenuItem(value: 'ThreePhase', child: Text('Three Phase (400V)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _gridType = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Property Address',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.home, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF10B981))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image picker button
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _pickImage,
                    icon: Icon(_attachedImage == null ? Icons.camera_alt : Icons.check_circle, color: const Color(0xFF38BDF8)),
                    label: Text(
                      _attachedImage == null ? 'Attach Site Photo (Optional)' : 'Photo Attached (${_attachedImage!.name})',
                      style: const TextStyle(color: Color(0xFF38BDF8)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x3338BDF8)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _createAndSubmitSurvey,
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: Text(_loading ? 'Submitting to AI Agent...' : 'Submit Survey for AI Sizing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Survey History List
            const Text(
              'Your Submitted Surveys & AI Results',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            if (_fetching && _surveys.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_surveys.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111726),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No surveys submitted yet.', style: TextStyle(color: Color(0xFF94A3B8))),
              )
            else
              ..._surveys.map((survey) => _buildSurveyItemCard(survey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyItemCard(SolarSurvey survey) {
    final statusColor = _getStatusColor(survey.surveyStatus);
    final hasFailed = survey.surveyStatus.toUpperCase() == 'FAILED' || survey.errorMessage != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111726),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  survey.propertyAddress.isNotEmpty ? survey.propertyAddress : 'Solar Survey',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  survey.surveyStatus,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            '${survey.monthlyKwh} kWh/mo · ${survey.roofAreaSqm} m² · ${survey.gridType}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),

          // Sizing Recommendation Display
          if (survey.recommendedKw != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x1A10B981),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x4010B981)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wb_sunny, color: Color(0xFF10B981), size: 16),
                      SizedBox(width: 6),
                      Text('Recommended System Size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Array: ${survey.recommendedKw} kW', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Panels: ${survey.panelCount ?? "-"} x 400W', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Inverter: ${survey.inverterKw} kW', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (survey.isValid != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Deterministic Validation: ${survey.isValid == true ? "PASSED" : "FAILED"}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: survey.isValid == true ? const Color(0xFF10B981) : Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (hasFailed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      survey.errorMessage ?? 'Workflow execution encountered an error. No fake recommendations were emitted.',
                      style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
