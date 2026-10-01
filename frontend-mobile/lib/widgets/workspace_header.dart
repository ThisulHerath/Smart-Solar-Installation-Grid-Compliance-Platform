import 'package:flutter/material.dart';
import '../theme/solar_theme.dart';

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
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SolarColors.primary, SolarColors.heroEnd]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: SolarColors.heroAccent, size: 23),
            const SizedBox(width: 10),
            Expanded(
                child: Text(eyebrow.toUpperCase(),
                    style: const TextStyle(
                        color: SolarColors.heroAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3))),
          ]),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -.5)),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(
                  color: SolarColors.heroText, fontSize: 13, height: 1.6)),
        ]),
      );
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
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 21)),
              const SizedBox(height: 14),
              Text(value,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: SolarColors.text)),
              const SizedBox(height: 5),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: SolarColors.muted, height: 1.4)),
            ])),
      );
}
