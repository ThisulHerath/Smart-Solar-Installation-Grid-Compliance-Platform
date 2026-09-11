import 'package:flutter_test/flutter_test.dart';
import 'package:smart_solar_mobile/models/equipment_quote.dart';

void main() {
  test('Parses reserved equipment and numeric costs', () {
    final quote = EquipmentQuote.fromJson({'status': 'RESERVED', 'result': {'totalPriceLkr': 1350000, 'lines': [
      {'name': '500 W panel', 'quantity': 10, 'totalPriceLkr': 1350000}
    ]}});
    expect(quote.totalPriceLkr, 1350000.0);
    expect(quote.lines.single.quantity, 10);
    expect(quote.status, 'RESERVED');
  });
  test('Failed quote does not invent prices or equipment', () {
    final quote = EquipmentQuote.fromJson({'status': 'FAILED', 'error': 'Unavailable', 'result': null});
    expect(quote.totalPriceLkr, isNull);
    expect(quote.lines, isEmpty);
    expect(quote.error, 'Unavailable');
  });
}
