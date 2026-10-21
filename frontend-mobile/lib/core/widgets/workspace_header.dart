import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';

/// Shared introduction for mobile workspaces, matching the website hero.
class WorkspaceHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  const WorkspaceHeader(
      {super.key,
      required this.eyebrow,
      required this.title,
      required this.description,
      this.icon = Icons.solar_power_rounded});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SolarColors.primary,
                Color(0xFF176C71),
                SolarColors.heroEnd
              ]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x29173E44),
                blurRadius: 24,
                offset: Offset(0, 12)),
          ],
        ),
        child: Stack(children: [
          const Positioned.fill(
              child: IgnorePointer(
                  child: CustomPaint(painter: _SolarHeaderPainter()))),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: .12))),
                    child: Icon(icon, color: SolarColors.heroAccent, size: 21)),
                const SizedBox(width: 11),
                Expanded(
                    child: Text(eyebrow.toUpperCase(),
                        style: const TextStyle(
                            color: SolarColors.heroAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.45))),
              ]),
              const SizedBox(height: 19),
              FractionallySizedBox(
                widthFactor: .78,
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.16,
                        letterSpacing: -.55)),
              ),
              const SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: .79,
                alignment: Alignment.centerLeft,
                child: Text(description,
                    style: const TextStyle(
                        color: SolarColors.heroText,
                        fontSize: 13,
                        height: 1.58)),
              ),
            ]),
          ),
        ]),
      );
}

class _SolarHeaderPainter extends CustomPainter {
  const _SolarHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: .055);
    for (double x = 12; x < size.width; x += 22) {
      for (double y = 12; y < size.height; y += 22) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }

    final sunCenter = Offset(size.width - 46, 45);
    final sunPaint = Paint()
      ..color = SolarColors.heroAccent.withValues(alpha: .32);
    canvas.drawCircle(sunCenter, 18, sunPaint);
    final rayPaint = Paint()
      ..color = SolarColors.heroAccent.withValues(alpha: .28)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        sunCenter + Offset(math.cos(angle) * 25, math.sin(angle) * 25),
        sunCenter + Offset(math.cos(angle) * 32, math.sin(angle) * 32),
        rayPaint,
      );
    }

    final panelWidth = math.min(138.0, size.width * .39);
    final panelHeight = panelWidth * .48;
    final panelRect = Rect.fromLTWH(size.width - panelWidth + 17,
        size.height - panelHeight + 8, panelWidth, panelHeight);
    final panelPath = Path()
      ..moveTo(panelRect.left + 14, panelRect.top)
      ..lineTo(panelRect.right, panelRect.top)
      ..lineTo(panelRect.right - 14, panelRect.bottom)
      ..lineTo(panelRect.left, panelRect.bottom)
      ..close();
    canvas.drawPath(panelPath,
        Paint()..color = const Color(0xFFB8E2D8).withValues(alpha: .22));
    canvas.drawPath(
        panelPath,
        Paint()
          ..color = Colors.white.withValues(alpha: .28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .16)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final x = panelRect.left + panelWidth * i / 4;
      canvas.drawLine(Offset(x, panelRect.top + 2),
          Offset(x - 8, panelRect.bottom - 2), gridPaint);
    }
    canvas.drawLine(Offset(panelRect.left + 7, panelRect.center.dy),
        Offset(panelRect.right - 7, panelRect.center.dy), gridPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WorkspaceMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const WorkspaceMetric(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      this.color = SolarColors.primary});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFFBFDF9)])),
            child: Stack(children: [
              Positioned(
                  right: -17,
                  bottom: -20,
                  child: Icon(icon,
                      size: 88, color: color.withValues(alpha: .055))),
              Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: .09),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(icon, color: color, size: 21)),
                        const SizedBox(height: 14),
                        Text(value,
                            style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                color: SolarColors.text)),
                        const SizedBox(height: 5),
                        Text(label,
                            style: const TextStyle(
                                fontSize: 12,
                                color: SolarColors.muted,
                                height: 1.4)),
                      ])),
            ])),
      );
}
