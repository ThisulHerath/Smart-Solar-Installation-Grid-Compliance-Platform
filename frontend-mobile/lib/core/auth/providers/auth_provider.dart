import 'package:flutter/foundation.dart';
import 'package:smart_solar_mobile/core/auth/models/user.dart';
import 'package:smart_solar_mobile/core/auth/services/auth_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get requiresStaffOnboarding => _user?.mustChangePassword ?? false;

  Future<Map<String, dynamic>> requestStaffOnboarding(String newPassword) =>
      _authService.requestStaffOnboarding(newPassword);

  Future<void> confirmStaffOnboarding(String challengeId, String code) =>
      _authService.confirmStaffOnboarding(challengeId, code);

  Future<void> initializeAuth() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        _user = currentUser;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _user = response.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  bool hasRole(String role) {
    return _user?.roles.contains(role) ?? false;
  }
}
