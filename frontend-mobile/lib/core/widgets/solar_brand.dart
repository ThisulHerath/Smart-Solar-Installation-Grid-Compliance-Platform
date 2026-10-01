import 'package:flutter/material.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';

class SolarBrand extends StatelessWidget {
  final Color color;
  final double size;
  const SolarBrand(
      {super.key, this.color = SolarColors.primary, this.size = 22});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Smart Solar',
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wb_sunny_outlined,
              size: size + 4, color: SolarColors.lime),
          const SizedBox(width: 5),
          Text('smartsolar.',
              style: TextStyle(
                color: color,
                fontSize: size,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
              )),
        ]),
      );
}
