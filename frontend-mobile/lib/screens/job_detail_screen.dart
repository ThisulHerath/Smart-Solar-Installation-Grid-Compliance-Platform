import '../widgets/record_reference.dart';
import '../widgets/solar_field.dart';
import '../utils/validators.dart';
import 'dart:typed_data';
import '../theme/solar_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
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
  final _form = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  FieldJob? _job;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _successMessage;

  final Map<String, Uint8List> _photoBytes = {};
  final Map<String, String> _photoUrls = {};

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

  String _roofOrientation = 'Unknown';
  String _gridType = 'SinglePhase';
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
      if (!mounted) return;
      setState(() {
        _job = FieldJob.fromJson(data);
        for (final p in _job!.photos) {
          if (p.fileUrl.isNotEmpty) {
            _photoUrls[p.photoType] = p.fileUrl;
          }
        }
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
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Enable location services to record your arrival.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission is needed for check-in. Enable it in your device settings.');
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20)));
      await _api.checkInJob(
          widget.jobId, position.latitude, position.longitude);
      setState(() => _successMessage = 'GPS Check-in recorded successfully.');
      await _loadJobDetails();
    } catch (e) {
      setState(() => _error =
          'Check-in failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<bool> _handleSaveInspection() async {
    if (!_form.currentState!.validate()) return false;
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
        'phaseCount': _gridType == 'ThreePhase' ? 3 : 1,
        'mainBreakerRating': mainBreaker,
        'inverterLocationSuitable': _inverterLocationSuitable,
        'safetyNotes': _safetyNotesController.text.trim(),
        'technicianNotes': _technicianNotesController.text.trim(),
      });

      // Record Telemetry if entered
      if (_voltageController.text.isNotEmpty) {
        final v = double.tryParse(_voltageController.text.trim());
        if (v != null) {
          await _api.recordTelemetry(widget.jobId, 'GridVoltage', v, 'V');
        }
      }
      if (_frequencyController.text.isNotEmpty) {
        final f = double.tryParse(_frequencyController.text.trim());
        if (f != null) {
          await _api.recordTelemetry(widget.jobId, 'GridFrequency', f, 'Hz');
        }
      }
      if (_vocController.text.isNotEmpty) {
        final voc = double.tryParse(_vocController.text.trim());
        if (voc != null) {
          await _api.recordTelemetry(widget.jobId, 'Voc', voc, 'V');
        }
      }
      if (_iscController.text.isNotEmpty) {
        final isc = double.tryParse(_iscController.text.trim());
        if (isc != null) {
          await _api.recordTelemetry(widget.jobId, 'Isc', isc, 'A');
        }
      }

      setState(
          () => _successMessage = 'Site inspection draft & telemetry saved.');
      await _loadJobDetails();
      return true;
    } catch (e) {
      setState(() => _error =
          'Failed to save: ${e.toString().replaceAll('Exception: ', '')}');
      return false;
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _handleUploadPhoto(String photoType) async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (sheetContext) => SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Take a site photo'),
                    onTap: () =>
                        Navigator.pop(sheetContext, ImageSource.camera)),
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Choose a photo'),
                    onTap: () =>
                        Navigator.pop(sheetContext, ImageSource.gallery)),
              ])));
      if (source == null) return;
      final picked = await _picker.pickImage(
          source: source, maxWidth: 1920, imageQuality: 85);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes[photoType] = bytes;
        _saving = true;
      });

      final result =
          await _api.uploadInspectionPhoto(widget.jobId, picked, photoType);
      if (result is Map && result['fileUrl'] != null) {
        _photoUrls[photoType] = result['fileUrl'] as String;
      }
      setState(
          () => _successMessage = 'Photo ($photoType) uploaded successfully.');
      await _loadJobDetails();
    } catch (e) {
      setState(() => _error =
          'Photo upload failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _saving = false);
    }
  }

  bool _hasPhoto(String type) {
    if (_photoBytes.containsKey(type)) return true;
    if (_photoUrls.containsKey(type)) return true;
    return _job?.photos
            .any((p) => p.photoType.toLowerCase() == type.toLowerCase()) ??
        false;
  }

  Widget? _buildPreviewImage(String type) {
    if (_photoBytes.containsKey(type)) {
      return Image.memory(
        _photoBytes[type]!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    final url = _photoUrls[type] ??
        (_job?.photos
                    .where(
                        (p) => p.photoType.toLowerCase() == type.toLowerCase())
                    .isNotEmpty ==
                true
            ? _job!.photos
                .firstWhere(
                    (p) => p.photoType.toLowerCase() == type.toLowerCase())
                .fileUrl
            : null);
    if (url != null && url.isNotEmpty) {
      final fullUrl = url.startsWith('http') ? url : '${_api.baseUrl}$url';
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: SolarColors.muted),
        ),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: SolarColors.primary)),
      );
    }
    return null;
  }

  void _viewFullPhoto(String type) {
    final previewWidget = _buildPreviewImage(type);
    if (previewWidget == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.black,
                constraints: const BoxConstraints(maxHeight: 480),
                child: previewWidget,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$type Evidence Photo',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmitInspection() async {
    setState(() => _saving = true);
    try {
      if (!await _handleSaveInspection()) return;
      await _api.submitInspection(widget.jobId);
      setState(() => _successMessage =
          'Inspection submitted! Compliance analysis completed.');
      await _loadJobDetails();
    } catch (e) {
      setState(() => _error =
          'Submission failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: SolarColors.background,
        body: Center(
            child: CircularProgressIndicator(color: SolarColors.primary)),
      );
    }

    if (_job == null) {
      return Scaffold(
        backgroundColor: SolarColors.background,
        appBar: AppBar(
            backgroundColor: SolarColors.surface,
            title: const Text('Job Details')),
        body: const Center(
            child: Text('Job not found.',
                style: TextStyle(color: SolarColors.muted))),
      );
    }

    final job = _job!;

    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
        backgroundColor: SolarColors.surface,
        title: Text(
          job.propertyAddress,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: SolarColors.text),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status & Customer Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SolarColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SolarColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(job.customerName,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: SolarColors.text))),
                          StatusBadge(label: job.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      RecordReference(label: 'Job reference', value: job.id),
                      RecordReference(
                          label: 'Survey reference', value: job.solarSurveyId),
                      Text('Phone: ${job.customerPhone}',
                          style: const TextStyle(
                              color: SolarColors.muted, fontSize: 13)),
                      Text('Monthly electricity use: ${job.monthlyKwh} kWh',
                          style: const TextStyle(
                              color: SolarColors.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_successMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0x2010B981),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SolarColors.primary)),
                    child: Text(_successMessage!,
                        style: const TextStyle(
                            color: SolarColors.primary, fontSize: 13)),
                  ),

                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0x20EF4444),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SolarColors.error)),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: SolarColors.error, fontSize: 13)),
                  ),

                // Step 1: GPS Check-In
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SolarColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SolarColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. GPS Check-in (Site Arrival)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: SolarColors.info)),
                      const SizedBox(height: 8),
                      const Text(
                          'Confirm physical presence at survey site using device GPS coordinates.',
                          style: TextStyle(
                              fontSize: 12, color: SolarColors.muted)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _handleGpsCheckIn,
                        icon: const Icon(Icons.location_on, size: 16),
                        label: const Text('Record GPS Check-in'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: SolarColors.info,
                            foregroundColor: SolarColors.onPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Step 2: Site & Electrical Measurements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SolarColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SolarColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2. Roof & Electrical Inspection',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: SolarColors.primary)),
                      const SizedBox(height: 12),
                      SolarField(
                        controller: _roofAreaController,
                        inputFormatters: [solarDecimalFormatter],
                        validator: (v) => Validators.number(v,
                            min: 0.01, max: 100000, optional: true),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: SolarColors.text),
                        decoration: const InputDecoration(
                            labelText: 'Measured Roof Area (m²)',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      SolarField(
                        controller: _roofTiltController,
                        inputFormatters: [solarDecimalFormatter],
                        validator: (v) => Validators.number(v,
                            min: 0, max: 90, optional: true),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: SolarColors.text),
                        decoration: const InputDecoration(
                            labelText: 'Roof Tilt Angle (degrees)',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      SolarField(
                        controller: _mainBreakerController,
                        inputFormatters: [solarDecimalFormatter],
                        validator: (v) => Validators.number(v,
                            min: 0.01, max: 100000, optional: true),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: SolarColors.text),
                        decoration: const InputDecoration(
                            labelText: 'Main Breaker Rating (Amps)',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          initialValue: _gridType,
                          decoration: const InputDecoration(
                              labelText: 'Observed grid connection'),
                          items: const [
                            DropdownMenuItem(
                                value: 'SinglePhase',
                                child: Text('Single phase')),
                            DropdownMenuItem(
                                value: 'ThreePhase', child: Text('Three phase'))
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _gridType = value);
                            }
                          }),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          initialValue: _roofOrientation,
                          decoration: const InputDecoration(
                              labelText: 'Roof orientation'),
                          items: [
                            'Unknown',
                            'North',
                            'South',
                            'East',
                            'West',
                            'NorthEast',
                            'NorthWest',
                            'SouthEast',
                            'SouthWest'
                          ]
                              .map((value) => DropdownMenuItem(
                                  value: value, child: Text(value)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _roofOrientation = value);
                            }
                          }),
                      SwitchListTile(
                        title: const Text('Inverter Location Suitable',
                            style: TextStyle(
                                color: SolarColors.text, fontSize: 14)),
                        subtitle: const Text(
                            'Adequate airflow, sheltered, fire safety compliant',
                            style: TextStyle(
                                color: SolarColors.muted, fontSize: 12)),
                        value: _inverterLocationSuitable,
                        activeThumbColor: SolarColors.primary,
                        onChanged: (val) =>
                            setState(() => _inverterLocationSuitable = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Step 3: Electrical Telemetry
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SolarColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SolarColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. Measured electrical readings',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: SolarColors.warning)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SolarField(
                              controller: _voltageController,
                              inputFormatters: [solarDecimalFormatter],
                              validator: (v) => Validators.number(v,
                                  min: 0.01, max: 100000, optional: true),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(color: SolarColors.text),
                              decoration: const InputDecoration(
                                  labelText: 'Grid Voltage (V)',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SolarField(
                              controller: _frequencyController,
                              inputFormatters: [solarDecimalFormatter],
                              validator: (v) => Validators.number(v,
                                  min: 0.01, max: 100000, optional: true),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(color: SolarColors.text),
                              decoration: const InputDecoration(
                                  labelText: 'Grid Freq (Hz)',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SolarField(
                              controller: _vocController,
                              inputFormatters: [solarDecimalFormatter],
                              validator: (v) => Validators.number(v,
                                  min: 0.01, max: 100000, optional: true),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(color: SolarColors.text),
                              decoration: const InputDecoration(
                                  labelText: 'Voc (V)',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SolarField(
                              controller: _iscController,
                              inputFormatters: [solarDecimalFormatter],
                              validator: (v) => Validators.number(v,
                                  min: 0.01, max: 100000, optional: true),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(color: SolarColors.text),
                              decoration: const InputDecoration(
                                  labelText: 'Isc (A)',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Step 4: Photo Capture & Previews
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SolarColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SolarColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '4. Site Evidence Photographs',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: SolarColors.text),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x18287247),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0x33287247)),
                            ),
                            child: Text(
                              '${[
                                'Roof',
                                'Meter',
                                'ElectricalPanel',
                                'InverterLocation'
                              ].where(_hasPhoto).length}/4 Attached',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: SolarColors.success),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons with completion ticks
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Roof',
                          'Meter',
                          'ElectricalPanel',
                          'InverterLocation'
                        ].map((type) {
                          final uploaded = _hasPhoto(type);
                          return OutlinedButton.icon(
                            onPressed:
                                _saving ? null : () => _handleUploadPhoto(type),
                            icon: Icon(
                              uploaded
                                  ? Icons.check_circle_rounded
                                  : Icons.camera_alt,
                              size: 15,
                              color: uploaded
                                  ? SolarColors.success
                                  : SolarColors.muted,
                            ),
                            label: Text(
                              uploaded ? '$type ✓' : type,
                              style: TextStyle(
                                color: uploaded
                                    ? SolarColors.success
                                    : SolarColors.text,
                                fontWeight: uploaded
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: uploaded
                                  ? const Color(0x14287247)
                                  : Colors.transparent,
                              side: BorderSide(
                                color: uploaded
                                    ? SolarColors.success
                                    : SolarColors.border,
                                width: uploaded ? 1.5 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          );
                        }).toList(),
                      ),

                      // Previews section
                      if ([
                        'Roof',
                        'Meter',
                        'ElectricalPanel',
                        'InverterLocation'
                      ].any(_hasPhoto)) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: SolarColors.border),
                        const SizedBox(height: 12),
                        const Text(
                          'Attached Photo Previews',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: SolarColors.text),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.15,
                          children: [
                            'Roof',
                            'Meter',
                            'ElectricalPanel',
                            'InverterLocation'
                          ].map((type) {
                            final hasPhoto = _hasPhoto(type);
                            final previewWidget = _buildPreviewImage(type);
                            return Container(
                              decoration: BoxDecoration(
                                color: SolarColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasPhoto
                                      ? SolarColors.success
                                          .withValues(alpha: 0.4)
                                      : SolarColors.border,
                                ),
                              ),
                              child: hasPhoto && previewWidget != null
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          child: GestureDetector(
                                            onTap: () => _viewFullPhoto(type),
                                            child: previewWidget,
                                          ),
                                        ),
                                        // Gradient overlay & badges
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.7),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomLeft: Radius.circular(11),
                                                bottomRight:
                                                    Radius.circular(11),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    type,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Icon(Icons.check_circle,
                                                    color: Color(0xFFD4EF83),
                                                    size: 14),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Retake button
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: InkWell(
                                            onTap: _saving
                                                ? null
                                                : () =>
                                                    _handleUploadPhoto(type),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.65),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.edit,
                                                  color: Colors.white,
                                                  size: 13),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : InkWell(
                                      onTap: _saving
                                          ? null
                                          : () => _handleUploadPhoto(type),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                                Icons.add_a_photo_outlined,
                                                color: SolarColors.muted,
                                                size: 22),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Add $type',
                                              style: const TextStyle(
                                                  color: SolarColors.muted,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Buttons
                ElevatedButton(
                  onPressed: _saving ? null : _handleSaveInspection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SolarColors.surfaceSoft,
                    foregroundColor: SolarColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Inspection Draft'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _saving ? null : _handleSubmitInspection,
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                      'Submit Inspection for Grid Compliance Evaluation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SolarColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Compliance Assessment View
                if (job.compliance != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: job.compliance!.gridCompliant
                          ? const Color(0x1510B981)
                          : const Color(0x15EF4444),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: job.compliance!.gridCompliant
                              ? SolarColors.primary
                              : SolarColors.error),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grid Compliance Assessment',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: SolarColors.text)),
                            StatusBadge(
                                label: job.compliance!.complianceStatus,
                                color: job.compliance!.gridCompliant
                                    ? SolarColors.primary
                                    : SolarColors.error),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Risk Level: ${job.compliance!.riskLevel}',
                            style: const TextStyle(
                                color: SolarColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        if (job.compliance!.complianceNotes != null) ...[
                          const SizedBox(height: 6),
                          Text(job.compliance!.complianceNotes!,
                              style: const TextStyle(
                                  color: SolarColors.muted,
                                  fontSize: 12,
                                  height: 1.4)),
                        ],
                      ],
                    ),
                  ),
              ],
            )),
      ),
    );
  }
}
