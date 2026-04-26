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
  /// rules are: a non-empty trimmed label, a parseable strictly
  /// positive threshold, AND a center — either GPS coordinates OR a
  /// non-empty postal code (the phase-3 worker geocodes postal-only
  /// entries later).
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
    final hasGps = centerLat != null && centerLng != null;
    final hasPostal = postalCode.trim().isNotEmpty;
    return hasGps || hasPostal;
  }
}
