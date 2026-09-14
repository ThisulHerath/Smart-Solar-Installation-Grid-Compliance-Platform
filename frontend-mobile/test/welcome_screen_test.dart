import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/providers/auth_provider.dart';
import 'package:smart_solar_mobile/screens/welcome_screen.dart';

void main() {
  testWidgets('welcome page sends guests to manual login without demo shortcuts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => AuthProvider(), child: const MaterialApp(home: WelcomeScreen())));
    expect(find.text('Your rooftop.\nA brighter tomorrow.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ActionChip), findsNothing);
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.controller!.text, isEmpty);
    }
    expect(tester.takeException(), isNull);
  });
}
