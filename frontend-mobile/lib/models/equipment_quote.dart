class EquipmentQuote {
  final String status;
  final String? error;
  final double? totalPriceLkr;
  final List<EquipmentLine> lines;
  EquipmentQuote({required this.status, this.error, this.totalPriceLkr, required this.lines});
  factory EquipmentQuote.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;
    return EquipmentQuote(status: json['status'] as String, error: json['error'] as String?,
      totalPriceLkr: (result?['totalPriceLkr'] as num?)?.toDouble(),
      lines: ((result?['lines'] as List?) ?? []).map((line) => EquipmentLine.fromJson(Map<String, dynamic>.from(line))).toList());
  }
}

class EquipmentLine {
  final String name;
  final int quantity;
  final double totalPriceLkr;
  EquipmentLine({required this.name, required this.quantity, required this.totalPriceLkr});
  factory EquipmentLine.fromJson(Map<String, dynamic> json) => EquipmentLine(name: json['name'] as String,
    quantity: (json['quantity'] as num).toInt(), totalPriceLkr: (json['totalPriceLkr'] as num).toDouble());
}
