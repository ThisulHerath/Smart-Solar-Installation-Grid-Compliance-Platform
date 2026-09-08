import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;
  final StorageService _storageService;

  ApiService({
    String? baseUrl,
    http.Client? client,
    StorageService? storageService,
  })  : baseUrl = baseUrl ?? AppConstants.defaultApiBaseUrl,
        _client = client ?? http.Client(),
        _storageService = storageService ?? StorageService();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    final response = await _client.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getSurveys() async => List<dynamic>.from(await get('/api/surveys'));

  Future<Map<String, dynamic>> createSurvey({required double monthlyKwh, required double roofAreaSqm, required String gridType, required String propertyAddress}) async {
    final response = await post('/api/surveys', {
      'monthlyKwh': monthlyKwh, 'roofAreaSqm': roofAreaSqm, 'gridType': gridType,
      'propertyAddress': propertyAddress, 'roofOrientation': 'Unknown',
    });
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> submitSurvey(String id) async => Map<String, dynamic>.from(await post('/api/surveys/$id/submit', {}));

  /// Upload an [XFile] as bytes so this works on Flutter Web as well as mobile.
  /// `MultipartFile.fromPath` depends on dart:io and fails in a browser.
  Future<dynamic> uploadSurveyImage(String id, XFile image, String imageType) async {
    final token = await _storageService.getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/surveys/$id/images'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['imageType'] = imageType;
    final bytes = await image.readAsBytes();
    final contentType = _imageContentType(image.name, image.mimeType);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: image.name,
      contentType: contentType,
    ));
    final response = await http.Response.fromStream(await request.send());
    return _handleResponse(response);
  }

  MediaType _imageContentType(String fileName, String? mimeType) {
    if (mimeType == 'image/jpeg' || mimeType == 'image/png') {
      return MediaType.parse(mimeType!);
    }
    final name = fileName.toLowerCase();
    return name.endsWith('.png')
        ? MediaType('image', 'png')
        : MediaType('image', 'jpeg');
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Request failed with status: ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
