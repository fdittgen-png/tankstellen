/// Pure helpers for the radius-alert create form (#563 phase:
/// radius_alert_create_sheet extract).
///
/// The bottom sheet itself is widget-heavy, but the validation rules
/// — "is this threshold a positive number?", "does this form have
/// enough state to save?" — are pure logic. Lifting them out keeps
/// the widget under the 300-LOC guideline and gives us cheap
/// unit-test coverage that does not need to spin up a `pumpApp`.
library;

/// Parses the threshold string the user typed into the price field.
///
/// Accepts comma decimals (`'1,499'`) the same way the user keypad
/// renders them on a German/French Android keyboard, normalises to a
/// `double`, and returns `null` for blank or unparseable input. The
/// returned value is *not* clamped to a positive range — that's the
/// caller's job (`canSaveRadiusAlertForm` handles it).
double? parseRadiusAlertThreshold(String raw) {
  final trimmed = raw.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

/// Returns `true` when the form has enough state to materialise a
/// [RadiusAlert]. Mirrors the legacy `_canSave` getter from the
/// pre-extract sheet:
///
/// * label must be non-blank,
/// * threshold must parse and be strictly positive,
/// * a center must be available — either GPS coordinates *or* a
///   non-blank postal code (the geocoder fills in the coordinates
///   later in #578 phase 3+).
bool canSaveRadiusAlertForm({
  required String label,
  required String thresholdRaw,
  required double? centerLat,
  required double? centerLng,
  required String postalCode,
}) {
  if (label.trim().isEmpty) return false;
  final threshold = parseRadiusAlertThreshold(thresholdRaw);
  if (threshold == null || threshold <= 0) return false;
  final hasGps = centerLat != null && centerLng != null;
  final hasPostal = postalCode.trim().isNotEmpty;
  return hasGps || hasPostal;
}

/// The center binding the user has chosen for the new alert.
///
/// This pairs the latitude/longitude (when known) with a
/// human-readable [source] caption so the UI can tell the user
/// *which* center is currently bound — "GPS", "Map location", or a
/// reverse-geocoded address. A `null` instance means no center is
/// bound yet.
class RadiusAlertCenterBinding {
  /// The latitude bound to the alert. `null` until either GPS
  /// resolves or the map picker returns a [LatLng].
  final double? lat;

  /// The longitude bound to the alert. `null` until either GPS
  /// resolves or the map picker returns a [LatLng].
  final double? lng;

  /// Human-readable caption for the bound center (e.g. `'GPS'`,
  /// `'Map location'`). The sheet renders this directly under the
  /// center buttons so the user knows which source is active.
  final String source;

  const RadiusAlertCenterBinding({
    required this.lat,
    required this.lng,
    required this.source,
  });

  /// Coordinates the persistence layer should store. Postal-code-only
  /// entries are parked at `(0, 0)` until the geocoder resolves them
  /// — see the legacy `_save` comment for context. Returning a
  /// 2-tuple keeps the call site readable on both branches.
  ({double lat, double lng}) coordinatesOrZero() {
    return (lat: lat ?? 0.0, lng: lng ?? 0.0);
  }
}
