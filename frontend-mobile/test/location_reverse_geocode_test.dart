import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_solar_mobile/core/api/api_service.dart';
import 'package:smart_solar_mobile/core/auth/services/storage_service.dart';

class _TestStorageService extends StorageService {
  @override
  Future<String?> getToken() async => 'test-token';
}

void main() {
  test('reverse location requests an address for the selected map point',
      () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response(
          jsonEncode({
            'displayName': '45 Galle Road, Colombo, Sri Lanka',
            'latitude': 6.9271,
            'longitude': 79.8612,
          }),
          200,
          headers: {'content-type': 'application/json'});
    });
    final api = ApiService(
        baseUrl: 'http://localhost:5116',
        client: client,
        storageService: _TestStorageService());

    final result = await api.reverseLocation(6.9271, 79.8612);

    expect(requestedUri.path, '/api/locations/reverse');
    expect(requestedUri.queryParameters['latitude'], '6.9271');
    expect(requestedUri.queryParameters['longitude'], '79.8612');
    expect(result['displayName'], '45 Galle Road, Colombo, Sri Lanka');
  });
}
