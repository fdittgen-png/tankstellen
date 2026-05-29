// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Pure validators / parsers for the Radius Alert create form (#563).
///
/// Pulled out of `radius_alert_create_sheet.dart` so the rules can be
/// unit-tested without pumping a full widget tree. Same pattern as
/// `ChargingLogValidators` from #1156 — keep parsing comma-or-dot
/// decimal strings and the "can save" predicate in one auditable place.
class RadiusAlertValidators {
  RadiusAlertValidators._();

  /// Parses the threshold field's raw text into a non-null double, or
  /// `null` if the input is empty / unparseable. Accepts both `,` and
  /// `.` as decimal separators because the form is bilingual and
  /// continental European keyboards default to a comma.
  static double? parseThreshold(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Predicate that mirrors the "Save" button's enabled state. The
  /// rules are: a non-empty trimmed label, a parseable strictly positive
  /// threshold, AND real GPS coordinates for the center.
  ///
  /// #2211 — a real center is now REQUIRED. Postal-code-only entries used
  /// to save with a (0,0) center and never matched anything (no
  /// geocoding step exists), so they were silently dead. [postalCode] is
  /// still accepted (it's surfaced in the label) but no longer enables
  /// save on its own; the user must pick a location or use GPS.
  static bool canSave({
    required String label,
    required String thresholdRaw,
    required double? centerLat,
    required double? centerLng,
    required String postalCode,
  }) {
    if (label.trim().isEmpty) return false;
    final threshold = parseThreshold(thresholdRaw);
    if (threshold == null || threshold <= 0) return false;
    return centerLat != null && centerLng != null;
  }
}
