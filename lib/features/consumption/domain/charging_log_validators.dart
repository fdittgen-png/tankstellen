import '../../../l10n/app_localizations.dart';

/// Pure validators / parsers shared by the Add-Charging-Log form
/// (#582 phase 2). Pulled out of `add_charging_log_screen.dart` so the
/// rules can be unit-tested without pumping a full widget tree.
///
/// All validators accept `null` localizations for tests / golden
/// fallbacks and degrade to English defaults — the same pattern used
/// elsewhere in the codebase (see `AppLocalizations.of(context)?.x ??
/// 'Fallback'`).
class ChargingLogValidators {
  ChargingLogValidators._();

  /// Validates that [value] parses to a strictly positive number. Used
  /// for kWh, cost, and odometer fields — all three must be > 0 for a
  /// charging log to make sense (you can't charge nothing, pay
  /// nothing, or have a zero-km odometer).
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

  /// Validates that [value] parses to a non-negative integer. Used for
  /// the charge-time-minutes field — 0 is allowed (slow chargers can
  /// log a zero-minute session if the user hasn't measured it).
  static String? nonNegativeInt(String? value, AppLocalizations? l) {
    if (value == null || value.trim().isEmpty) {
      return l?.fieldRequired ?? 'Required';
    }
    final parsed = int.tryParse(value.replaceAll(',', '.').split('.').first);
    if (parsed == null || parsed < 0) {
      return l?.fieldInvalidNumber ?? 'Invalid number';
    }
    return null;
  }

  /// Parses a double from a comma-or-dot decimal string. Throws if the
  /// string is unparseable — call only after validation has passed.
  static double parseDouble(String text) =>
      double.parse(text.replaceAll(',', '.'));

  /// Parses an int from a comma-or-dot decimal string (truncates the
  /// fractional part). Throws if the leading numeric is unparseable —
  /// call only after validation has passed.
  static int parseInt(String text) =>
      int.parse(text.replaceAll(',', '.').split('.').first);
}
