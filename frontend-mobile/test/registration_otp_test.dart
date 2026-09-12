import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/providers/auth_provider.dart';
import '../lib/screens/register_screen.dart';
import '../lib/services/api_service.dart';

class MailApi extends ApiService {
  final calls = <String>[];
  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool requiresAuth = true}) async {
    calls.add(endpoint);
    if (endpoint.endsWith('request-otp')) return {'challengeId': 'test-challenge', 'maskedEmail': 'o•••@example.com', 'resendAfterSeconds': 60};
    throw Exception('The verification code is incorrect.');
  }
}
void main() {
  testWidgets('registration requests email first and retains invalid-code feedback', (tester) async {
    final api = MailApi();
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => AuthProvider(), child: MaterialApp(home: RegisterScreen(api: api))));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Solar Owner');
    await tester.enterText(fields.at(1), 'owner@example.com');
    await tester.enterText(fields.at(3), 'A safe passphrase123');
    await tester.ensureVisible(find.text('Send verification code'));
    await tester.tap(find.text('Send verification code')); await tester.pumpAndSettle();
    expect(api.calls, ['/api/auth/register/request-otp']);
    expect(find.text('Email verification code'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verify & create account')); await tester.pumpAndSettle();
    expect(api.calls.last, '/api/auth/register');
    expect(find.text('The verification code is incorrect.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
