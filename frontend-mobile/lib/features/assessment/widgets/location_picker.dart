import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_solar_mobile/core/api/api_service.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';

class PropertyLocation {
  final double latitude;
  final double longitude;
  const PropertyLocation(this.latitude, this.longitude);
}

class LocationPicker extends StatefulWidget {
  final TextEditingController addressController;
  final PropertyLocation? value;
  final ValueChanged<PropertyLocation?> onChanged;
  final bool disabled;

  const LocationPicker({
    super.key,
    required this.addressController,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _api = ApiService();
  final _mapController = MapController();
  bool _expanded = false;
  bool _searching = false;
  bool _resolvingAddress = false;
  int _reverseRequestId = 0;
  String? _message;
  List<Map<String, dynamic>> _results = [];

  void _select(PropertyLocation location, {String? address}) {
    _reverseRequestId++;
    if (address != null) widget.addressController.text = address;
    widget.onChanged(location);
    setState(() {
      _expanded = true;
      _resolvingAddress = false;
      _results = [];
      _message =
          'Location selected. Tap another point if adjustment is required.';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(LatLng(location.latitude, location.longitude), 16);
    });
  }

  Future<void> _selectAndResolveAddress(PropertyLocation location,
      {required bool currentLocation}) async {
    final requestId = ++_reverseRequestId;
    widget.onChanged(location);
    setState(() {
      _expanded = true;
      _resolvingAddress = true;
      _results = [];
      _message = 'Location selected. Finding its street address…';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(LatLng(location.latitude, location.longitude), 16);
    });

    try {
      final result =
          await _api.reverseLocation(location.latitude, location.longitude);
      if (!mounted || requestId != _reverseRequestId) return;
      widget.addressController.text = result['displayName']?.toString() ?? '';
      setState(() {
        _message = currentLocation
            ? 'Current location and property address added. Confirm the rooftop pin.'
            : 'Map location and property address added. Tap again if adjustment is required.';
      });
    } catch (error) {
      if (!mounted || requestId != _reverseRequestId) return;
      widget.addressController.text =
          'Pinned location (${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)})';
      setState(() => _message =
          'The street address could not be loaded. Coordinates were added to the address field and can be edited.');
    } finally {
      if (mounted && requestId == _reverseRequestId) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  Future<void> _findAddress() async {
    final query = widget.addressController.text.trim();
    if (query.length < 3) {
      setState(() => _message = 'Enter at least 3 address characters first.');
      return;
    }
    setState(() {
      _searching = true;
      _message = null;
    });
    try {
      final matches = await _api.searchLocations(query);
      if (!mounted) return;
      setState(() {
        _results = matches;
        if (matches.isEmpty) {
          _message = 'No match found. Tap Choose on map to place the pin.';
        }
      });
      if (matches.length == 1) _chooseResult(matches.first);
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'Address search is unavailable. You can still choose on the map.');
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _chooseResult(Map<String, dynamic> result) {
    final latitude = (result['latitude'] as num).toDouble();
    final longitude = (result['longitude'] as num).toDouble();
    _select(PropertyLocation(latitude, longitude),
        address: result['displayName']?.toString());
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _message = 'Requesting your current location…');
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      await _selectAndResolveAddress(
          PropertyLocation(position.latitude, position.longitude),
          currentLocation: true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _expanded = true;
          _message =
              'Location permission was not granted. Tap the map to place the pin.';
        });
      }
    }
  }

  void _clearLocation() {
    _reverseRequestId++;
    widget.onChanged(null);
    setState(() {
      _resolvingAddress = false;
      _message = 'Map location cleared. You can keep or edit the address.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 17),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SolarColors.surfaceSoft,
        border: Border.all(color: SolarColors.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _LocationAction(
              icon: Icons.search_rounded,
              label: _searching ? 'Finding…' : 'Find address',
              onPressed: widget.disabled || _searching ? null : _findAddress),
          _LocationAction(
              icon: Icons.my_location_rounded,
              label: _resolvingAddress ? 'Adding address…' : 'Use my location',
              onPressed: widget.disabled || _resolvingAddress
                  ? null
                  : _useCurrentLocation),
          _LocationAction(
              icon: Icons.map_outlined,
              label: _expanded ? 'Hide map' : 'Choose on map',
              onPressed: widget.disabled
                  ? null
                  : () => setState(() => _expanded = !_expanded)),
        ]),
        if (_results.length > 1) ...[
          const SizedBox(height: 10),
          const Text('Select the correct address',
              style: TextStyle(
                  color: SolarColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          ..._results.map((result) => ListTile(
                minTileHeight: 48,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined,
                    color: SolarColors.primary),
                title: Text(result['displayName']?.toString() ?? '',
                    style: const TextStyle(fontSize: 11)),
                onTap: () => _chooseResult(result),
              )),
        ],
        if (_message != null) ...[
          const SizedBox(height: 9),
          Text(_message!,
              style: const TextStyle(
                  color: SolarColors.muted, fontSize: 11, height: 1.4)),
        ],
        if (selected != null) ...[
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
                color: const Color(0xFFEAF7E4),
                borderRadius: BorderRadius.circular(9)),
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: SolarColors.success, size: 18),
              const SizedBox(width: 7),
              const Expanded(
                  child: Text('Location selected for technician navigation',
                      style: TextStyle(
                          color: SolarColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
              IconButton(
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  tooltip: 'Clear location',
                  onPressed: widget.disabled ? null : _clearLocation,
                  icon: const Icon(Icons.close_rounded, size: 18)),
            ]),
          ),
        ],
        if (_expanded) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              height: 280,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: selected == null
                      ? const LatLng(7.8731, 80.7718)
                      : LatLng(selected.latitude, selected.longitude),
                  initialZoom: selected == null ? 8 : 16,
                  onTap: (_, point) => _selectAndResolveAddress(
                      PropertyLocation(point.latitude, point.longitude),
                      currentLocation: false),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'lk.smartsolar.platform',
                  ),
                  if (selected != null)
                    MarkerLayer(markers: [
                      Marker(
                        width: 48,
                        height: 48,
                        point: LatLng(selected.latitude, selected.longitude),
                        child: const Icon(Icons.location_pin,
                            color: SolarColors.primary, size: 44),
                      )
                    ]),
                  RichAttributionWidget(attributions: [
                    TextSourceAttribution('OpenStreetMap contributors',
                        onTap: () => launchUrl(Uri.parse(
                            'https://www.openstreetmap.org/copyright'))),
                  ]),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Text('Tap the map to place the pin on the rooftop.',
                style: TextStyle(color: SolarColors.muted, fontSize: 10)),
          ),
        ],
      ]),
    );
  }
}

class _LocationAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _LocationAction(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: SolarColors.primary,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
}
