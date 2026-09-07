import 'user.dart';

class AuthResponse {
  final String token;
  final String tokenType;
  final int expiresIn;
  final User user;

  AuthResponse({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int? ?? 3600,
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}
