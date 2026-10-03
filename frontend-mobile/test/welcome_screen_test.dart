import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/core/auth/providers/auth_provider.dart';
import 'package:smart_solar_mobile/core/navigation/screens/welcome_screen.dart';

void main() {
  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets('welcome content fits without scrolling at $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      expect(find.byType(SingleChildScrollView), findsNothing);
      for (final label in [
        'Register',
        'Login',
        'Assess',
        'Review',
        'Track',
        'How it works'
      ]) {
        expect(find.text(label).hitTestable(), findsOneWidget);
      }
      expect(tester.getBottomRight(find.textContaining('SMART SOLAR')).dy,
          lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('welcome process expands and collapses on a small screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.ensureVisible(find.text('How it works'));
    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();
    for (final title in [
      'Assess your rooftop',
      'Review your solar plan',
      'Track your project'
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('How it works'));
    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();
    expect(find.text('Assess your rooftop'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'welcome page sends guests to manual login without demo shortcuts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: WelcomeScreen())));
    expect(find.text('Your rooftop.\nA brighter tomorrow.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ActionChip), findsNothing);
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.controller!.text, isEmpty);
    }
    expect(tester.takeException(), isNull);
  });
}
