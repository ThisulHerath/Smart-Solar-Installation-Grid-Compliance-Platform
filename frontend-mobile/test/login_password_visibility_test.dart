import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/core/auth/providers/auth_provider.dart';
import 'package:smart_solar_mobile/core/navigation/screens/login_screen.dart';
import 'package:smart_solar_mobile/core/widgets/solar_field.dart';

void main() {
  testWidgets(
      'login screen toggles password visibility when eye icon is tapped',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    final passwordFieldFinder =
        find.byKey(const ValueKey('login_password_field'));
    expect(passwordFieldFinder, findsOneWidget);
    expect(
      tester.widget<SolarField>(passwordFieldFinder).obscureText,
      isTrue,
    );

    final toggleFinder = find.byTooltip('Show password');
    expect(toggleFinder, findsOneWidget);

    await tester.tap(toggleFinder);
    await tester.pump();

    expect(passwordFieldFinder, findsOneWidget);
    expect(
      tester.widget<SolarField>(passwordFieldFinder).obscureText,
      isFalse,
    );

    final hideToggleFinder = find.byTooltip('Hide password');
    expect(hideToggleFinder, findsOneWidget);

    await tester.tap(hideToggleFinder);
    await tester.pump();

    expect(passwordFieldFinder, findsOneWidget);
    expect(
      tester.widget<SolarField>(passwordFieldFinder).obscureText,
      isTrue,
    );
  });

  testWidgets('forgot password link opens the reset password flow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Forgot Your Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Recover your account'), findsOneWidget);
    expect(find.text('Send verification code'), findsOneWidget);
    expect(find.byTooltip('Show new password'), findsOneWidget);
    expect(find.byTooltip('Show confirmed password'), findsOneWidget);
  });
}
