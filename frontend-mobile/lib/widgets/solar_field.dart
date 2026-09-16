import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/solar_theme.dart';

// Keep decimal input intact, including incomplete values while typing.
final solarDecimalFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        RegExp(r'^\d*\.?\d*$').hasMatch(newValue.text) ? newValue : oldValue);

class SolarField extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final bool obscureText;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  const SolarField(
      {super.key,
      required this.controller,
      required this.decoration,
      this.keyboardType,
      this.style,
      this.obscureText = false,
      this.maxLength,
      this.autofillHints,
      this.validator,
      this.inputFormatters,
      this.textInputAction = TextInputAction.next,
      this.onFieldSubmitted});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: decoration.copyWith(
          border: Theme.of(context).inputDecorationTheme.border,
          enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
          focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
        ),
        keyboardType: keyboardType,
        style: style,
        obscureText: obscureText,
        maxLength: maxLength,
        autofillHints: autofillHints,
        validator: validator,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        errorBuilder: (context, message) =>
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, size: 16, color: SolarColors.error),
          const SizedBox(width: 6),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: SolarColors.error, fontSize: 12, height: 1.4))),
        ]),
      ));
}
