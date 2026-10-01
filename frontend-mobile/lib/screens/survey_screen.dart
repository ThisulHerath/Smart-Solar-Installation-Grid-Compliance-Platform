import '../widgets/solar_search.dart';
import '../widgets/record_reference.dart';
import '../widgets/solar_field.dart';
import '../widgets/location_picker.dart';
import '../utils/validators.dart';
import '../theme/solar_theme.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/solar_survey.dart';
import 'proposal_screen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _form = GlobalKey<FormState>();
  final _usageController = TextEditingController();
  final _roofController = TextEditingController();
  final _addressController = TextEditingController();
  final _api = ApiService();

  List<SolarSurvey> _surveys = [];
  String _search = '';
  String _statusFilter = '';
  String _gridType = 'SinglePhase';
  String? _error;
  bool _loading = false;
  bool _fetching = true;
  XFile? _attachedImage;
  PropertyLocation? _propertyLocation;
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
          _surveys = data
              .map((e) => SolarSurvey.fromJson(Map<String, dynamic>.from(e)))
              .toList();
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
    if (!_form.currentState!.validate()) return;
    final usage = double.tryParse(_usageController.text.trim());
    final roof = double.tryParse(_roofController.text.trim());
    final address = _addressController.text.trim();

    if (usage == null || usage <= 0) {
      setState(
          () => _error = 'Please enter a valid positive monthly usage (kWh).');
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
        latitude: _propertyLocation?.latitude,
        longitude: _propertyLocation?.longitude,
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
      _propertyLocation = null;

      await _loadSurveys();

      if (mounted) {
        final status = submitted['surveyStatus'] ?? 'Processing';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Survey submitted successfully! Current status: $status'),
            backgroundColor: SolarColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Submission failed: ${e.toString().replaceAll('Exception:', '').trim()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: SolarColors.error,
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
        return SolarColors.primary;
      case 'PROCESSING':
      case 'SUBMITTED':
        return SolarColors.warning;
      case 'FAILED':
        return SolarColors.error;
      default:
        return SolarColors.muted;
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      prefixIcon: Icon(icon, color: SolarColors.primary, size: 20),
      suffixText: suffix,
      suffixStyle: const TextStyle(
          color: SolarColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: SolarColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    );
  }

  Widget _fieldLabel(String label, String helper) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 7),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  color: SolarColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(helper,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: SolarColors.muted, fontSize: 10))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
        backgroundColor: SolarColors.surface,
        title: const Text('Solar projects',
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: SolarColors.text)),
        actions: [
          IconButton(
            tooltip: 'Refresh projects',
            icon: const Icon(Icons.refresh_rounded, color: SolarColors.primary),
            onPressed: () => _loadSurveys(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
        child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: SolarColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: SolarColors.border),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x12173E44),
                          blurRadius: 24,
                          offset: Offset(0, 9)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(21)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              SolarColors.primary,
                              SolarColors.heroEnd,
                            ],
                          ),
                        ),
                        child: const Row(children: [
                          CircleAvatar(
                            radius: 23,
                            backgroundColor: SolarColors.lime,
                            child: Icon(Icons.roofing_rounded,
                                color: SolarColors.primary, size: 24),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('New solar assessment',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(height: 4),
                                  Text(
                                      'Tell us about your home to calculate the right solar system.',
                                      style: TextStyle(
                                          color: SolarColors.heroText,
                                          fontSize: 11,
                                          height: 1.35)),
                                ]),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _fieldLabel('Monthly electricity use',
                                'Check a recent electricity bill'),
                            SolarField(
                              controller: _usageController,
                              inputFormatters: [solarDecimalFormatter],
                              validator: (v) => Validators.number(v, min: 0.01),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(color: SolarColors.text),
                              decoration: _fieldDecoration(
                                  hint: 'e.g. 450',
                                  icon: Icons.bolt_rounded,
                                  suffix: 'kWh / month'),
                            ),
                            const SizedBox(height: 5),
                            _fieldLabel('Usable roof area',
                                'Approximate measurement is enough'),
                            SolarField(
                              controller: _roofController,
                              inputFormatters: [solarDecimalFormatter],
                              validator: (v) => Validators.number(v, min: 1),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(color: SolarColors.text),
                              decoration: _fieldDecoration(
                                  hint: 'e.g. 80',
                                  icon: Icons.square_foot_rounded,
                                  suffix: 'm²'),
                            ),
                            const SizedBox(height: 5),
                            _fieldLabel('Grid connection',
                                'Select the supply available at your home'),
                            DropdownButtonFormField<String>(
                              initialValue: _gridType,
                              dropdownColor: SolarColors.surface,
                              icon: const Icon(Icons.expand_more_rounded),
                              style: const TextStyle(
                                  color: SolarColors.text, fontSize: 13),
                              decoration: _fieldDecoration(
                                  hint: 'Select connection type',
                                  icon: Icons.electrical_services_rounded),
                              items: const [
                                DropdownMenuItem(
                                    value: 'SinglePhase',
                                    child: Text('Single Phase (230V)')),
                                DropdownMenuItem(
                                    value: 'ThreePhase',
                                    child: Text('Three Phase (400V)')),
                              ],
                              onChanged: _loading
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setState(() => _gridType = val);
                                      }
                                    },
                            ),
                            const SizedBox(height: 17),
                            _fieldLabel('Property address',
                                'The site where solar will be installed'),
                            SolarField(
                              controller: _addressController,
                              validator: Validators.required,
                              maxLength: 500,
                              style: const TextStyle(color: SolarColors.text),
                              decoration: _fieldDecoration(
                                  hint: 'House number, street and city',
                                  icon: Icons.location_on_outlined),
                            ),
                            LocationPicker(
                              addressController: _addressController,
                              value: _propertyLocation,
                              disabled: _loading,
                              onChanged: (location) =>
                                  setState(() => _propertyLocation = location),
                            ),
                            Material(
                              color: const Color(0x0F07536A),
                              borderRadius: BorderRadius.circular(13),
                              child: InkWell(
                                onTap: _loading ? null : _pickImage,
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(
                                          color: const Color(0x3372B83E))),
                                  child: Row(children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                          color: SolarColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(11)),
                                      child: Icon(
                                          _attachedImage == null
                                              ? Icons.add_a_photo_outlined
                                              : Icons.check_circle_rounded,
                                          color: _attachedImage == null
                                              ? SolarColors.primary
                                              : SolarColors.success,
                                          size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                _attachedImage == null
                                                    ? 'Add a roof photo'
                                                    : 'Roof photo attached',
                                                style: const TextStyle(
                                                    color: SolarColors.text,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            const SizedBox(height: 3),
                                            Text(
                                                _attachedImage?.name ??
                                                    'Optional · JPG or PNG',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: SolarColors.muted,
                                                    fontSize: 10)),
                                          ]),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: SolarColors.muted),
                                  ]),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _loading ? null : _createAndSubmitSurvey,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: SolarColors.primary))
                                    : const Icon(Icons.auto_awesome_rounded,
                                        size: 19),
                                label: Text(_loading
                                    ? 'Analysing your survey…'
                                    : 'Create my solar project'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SolarColors.lime,
                                  foregroundColor: SolarColors.primary,
                                  disabledBackgroundColor:
                                      SolarColors.surfaceSoft,
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13)),
                                ),
                              ),
                            ),
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(top: 13),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: SolarColors.errorSoft,
                                    borderRadius: BorderRadius.circular(11)),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          color: SolarColors.error, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(_error!,
                                              style: const TextStyle(
                                                  color: SolarColors.error,
                                                  fontSize: 11,
                                                  height: 1.4))),
                                    ]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(children: [
                  const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your projects',
                              style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: SolarColors.text)),
                          SizedBox(height: 3),
                          Text('Track submitted assessments and proposals',
                              style: TextStyle(
                                  color: SolarColors.muted, fontSize: 11)),
                        ]),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0x1872B83E),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${_surveys.length} total',
                        style: const TextStyle(
                            color: SolarColors.limeDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 14),
                SolarSearch(
                    label: 'Search your projects',
                    onChanged: (value) =>
                        setState(() => _search = value.toLowerCase())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    isExpanded: true,
                    decoration: _fieldDecoration(
                        hint: 'Filter by status', icon: Icons.tune_rounded),
                    onChanged: (value) =>
                        setState(() => _statusFilter = value ?? ''),
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('All project statuses')),
                      ..._surveys.map((s) => s.surveyStatus).toSet().map(
                          (status) => DropdownMenuItem(
                              value: status, child: Text(status))),
                    ]),
                const SizedBox(height: 14),
                if (!_fetching &&
                    _surveys.isNotEmpty &&
                    !_surveys.any((s) =>
                        (s.propertyAddress.toLowerCase().contains(_search) ||
                            s.id.toLowerCase().contains(_search)) &&
                        (_statusFilter.isEmpty ||
                            s.surveyStatus == _statusFilter)))
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'No matching surveys. Try another address or reference, or select all statuses.')),
                if (_fetching && _surveys.isEmpty)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator()))
                else if (_surveys.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SolarColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No surveys submitted yet.',
                        style: TextStyle(color: SolarColors.muted)),
                  )
                else
                  ..._surveys
                      .where((survey) =>
                          (survey.propertyAddress
                                  .toLowerCase()
                                  .contains(_search) ||
                              survey.id.toLowerCase().contains(_search)) &&
                          (_statusFilter.isEmpty ||
                              survey.surveyStatus == _statusFilter))
                      .map((survey) => _buildSurveyItemCard(survey)),
              ],
            )),
      ),
    );
  }

  Widget _buildSurveyItemCard(SolarSurvey survey) {
    final statusColor = _getStatusColor(survey.surveyStatus);
    final hasFailed = survey.surveyStatus.toUpperCase() == 'FAILED' ||
        survey.errorMessage != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SolarColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecordReference(label: 'Survey reference', value: survey.id),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  survey.propertyAddress.isNotEmpty
                      ? survey.propertyAddress
                      : 'Solar Survey',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: SolarColors.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  survey.surveyStatus,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            '${survey.monthlyKwh} kWh/mo · ${survey.roofAreaSqm} m² · ${survey.gridType}',
            style: const TextStyle(fontSize: 13, color: SolarColors.muted),
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
                      Icon(Icons.wb_sunny,
                          color: SolarColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text('Recommended System Size',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: SolarColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text('Array: ${survey.recommendedKw} kW',
                          style: const TextStyle(
                              color: SolarColors.text,
                              fontWeight: FontWeight.bold)),
                      Text('Panels: ${survey.panelCount ?? "-"} x 400W',
                          style: const TextStyle(
                              color: SolarColors.text,
                              fontWeight: FontWeight.bold)),
                      Text('Inverter: ${survey.inverterKw} kW',
                          style: const TextStyle(
                              color: SolarColors.text,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (survey.isValid != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Deterministic Validation: ${survey.isValid == true ? "PASSED" : "FAILED"}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: survey.isValid == true
                              ? SolarColors.primary
                              : SolarColors.error),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (hasFailed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SolarColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: SolarColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: SolarColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      survey.errorMessage ??
                          'Sizing could not be completed. Please try again later.',
                      style: const TextStyle(
                          fontSize: 12, color: SolarColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (['ANALYSISCOMPLETE', 'COMPLETED']
              .contains(survey.surveyStatus.toUpperCase()))
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProposalScreen(surveyId: survey.id))),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Proposal and equipment'),
            ),
        ],
      ),
    );
  }
}
