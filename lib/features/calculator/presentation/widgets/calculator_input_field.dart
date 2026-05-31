// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// Numeric text field used by the fuel cost calculator.
///
/// Wraps a [TextField] with decimal keyboard, outlined border, and a parse
/// callback that forwards the parsed value (0 on invalid input) to the
/// caller — the calculator's three inputs are structurally identical except
/// for label, hint, icon, and the notifier method they forward to.
///
/// [action] is an optional trailing widget rendered under the field
/// (the redesign's "use mine" `ActionChip`, #2543). It's hidden — and
/// the gap with it — when null, so existing call sites are unaffected.
class CalculatorInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData icon;
  final ValueChanged<double> onParsed;

  /// Optional trailing widget rendered below the field, left-aligned —
  /// used by the redesign for the per-field "use mine" prefill chip.
  final Widget? action;

  const CalculatorInputField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.icon,
    required this.onParsed,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
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

    if (action == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        const SizedBox(height: Spacing.sm),
        Align(alignment: Alignment.centerLeft, child: action),
      ],
    );
  }
}
