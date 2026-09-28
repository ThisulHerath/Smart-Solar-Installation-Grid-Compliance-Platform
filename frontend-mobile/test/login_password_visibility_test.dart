import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/providers/auth_provider.dart';
import 'package:smart_solar_mobile/screens/login_screen.dart';

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

    final passwordFieldFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.obscureText,
    );
    expect(passwordFieldFinder, findsOneWidget);

    TextField passwordField = tester.widget<TextField>(passwordFieldFinder);
    expect(passwordField.obscureText, isTrue);

    final toggleFinder = find.byTooltip('Show password');
    expect(toggleFinder, findsOneWidget);

    await tester.tap(toggleFinder);
    await tester.pump();

    final visiblePasswordFieldFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && !widget.obscureText,
    );
    expect(visiblePasswordFieldFinder, findsOneWidget);
    passwordField = tester.widget<TextField>(visiblePasswordFieldFinder);
    expect(passwordField.obscureText, isFalse);

    final hideToggleFinder = find.byTooltip('Hide password');
    expect(hideToggleFinder, findsOneWidget);

    await tester.tap(hideToggleFinder);
    await tester.pump();

    final obscuredPasswordFieldFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.obscureText,
    );
    expect(obscuredPasswordFieldFinder, findsOneWidget);
    passwordField = tester.widget<TextField>(obscuredPasswordFieldFinder);
    expect(passwordField.obscureText, isTrue);
  });
}
