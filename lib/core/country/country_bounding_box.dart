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
};
