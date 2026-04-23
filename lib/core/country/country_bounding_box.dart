/// Geographic bounding boxes for all supported countries.
///
/// Used to validate that geocoded coordinates actually fall within the
/// expected country. Prevents silently returning results for the wrong
/// area when Nominatim returns inaccurate coordinates.
///
/// Boxes are intentionally generous (1-2 degree margin) to account for
/// overseas territories, islands, and border regions.
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

/// Bounding boxes for all supported countries, keyed by ISO 3166-1 alpha-2 code.
///
/// Sources: OpenStreetMap / Natural Earth bounding boxes with generous margins.
const countryBoundingBoxes = <String, CountryBoundingBox>{
  // Germany: lat 47.27–55.06, lng 5.87–15.04 (with margin)
  'DE': CountryBoundingBox(minLat: 47.0, maxLat: 55.5, minLng: 5.5, maxLng: 15.5),

  // France (mainland): lat 41.33–51.12, lng -5.14–9.56 (with margin)
  // Excludes overseas territories (Réunion, Guadeloupe, etc.)
  'FR': CountryBoundingBox(minLat: 41.0, maxLat: 51.5, minLng: -5.5, maxLng: 10.0),

  // Austria: lat 46.37–49.02, lng 9.53–17.16 (with margin)
  'AT': CountryBoundingBox(minLat: 46.0, maxLat: 49.5, minLng: 9.0, maxLng: 17.5),

  // Spain (mainland + Balearic + Canary): lat 27.64–43.79, lng -18.17–4.33 (with margin)
  'ES': CountryBoundingBox(minLat: 27.0, maxLat: 44.0, minLng: -19.0, maxLng: 5.0),

  // Italy (mainland + Sicily + Sardinia): lat 35.49–47.09, lng 6.63–18.52 (with margin)
  'IT': CountryBoundingBox(minLat: 35.0, maxLat: 47.5, minLng: 6.0, maxLng: 19.0),

  // Denmark (mainland + Greenland excluded): lat 54.56–57.75, lng 8.07–15.20 (with margin)
  'DK': CountryBoundingBox(minLat: 54.0, maxLat: 58.0, minLng: 7.5, maxLng: 15.5),

  // Argentina: lat -55.06–-21.78, lng -73.56–-53.64 (with margin)
  'AR': CountryBoundingBox(minLat: -56.0, maxLat: -21.0, minLng: -74.0, maxLng: -53.0),

  // Portugal (mainland + Azores + Madeira): lat 32.40–42.15, lng -31.27–-6.19 (with margin)
  'PT': CountryBoundingBox(minLat: 32.0, maxLat: 42.5, minLng: -32.0, maxLng: -6.0),

  // United Kingdom: lat 49.86–60.86, lng -8.65–1.77 (with margin)
  'GB': CountryBoundingBox(minLat: 49.5, maxLat: 61.0, minLng: -9.0, maxLng: 2.0),

  // Australia: lat -43.64–-10.06, lng 112.92–153.64 (with margin)
  'AU': CountryBoundingBox(minLat: -44.0, maxLat: -9.5, minLng: 112.5, maxLng: 154.0),

  // Mexico: lat 14.39–32.72, lng -118.37–-86.71 (with margin)
  'MX': CountryBoundingBox(minLat: 14.0, maxLat: 33.0, minLng: -119.0, maxLng: -86.0),

  // Luxembourg: lat 49.45–50.18, lng 5.74–6.53 (with margin).
  // Very tight box — LU is ~82 km north-south, ~57 km east-west; keeping
  // the margin modest so BE/FR/DE neighbours don't bleed into LU matches.
  'LU': CountryBoundingBox(minLat: 49.4, maxLat: 50.25, minLng: 5.7, maxLng: 6.55),

  // Slovenia: lat 45.42–46.88, lng 13.38–16.61 (with margin). Tight
  // box — Slovenia is small and surrounded by IT / AT / HR so an
  // over-generous margin would shadow those neighbours. See #575.
  'SI': CountryBoundingBox(minLat: 45.3, maxLat: 47.0, minLng: 13.3, maxLng: 16.7),

  // South Korea (mainland + Jeju): lat 33.10–38.61, lng 124.61–131.87
  // (with margin). No overlap with any other registered country. See #597.
  'KR': CountryBoundingBox(minLat: 33.0, maxLat: 39.0, minLng: 124.0, maxLng: 131.0),

  // Chile: lat -56.00 (Tierra del Fuego) – -17.50 (Arica), lng -75.80 –
  // -66.40 (mainland, with a margin large enough for Isla de Chiloé and
  // the Atacama coast but kept narrow on the east so Chile's tight west-
  // coast strip does not shadow Argentina's much larger box. See #596.
  'CL': CountryBoundingBox(minLat: -56.5, maxLat: -17.0, minLng: -77.0, maxLng: -66.0),

  // Greece: lat 34.50 (southern Crete) – 41.80 (north Macedonia border),
  // lng 19.00 (Corfu / Ionian) – 28.50 (eastern Dodecanese / Rhodes).
  // The eastern edge is deliberately pulled in from the geographic
  // limit (~29.6 for Kastellorizo) so Istanbul (41.01, 28.98) is
  // NOT falsely attributed to GR. Kastellorizo (~500 residents) is
  // the only Greek territory lost; every populated island including
  // Rhodes (36.43, 28.22) and Kos stays inside the box. Turkey is
  // not currently in the registry, so a point that falls between the
  // bbox and the Turkish border simply returns `null` — the caller
  // uses that as the signal to fall back to the active profile.
  // See #576.
  'GR': CountryBoundingBox(minLat: 34.5, maxLat: 41.8, minLng: 19.0, maxLng: 28.5),

  // Romania: lat 43.50 (southern Danube border) – 48.50 (northern
  // Maramureș), lng 20.00 (western Banat) – 29.80 (Dobrogea / Black
  // Sea coast). No neighbour conflicts — HU, BG, UA, RS, and MD are
  // not currently in the registry, so misattribution risk is zero at
  // the bbox layer. See #577.
  'RO': CountryBoundingBox(minLat: 43.5, maxLat: 48.5, minLng: 20.0, maxLng: 29.8),
};

