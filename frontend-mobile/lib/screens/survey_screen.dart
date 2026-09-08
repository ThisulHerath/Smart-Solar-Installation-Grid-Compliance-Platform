import 'package:flutter/material.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/solar_survey.dart';
import 'package:image_picker/image_picker.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});
  @override State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _usage = TextEditingController();
  final _roof = TextEditingController();
  final _address = TextEditingController();
  final _api = ApiService();
  List<SolarSurvey> _surveys = [];
  String _grid = 'SinglePhase';
  String? _error;
  bool _loading = false;
  XFile? _image;

  Future<void> _load() async { try { final data = await _api.getSurveys(); setState(() => _surveys = data.map((e) => SolarSurvey.fromJson(e)).toList()); } catch (e) { setState(() => _error = e.toString()); } }
  Future<void> _create() async {
    final usage = double.tryParse(_usage.text); final roof = double.tryParse(_roof.text);
    if (usage == null || usage <= 0 || roof == null || roof <= 0 || _address.text.trim().isEmpty) { setState(() => _error = 'Enter positive usage, roof area, and property address.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final created = await _api.createSurvey(monthlyKwh: usage, roofAreaSqm: roof, gridType: _grid, propertyAddress: _address.text.trim());
      if (_image != null) await _api.uploadSurveyImage(created['id'], File(_image!.path), 'RoofSite');
      final submitted = await _api.submitSurvey(created['id']);
      _image = null; _usage.clear(); _roof.clear(); _address.clear(); await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Survey submitted: ${submitted['surveyStatus'] ?? 'processing'}')));
    } catch (_) { if (mounted) setState(() => _error = 'Submission failed. Please try again.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override void initState() { super.initState(); _load(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Solar Surveys')), body: ListView(padding: const EdgeInsets.all(20), children: [
    TextField(controller: _usage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly usage (kWh)')),
    TextField(controller: _roof, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Roof area (m²)')),
    DropdownButtonFormField(value: _grid, items: const [DropdownMenuItem(value: 'SinglePhase', child: Text('Single phase')), DropdownMenuItem(value: 'ThreePhase', child: Text('Three phase'))], onChanged: (v) => setState(() => _grid = v!), decoration: const InputDecoration(labelText: 'Grid type')),
    TextField(controller: _address, decoration: const InputDecoration(labelText: 'Property address')),
    const SizedBox(height: 12), FilledButton.icon(onPressed: _loading ? null : _create, icon: const Icon(Icons.send), label: Text(_loading ? 'Submitting...' : 'Save and submit survey')),
    if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
    const SizedBox(height: 24), const Text('Survey history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ..._surveys.map((s) => ListTile(title: Text(s.propertyAddress), subtitle: Text('${s.monthlyKwh} kWh · ${s.roofAreaSqm} m²'), trailing: Text(s.surveyStatus))),
    OutlinedButton.icon(onPressed: () async { final picked = await ImagePicker().pickImage(source: ImageSource.camera); if (picked != null) setState(() => _image = picked); }, icon: const Icon(Icons.camera_alt), label: Text(_image == null ? 'Attach roof or bill image' : 'Image attached')),
  ]));
}
