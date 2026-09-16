import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_solar_mobile/utils/validators.dart';
import 'package:smart_solar_mobile/widgets/solar_search.dart';
import 'package:smart_solar_mobile/widgets/solar_field.dart';

void main() {
  test('shared validators reject invalid values and preserve decimal measurements', () {
    expect(Validators.email('bad'), isNotNull);
    expect(Validators.email('solar@example.com'), isNull);
    expect(Validators.number('12.5', min: 1), isNull);
    expect(Validators.number('NaN'), isNotNull);
    expect(Validators.number('-1'), isNotNull);
    expect(Validators.number('', optional: true), isNull);
    expect(Validators.code('12345x'), isNotNull);
    expect(Validators.code('123456'), isNull);
    expect(Validators.password('short'), isNotNull);
    expect(Validators.confirm('different', 'password'), isNotNull);
    expect(solarDecimalFormatter.formatEditUpdate(const TextEditingValue(text: '12.5'), const TextEditingValue(text: '12.5.')).text, '12.5');
  });
  testWidgets('search debounces, submits immediately and cancels after disposal', (tester) async {
    final values = <String>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SolarSearch(label: 'Search surveys', onChanged: values.add))));
    await tester.enterText(find.byType(TextField), 'Col');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'Colombo');
    await tester.pump(const Duration(milliseconds: 249));
    expect(values, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(values, ['Colombo']);
    await tester.enterText(find.byType(TextField), 'Roof');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(values.last, 'Roof');
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(values.last, '');
    await tester.enterText(find.byType(TextField), 'Pending');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    expect(values, isNot(contains('Pending')));
  });
}
