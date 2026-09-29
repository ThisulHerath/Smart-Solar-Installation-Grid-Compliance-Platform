import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/solar_survey.dart';
import '../services/api_service.dart';
import '../theme/solar_theme.dart';
import '../widgets/record_reference.dart';

class CustomerLocationsScreen extends StatefulWidget {
  const CustomerLocationsScreen({super.key});

  @override
  State<CustomerLocationsScreen> createState() =>
      _CustomerLocationsScreenState();
}

class _CustomerLocationsScreenState extends State<CustomerLocationsScreen> {
  final _api = ApiService();
  List<SolarSurvey> _surveys = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _api.getSurveys();
      if (!mounted) return;
      setState(() => _surveys = rows
          .map((row) =>
              SolarSurvey.fromJson(Map<String, dynamic>.from(row as Map)))
          .where(
              (survey) => survey.latitude != null && survey.longitude != null)
          .toList());
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load customer locations.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigate(SolarSurvey survey) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${survey.latitude},${survey.longitude}',
    });
    try {
      final opened = await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open map directions.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open map directions.')));
      }
    }
  }

  void _showSurvey(SolarSurvey survey) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: SolarColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(survey.customerName ?? 'Solar customer',
                  style: const TextStyle(
                      color: SolarColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 5),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(survey.propertyAddress,
                    style: const TextStyle(color: SolarColors.muted))),
            const SizedBox(height: 10),
            RecordReference(label: 'Survey ID', value: survey.id),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => _navigate(survey),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Open directions'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
        backgroundColor: SolarColors.surface,
        title: const Text('Customer locations'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!,
                        style: const TextStyle(color: SolarColors.error)),
                    TextButton(
                        onPressed: _load, child: const Text('Try again')),
                  ]),
                )
              : _surveys.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'No surveys have a confirmed map location yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: SolarColors.muted)),
                      ),
                    )
                  : FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(7.8731, 80.7718),
                        initialZoom: 8,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'lk.smartsolar.platform',
                        ),
                        MarkerLayer(
                          markers: _surveys
                              .map((survey) => Marker(
                                    width: 50,
                                    height: 50,
                                    point: LatLng(
                                        survey.latitude!, survey.longitude!),
                                    child: Semantics(
                                      button: true,
                                      label:
                                          '${survey.customerName ?? 'Customer'} at ${survey.propertyAddress}',
                                      child: GestureDetector(
                                        onTap: () => _showSurvey(survey),
                                        child: const Icon(Icons.location_pin,
                                            color: SolarColors.primary,
                                            size: 46),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        RichAttributionWidget(attributions: [
                          TextSourceAttribution('OpenStreetMap contributors',
                              onTap: () => launchUrl(Uri.parse(
                                  'https://www.openstreetmap.org/copyright'))),
                        ]),
                      ],
                    ),
    );
  }
}
