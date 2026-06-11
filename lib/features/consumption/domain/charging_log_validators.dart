// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../l10n/app_localizations.dart';

/// Pure validators / parsers shared by the Add-Charging-Log form
/// (#582 phase 2). Pulled out of `add_charging_log_screen.dart` so the
/// rules can be unit-tested without pumping a full widget tree.
///
/// Validators take a non-nullable [AppLocalizations] (#3162) — unit
/// tests drive them with the pure `lookupAppLocalizations` constructor.
class ChargingLogValidators {
  ChargingLogValidators._();

  /// Validates that [value] parses to a strictly positive number. Used
  /// for kWh, cost, and odometer fields — all three must be > 0 for a
  /// charging log to make sense (you can't charge nothing, pay
  /// nothing, or have a zero-km odometer).
  static String? positiveNumber(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.fieldRequired;
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return l.fieldInvalidNumber;
    }
    return null;
  }

  /// Validates that [value] parses to a non-negative integer. Used for
  /// the charge-time-minutes field — 0 is allowed (slow chargers can
  /// log a zero-minute session if the user hasn't measured it).
  static String? nonNegativeInt(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.fieldRequired;
    }
    final parsed = int.tryParse(value.replaceAll(',', '.').split('.').first);
    if (parsed == null || parsed < 0) {
      return l.fieldInvalidNumber;
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
