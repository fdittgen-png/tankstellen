import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeric input row used by the Add-Fill-Up form for the three required
/// quantities: liters, total cost, and odometer reading. Each instance is
/// a [TextFormField] with:
///
///   * a numeric keyboard that accepts decimals
///   * a digit/`.`/`,` filter so invalid characters are blocked at input
///     time instead of being caught by the validator after submit
///   * a label and prefix icon supplied by the caller
///   * the caller's [validator] (typically the screen's positive-number
///     validator)
///
/// Pulled out of `add_fill_up_screen.dart` so the screen's `build`
/// method drops the three nearly-identical inline blocks and so the
/// digit-filter / validator wiring can be exercised by widget tests in
/// isolation.
class FillUpNumericField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;

  const FillUpNumericField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}
