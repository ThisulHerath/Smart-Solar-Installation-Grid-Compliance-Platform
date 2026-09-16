import 'dart:async';
import 'package:flutter/material.dart';

class SolarSearch extends StatefulWidget {
  final String label;
  final ValueChanged<String> onChanged;
  const SolarSearch({super.key, required this.label, required this.onChanged});
  @override
  State<SolarSearch> createState() => _SolarSearchState();
}

class _SolarSearchState extends State<SolarSearch> {
  final _controller = TextEditingController();
  Timer? _timer;
  void _change(String text) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(
        const Duration(milliseconds: 250), () => widget.onChanged(text.trim()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onChanged: _change,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        onSubmitted: (text) {
          _timer?.cancel();
          widget.onChanged(text.trim());
          FocusScope.of(context).unfocus();
        },
        decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'Name, address or reference',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () {
                      _controller.clear();
                      _change('');
                    },
                    icon: const Icon(Icons.close))),
      );
}
