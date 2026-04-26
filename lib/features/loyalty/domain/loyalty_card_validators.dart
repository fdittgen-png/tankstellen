/// Pure-domain helpers for the fuel-club card add/edit form (#1120).
///
/// Extracted from `loyalty_settings_screen.dart` so the parsing and
/// validation rules can be exercised by plain Dart unit tests without
/// pumping a widget tree.
library;

/// Parse the user's discount input. Accepts both '.' and ',' as the
/// decimal separator so a German/French keyboard layout works without
/// nagging the user about the "right" character.
///
/// Returns `null` for `null`, an empty/whitespace-only input, or a
/// string that does not parse as a number after the comma-to-dot
/// substitution. The caller decides whether `null` means "invalid"
/// (Save short-circuits) or "still being typed" (no error yet).
double? parseDiscountInput(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed.replaceAll(',', '.'));
}

/// Whether [raw] is a valid per-litre discount: a positive number
/// (strictly `> 0`) when parsed via [parseDiscountInput].
///
/// Centralising the rule here keeps the form validator and any
/// future bulk-import / sync layer consistent.
bool isValidDiscountInput(String? raw) {
  final parsed = parseDiscountInput(raw);
  return parsed != null && parsed > 0;
}
