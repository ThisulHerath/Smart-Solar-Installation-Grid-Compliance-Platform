import 'package:flutter_test/flutter_test.dart';
import 'package:smart_solar_mobile/models/user.dart';
import 'package:smart_solar_mobile/models/auth_response.dart';

void main() {
  group('Smart Solar Mobile Models Test', () {
    test('User fromJson correctly parses valid data', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111111',
        'email': 'admin@smartsolar.local',
        'fullName': 'System Administrator',
        'roles': ['ADMINISTRATOR'],
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.id, '11111111-1111-1111-1111-111111111111');
      expect(user.email, 'admin@smartsolar.local');
      expect(user.fullName, 'System Administrator');
      expect(user.roles, contains('ADMINISTRATOR'));
    });

    test('AuthResponse fromJson correctly deserializes payload', () {
      final json = {
        'token': 'mock.jwt.token',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'user': {
          'id': '22222222-2222-2222-2222-222222222222',
          'email': 'engineer@smartsolar.local',
          'fullName': 'Senior Engineer',
          'roles': ['SENIOR_ENGINEER'],
          'createdAt': '2026-01-01T00:00:00Z',
        },
      };

      final authResponse = AuthResponse.fromJson(json);

      expect(authResponse.token, 'mock.jwt.token');
      expect(authResponse.expiresIn, 3600);
      expect(authResponse.user.email, 'engineer@smartsolar.local');
      expect(authResponse.user.roles, contains('SENIOR_ENGINEER'));
    });
  });
}
