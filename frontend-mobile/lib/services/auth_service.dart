import '../models/auth_response.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  Future<AuthResponse> login(String email, String password) async {
    final response = await _apiService.post(
      '/api/auth/login',
      {'email': email, 'password': password},
      requiresAuth: false,
    );

    final authResponse = AuthResponse.fromJson(response);
    await _storageService.saveToken(authResponse.token);
    return authResponse;
  }

  Future<User?> getCurrentUser() async {
    final token = await _storageService.getToken();
    if (token == null) return null;

    try {
      final response = await _apiService.get('/api/auth/me');
      return User.fromJson(response);
    } catch (_) {
      await _storageService.clearToken();
      return null;
    }
  }

  Future<void> logout() async {
    await _storageService.clearToken();
  }
}
