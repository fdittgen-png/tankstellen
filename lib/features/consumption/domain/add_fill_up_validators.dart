// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../l10n/app_localizations.dart';

/// Pure validators / parsers shared by the Add-Fill-up form (#563
/// extraction). Pulled out of `add_fill_up_screen.dart` so the rules
/// can be unit-tested without pumping a full widget tree, mirroring
/// the `charging_log_validators.dart` split landed for the Add-Charging
/// form in PR #1156.
///
/// Validators take a non-nullable [AppLocalizations] (#3162) — unit
/// tests drive them with the pure `lookupAppLocalizations` constructor.
class AddFillUpValidators {
  AddFillUpValidators._();

  /// Validates that [value] parses to a strictly positive number. Used
  /// for liters, total cost, and odometer fields — all three must be
  /// > 0 for a fill-up to make sense (you can't fill nothing, pay
  /// nothing, or have a zero-km odometer reading).
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

  /// Parses a double from a comma-or-dot decimal string. Throws if the
  /// string is unparseable — call only after validation has passed.
  static double parseDouble(String text) =>
      double.parse(text.replaceAll(',', '.'));
}
