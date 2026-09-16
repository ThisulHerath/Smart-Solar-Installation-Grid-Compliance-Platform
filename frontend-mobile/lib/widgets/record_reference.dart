import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/solar_theme.dart';

class RecordReference extends StatelessWidget {
  final String label, value;
  const RecordReference({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: SolarColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: SolarColors.muted)),
                SelectableText(value,
                    style: const TextStyle(
                        fontSize: 12,
                        color: SolarColors.text,
                        fontFamily: 'monospace')),
              ])),
          IconButton(
              tooltip: 'Copy $label',
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('$label copied')));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Select the reference to copy it.')));
                  }
                }
              })
        ]),
      );
}
