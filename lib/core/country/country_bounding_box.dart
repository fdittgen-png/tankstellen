import '../services/country_service_registry.dart';

/// Geographic bounding box for a country.
///
/// Used to validate that geocoded coordinates actually fall within the
/// expected country and to infer a station's origin country from its
/// coordinates when the station id has no country prefix (#516).
///
/// Boxes intentionally include a 1-2 degree margin to account for
/// overseas territories, islands, and border regions.
///
/// Per-country boxes live on [CountryServiceEntry.boundingBox] in
/// [CountryServiceRegistry.entries] — a single source of truth that
/// also encapsulates fuel types, error source, and the service
/// factory (#1111).
class CountryBoundingBox {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const CountryBoundingBox({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  /// Returns true if the given coordinates fall within this bounding box.
  bool contains(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  @override
  String toString() =>
      'CountryBoundingBox(lat: $minLat..$maxLat, lng: $minLng..$maxLng)';
}

/// Backwards-compatible map view of registered country bounding boxes,
/// keyed by ISO 3166-1 alpha-2 code.
///
/// Reads from [CountryServiceRegistry.entries] — adding a new country
/// only requires appending to the registry, never editing this file
/// (#1111). Existing call sites that look up by code (e.g.
/// `countryBoundingBoxes['DE']`) keep working unchanged.
Map<String, CountryBoundingBox> get countryBoundingBoxes => {
      for (final entry in CountryServiceRegistry.entries)
        entry.countryCode: entry.boundingBox,
    };

/// Returns the ISO country code whose bounding box contains the given
/// point, or `null` when no box matches.
///
/// Used by `Countries.countryForStation` (#516) as a fallback when a
/// station id has no country-specific prefix — every supported service
/// still emits `lat` / `lng`, so the station can still be attributed
/// to a country via its coordinates even if the id is a bare upstream
/// identifier (FR Prix-Carburants, DE Tankerkoenig, AT E-Control,
/// ES MITECO, IT MISE all fall into this case).
///
/// Lookup-order matters: [CountryServiceRegistry.entries] is intentionally
/// ordered so tighter / island / coastal boxes come first, before the
/// larger boxes that incidentally overlap them. See the doc on
/// [CountryServiceRegistry.entries] for the full rationale.
String? countryCodeFromLatLng(double lat, double lng) =>
    CountryServiceRegistry.entryByLatLng(lat, lng)?.countryCode;
