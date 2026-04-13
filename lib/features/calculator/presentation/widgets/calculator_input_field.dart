import 'package:flutter/material.dart';

/// Numeric text field used by the fuel cost calculator.
///
/// Wraps a [TextField] with decimal keyboard, outlined border, and a parse
/// callback that forwards the parsed value (0 on invalid input) to the
/// caller — the calculator's three inputs are structurally identical except
/// for label, hint, icon, and the notifier method they forward to.
class CalculatorInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData icon;
  final ValueChanged<double> onParsed;

  const CalculatorInputField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.icon,
    required this.onParsed,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) => onParsed(double.tryParse(value) ?? 0),
    );
  }
}