/// Deterministic order used by [countryCodeFromLatLng] to walk
/// [countryBoundingBoxes]. Small / island / coastal countries come
/// first so their tight boxes are not shadowed by larger neighbours
/// whose boxes incidentally overlap them (e.g. `PT`'s Iberian area
/// is entirely inside `ES`'s box, so we must test `PT` first).
///
/// Cross-currency border cases (#516) were the primary motivation —
/// getting a station misattributed between two euro-zone countries
/// is invisible at the currency-symbol layer, but a UK/FR or DE/DK
/// mix-up would flip the rendered symbol.
///
/// Ordering rationale:
/// - `PT` first → its tight box is entirely inside `ES`'s generous
///   one; Lisbon / Porto must not fall through to ES.
/// - `GB` / island next → no continental overlap.
/// - `DK` before `DE` → Copenhagen's lat sits inside DE's box.
/// - `FR` before `DE` → Alsace (Strasbourg) sits inside both.
/// - Continental EU countries last (DE) so stations outside every
///   tighter box still get attributed to something European.
/// - Non-EU countries last — they don't overlap anyone.
const List<String> _bboxLookupOrder = [
  'PT',
  'GB',
  'DK',
  // LU sits inside the generous FR and DE boxes (49.6/6.1) — must be
  // tested first so Luxembourg-Ville doesn't fall through to France.
  'LU',
  // SI first among Alpine neighbours — its tight box is entirely inside
  // both AT and IT's generous boxes (#575). A Ljubljana station (lat
  // 46.05 / lng 14.50) would otherwise fall through to AT.
  'SI',
  'AT',
  'FR',
  'IT',
  'ES',
  'DE',
  'MX',
  // CL before AR: Chile's narrow strip sits inside AR's generous
  // longitude range along the cordillera. A Santiago station
  // (-33.45 / -70.67) or a Punta Arenas station (-53.16 / -70.91)
  // would otherwise fall through to AR. See #596.
  'CL',
  'AR',
  'AU',
  'KR',
  // GR last — no overlap with any currently-registered country's box,
  // so placement in the lookup order is inconsequential. #576
  'GR',
  // RO last — no overlap with any currently-registered country's box
  // (HU / BG / UA / RS / MD are not registered). #577
  'RO',
];

/// Returns the ISO country code whose bounding box contains the
/// given point, or `null` when no box matches.
///
/// Used by `Countries.countryForStation` (#516) as a fallback when a
/// station id has no country-specific prefix — every supported
/// service still emits `lat` / `lng`, so the station can still be
/// attributed to a country via its coordinates even if the id is a
/// bare upstream identifier (FR Prix-Carburants, DE Tankerkoenig,
/// AT E-Control, ES MITECO, IT MISE all fall into this case).
String? countryCodeFromLatLng(double lat, double lng) {
  for (final code in _bboxLookupOrder) {
    final box = countryBoundingBoxes[code];
    if (box == null) continue;
    if (box.contains(lat, lng)) return code;
  }
  return null;
}
