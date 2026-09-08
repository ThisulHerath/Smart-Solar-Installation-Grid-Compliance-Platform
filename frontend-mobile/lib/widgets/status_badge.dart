import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = const Color(0x2610B981),
    this.textColor = const Color(0xFF34D399),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
