import '../../../l10n/app_localizations.dart';

/// Pure validators / parsers shared by the Add-Fill-up form (#563
/// extraction). Pulled out of `add_fill_up_screen.dart` so the rules
/// can be unit-tested without pumping a full widget tree, mirroring
/// the `charging_log_validators.dart` split landed for the Add-Charging
/// form in PR #1156.
///
/// All validators accept `null` localizations for tests / golden
/// fallbacks and degrade to English defaults — the same pattern used
/// elsewhere in the codebase (see `AppLocalizations.of(context)?.x ??
/// 'Fallback'`).
class AddFillUpValidators {
  AddFillUpValidators._();

  /// Validates that [value] parses to a strictly positive number. Used
  /// for liters, total cost, and odometer fields — all three must be
  /// > 0 for a fill-up to make sense (you can't fill nothing, pay
  /// nothing, or have a zero-km odometer reading).
  static String? positiveNumber(String? value, AppLocalizations? l) {
    if (value == null || value.trim().isEmpty) {
      return l?.fieldRequired ?? 'Required';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return l?.fieldInvalidNumber ?? 'Invalid number';
    }
    return null;
  }

  /// Parses a double from a comma-or-dot decimal string. Throws if the
  /// string is unparseable — call only after validation has passed.
  static double parseDouble(String text) =>
      double.parse(text.replaceAll(',', '.'));
}
