import 'package:flutter/material.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';

/// A sun above a solar panel, drawn as a vector for crisp mobile rendering.
class SolarHomeIcon extends StatelessWidget {
  final bool selected;

  const SolarHomeIcon({super.key, this.selected = false});

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SolarColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: SolarColors.border),
        ),
        child: CustomPaint(
          painter: _SolarHomePainter(
            selected ? SolarColors.limeDark : SolarColors.muted,
          ),
        ),
      );
}

class _SolarHomePainter extends CustomPainter {
  final Color color;

  const _SolarHomePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 28);
    final fill = Paint()..color = color;
    final ray = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(const Offset(14, 8), 3.5, fill);
    for (final points in const [
      [Offset(14, 1), Offset(14, 2)],
      [Offset(7, 8), Offset(8, 8)],
      [Offset(20, 8), Offset(21, 8)],
      [Offset(9, 3), Offset(9.8, 3.8)],
      [Offset(18.2, 3.8), Offset(19, 3)],
      [Offset(9, 13), Offset(9.8, 12.2)],
      [Offset(18.2, 12.2), Offset(19, 13)],
    ]) {
      canvas.drawLine(points[0], points[1], ray);
    }

    final panel = Path()
      ..moveTo(5.5, 16)
      ..lineTo(22.5, 16)
      ..lineTo(25, 26)
      ..lineTo(3, 26)
      ..close();
    canvas.drawPath(panel, fill);
    canvas.save();
    canvas.clipPath(panel);
    final grid = Paint()
      ..color = SolarColors.surface
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(14, 16), const Offset(14, 26), grid);
    canvas.drawLine(const Offset(3, 21), const Offset(25, 21), grid);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SolarHomePainter oldDelegate) =>
      oldDelegate.color != color;
}
