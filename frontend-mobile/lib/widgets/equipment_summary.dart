import 'package:flutter/material.dart';
import '../models/equipment_quote.dart';
import '../services/api_service.dart';

class EquipmentSummary extends StatefulWidget {
  final String proposalId;
  const EquipmentSummary({super.key, required this.proposalId});
  @override
  State<EquipmentSummary> createState() => _EquipmentSummaryState();
}

class _EquipmentSummaryState extends State<EquipmentSummary> {
  late Future<List<EquipmentQuote>> _quotes;
  Future<List<EquipmentQuote>> _load() async {
    final data = await ApiService().get('/api/inventory/proposals/${widget.proposalId}/equipment');
    return (data as List).map((row) => EquipmentQuote.fromJson(Map<String, dynamic>.from(row))).toList();
  }
  @override
  void initState() { super.initState(); _quotes = _load(); }
  @override
  void didUpdateWidget(covariant EquipmentSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposalId != widget.proposalId) _quotes = _load();
  }
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF111726),
    child: Padding(padding: const EdgeInsets.all(20), child: FutureBuilder<List<EquipmentQuote>>(
      future: _quotes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Text('Loading equipment…', style: TextStyle(color: Colors.white70));
        if (snapshot.hasError) return TextButton(onPressed: () => setState(() { _quotes = _load(); }), child: const Text('Equipment unavailable. Retry'));
        final quotes = snapshot.data ?? [];
        if (quotes.isEmpty) return const Text('Equipment pricing has not been prepared yet.', style: TextStyle(color: Colors.white70));
        final reserved = quotes.where((q) => q.status == 'RESERVED');
        final quote = reserved.isNotEmpty ? reserved.first : quotes.first;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Equipment summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Status: ${quote.status}', style: const TextStyle(color: Colors.white70)),
          if (quote.error != null) Text(quote.error!, style: const TextStyle(color: Colors.orangeAccent)),
          if (quote.totalPriceLkr != null) Text('Estimated equipment: LKR ${quote.totalPriceLkr!.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF10B981))),
          ...quote.lines.map((line) => Padding(padding: const EdgeInsets.only(top: 8), child: Text('${line.quantity} × ${line.name}', style: const TextStyle(color: Colors.white70)))),
          const SizedBox(height: 12),
          const Text('Equipment estimate excludes installation and taxes.\nRates By Exchange Rate API — www.exchangerate-api.com', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ]);
      },
    )),
  );
}
