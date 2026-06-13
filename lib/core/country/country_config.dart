// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/fuel_type.dart';
import 'country_bounding_box.dart';
import 'country_config_data_core.dart';
import 'country_config_data_extended.dart';

/// Configuration for each supported country.
/// Determines which services, fuel types, postal code formats,
/// and API key requirements apply.
class CountryConfig {
  final String code;            // ISO 3166-1 alpha-2: 'DE', 'FR', 'AT'
  final String name;            // Localized: 'Deutschland', 'France'
  final String flag;            // Emoji: '🇩🇪', '🇫🇷'
  final String currency;        // 'EUR', 'CHF'
  final String currencySymbol;  // '€', 'CHF'
  final String locale;          // 'de_DE', 'fr_FR'
  final int postalCodeLength;   // 5 (DE/FR), 4 (AT/CH/NL/BE)
  final String postalCodeRegex; // r'^\d{5}$'
  final String postalCodeLabel; // 'PLZ', 'Code postal'
  final bool requiresApiKey;    // true for Tankerkoenig, false for FR/AT
  final String? apiKeyRegistrationUrl;
  final String? apiProvider;    // 'Tankerkönig', 'Prix-Carburants'
  final String? attribution;
  final List<String> fuelTypes; // Display names for this country

  /// Typed fuel compatibility set (#699). Pickers across the app
  /// filter their options by this set so adding Italy's CNG or
  /// removing France's LPG flows through every dropdown in one place.
  /// Every OCM-covered country must include [FuelType.electric].
  final Set<FuelType> supportedFuelTypes;

  final String examplePostalCode;
  final String exampleCity;

  /// Distance unit convention for this country: 'km' or 'mi'.
  /// Defaults to metric km — override only for imperial-distance
  /// countries (GB road signs use miles, US, …).
  final String distanceUnit;

  /// Volume unit convention for this country: 'L' or 'gal'.
  /// Every country currently uses litres; imperial-gallon
  /// countries (US) will override.
  final String volumeUnit;

  /// Price-per-unit suffix to render after a fuel price value.
  /// Common values: '€/L', '£/L', 'p/L' (UK pence-per-litre),
  /// 'c/L' (AU cents-per-litre), '$/gal' (US).
  /// Defaults to '€/L' for the EUR-zone metric countries.
  final String pricePerUnitSuffix;

  /// Per-fuel overrides of [pricePerUnitSuffix] (#3198). Most fuels share
  /// the country-wide suffix; a fuel sold by a different physical unit
  /// overrides here — Argentina's GNC is priced per cubic metre
  /// (dollars per m³), not per litre. Read via [pricePerUnitSuffixFor].
  final Map<FuelType, String> pricePerUnitSuffixByFuel;

  /// Whether this country's station service runs against a verified
  /// price feed (#1828).
  ///
  /// `false` for a country whose service still targets an unverified
  /// best-guess endpoint. Such a country stays *registered* — a
  /// station id carrying its prefix still resolves — but is hidden
  /// from the user-facing country pickers (see [Countries.verified])
  /// so the app never advertises a country whose live prices are
  /// unproven. Flip to `true` once the endpoint is confirmed.
  final bool verified;

  const CountryConfig({
    required this.code,
    required this.name,
    required this.flag,
    this.currency = 'EUR',
    this.currencySymbol = '€',
    required this.locale,
    required this.postalCodeLength,
    required this.postalCodeRegex,
    required this.postalCodeLabel,
    this.requiresApiKey = false,
    this.apiKeyRegistrationUrl,
    this.apiProvider,
    this.attribution,
    this.fuelTypes = const ['E5', 'E10', 'Diesel'],
    this.supportedFuelTypes = const {
      FuelType.e5,
      FuelType.e10,
      FuelType.diesel,
      FuelType.electric,
    },
    this.examplePostalCode = '',
    this.exampleCity = '',
    this.distanceUnit = 'km',
    this.volumeUnit = 'L',
    this.pricePerUnitSuffix = '€/L',
    this.pricePerUnitSuffixByFuel = const {},
    this.verified = true,
  });

  /// The price-per-unit suffix for [fuelType]: the per-fuel override when
  /// one exists, else the country-wide [pricePerUnitSuffix]. A null
  /// [fuelType] (fuel not known at the call site) gets the country-wide
  /// suffix.
  String pricePerUnitSuffixFor(FuelType? fuelType) =>
      (fuelType == null ? null : pricePerUnitSuffixByFuel[fuelType]) ??
      pricePerUnitSuffix;
}

/// Registry of all supported countries + the station-id / locale / bbox
/// lookups over them.
///
/// #3296 — the per-country [CountryConfig] data rows were extracted into
/// `country_config_data_core.dart` (the original pre-v4.1.0 set) and
/// `country_config_data_extended.dart` (v4.1.0+). Each `Countries.<name>`
/// below is a `static const` alias of the matching `k<Name>` data const, so
/// every call site (`Countries.germany`, …) is unchanged; this class keeps the
/// `all` / `verified` / `byCode` / `fromLocale` / station-id resolution.
class Countries {
  Countries._();

  static const germany = kGermany;
  static const france = kFrance;
  static const austria = kAustria;
  static const spain = kSpain;
  static const italy = kItaly;
  static const denmark = kDenmark;
  static const argentina = kArgentina;
  // New countries (v4.1.0+).
  static const portugal = kPortugal;
  static const unitedKingdom = kUnitedKingdom;
  static const australia = kAustralia;
  static const slovenia = kSlovenia;
  static const mexico = kMexico;
  static const luxembourg = kLuxembourg;
  static const southKorea = kSouthKorea;
  static const chile = kChile;
  static const greece = kGreece;
  static const romania = kRomania;

  /// All registered countries, ordered for display.
  ///
  /// This is the source of truth for code that must resolve *every*
  /// registered country — station-id prefix → country, the
  /// registry-completeness assertion, geocoding scope. User-facing
  /// country pickers must iterate [verified] instead.
  static const all = [
    germany, france, austria, spain, italy, denmark, argentina,
    portugal, unitedKingdom, australia, mexico, luxembourg, slovenia,
    southKorea, chile, greece, romania,
  ];

  /// Countries safe to surface in the user-facing country pickers
  /// (#1828) — [all] minus any whose station service still targets an
  /// unverified best-guess endpoint ([CountryConfig.verified] false).
  /// Keeps the app from advertising a country whose live prices are
  /// unproven; a gated country stays in [all] so its data still
  /// resolves where it already exists.
  static final List<CountryConfig> verified =
      all.where((c) => c.verified).toList(growable: false);

  /// Find country by ISO code.
  /// Code → config lookup, built once from [all]. #2184 — byCode is on a
  /// per-station hot path (currency/locale resolution for favorites and
  /// cross-border rows), so an O(1) map beats the old linear scan.
  /// Case-sensitive on the canonical uppercase ISO code, exactly like the
  /// previous `c.code == code` scan.
  static final Map<String, CountryConfig> _byCode = {
    for (final c in all) c.code: c,
  };

  static CountryConfig? byCode(String code) => _byCode[code];

  /// Detect country from system locale.
  static CountryConfig fromLocale(String localeStr) {
    final code = localeStr.length >= 5
        ? localeStr.substring(3, 5).toUpperCase()
        : localeStr.toUpperCase();
    return byCode(code) ?? germany; // Default fallback
  }

  /// Maps a station id prefix to the country code it came from.
  ///
  /// Used by the Favorites list to render each row in its origin
  /// country's currency (see #514) — otherwise a UK station in a
  /// French profile would display \`£1.559\` as \`1,559 €\`.
  ///
  /// As of #753 every supported country emits prefixed ids — the
  /// previous "raw upstream id" exemptions for DE / FR / AT / ES / IT
  /// are gone. The widget tap path now derives the origin country from
  /// the prefix and routes [stationDetailProvider] to the matching
  /// [StationService], even when the user has switched the active
  /// profile to a different country.
  ///
  /// Known prefixes:
  /// - \`de-\` → DE (Germany Tankerkönig, #753)
  /// - \`fr-\` → FR (France Prix-Carburants, #753)
  /// - \`at-\` → AT (Austria E-Control, #753)
  /// - \`es-\` → ES (Spain MITECO Geoportal, #753)
  /// - \`it-\` → IT (Italy MIMIT/MISE, #753)
  /// - \`pt-\` → PT (Portugal DGEG, #503)
  /// - \`uk-\` → GB (UK CMA Fuel Finder, #499)
  /// - \`au-\` → AU (Australia FuelCheck)
  /// - \`mx-\` → MX (Mexico CRE)
  /// - \`ar-\` → AR (Argentina)
  /// - \`ok-\` / \`shell-\` → DK (Denmark — two retailer-specific feeds)
  /// - \`lu-\` → LU (Luxembourg regulated prices, #574)
  /// - \`si-\` → SI (Slovenia goriva.si, #575)
  /// - \`kr-\` → KR (South Korea OPINET / KNOC, #597)
  /// - \`cl-\` → CL (Chile CNE Bencina en Línea, #596)
  /// - \`gr-\` → GR (Greece Paratiritirio Timon, #576)
  /// - \`ro-\` → RO (Romania Monitorul Prețurilor, #577)
  /// - \`demo-\` → null (demo service, no real country)
  static const Map<String, String> _stationIdPrefixToCountry = {
    'de-': 'DE',
    'fr-': 'FR',
    'at-': 'AT',
    'es-': 'ES',
    'it-': 'IT',
    'pt-': 'PT',
    'uk-': 'GB',
    'au-': 'AU',
    'mx-': 'MX',
    'ar-': 'AR',
    'ok-': 'DK',
    'shell-': 'DK',
    'lu-': 'LU',
    'si-': 'SI',
    'kr-': 'KR',
    'cl-': 'CL',
    'gr-': 'GR',
    'ro-': 'RO',
  };

  /// Returns the ISO country code inferred from a station id's prefix,
  /// or \`null\` when the id has no recognised country prefix.
  static String? countryCodeForStationId(String? stationId) {
    if (stationId == null || stationId.isEmpty) return null;
    for (final entry in _stationIdPrefixToCountry.entries) {
      if (stationId.startsWith(entry.key)) return entry.value;
    }
    return null;
  }

  /// Returns the [CountryConfig] inferred from a station id's prefix,
  /// or \`null\` when no match is found or the prefix's country is not
  /// part of [all] (e.g. \`BE\` / \`LU\` — no full config yet).
  static CountryConfig? countryForStationId(String? stationId) {
    final code = countryCodeForStationId(stationId);
    if (code == null) return null;
    return byCode(code);
  }

  /// Resolves the origin country of a station using:
  ///
  /// 1. The id prefix ([countryForStationId]) — fast, canonical,
  ///    works for new search results from services that prefix their
  ///    ids (PT, GB, MX, AR, DK retailer-specific, AU, demo).
  /// 2. A bounding-box match on `lat` / `lng` when the prefix misses
  ///    — fixes #516 for services that emit raw upstream ids (DE
  ///    Tankerkoenig UUID, FR Prix-Carburants numeric id, AT
  ///    E-Control, ES MITECO, IT MISE) and repairs legacy favorites
  ///    saved before the prefix scheme existed.
  ///
  /// Returns \`null\` only when neither path resolves — the caller is
  /// expected to fall back to the globally-set active profile
  /// currency in that case.
  ///
  /// The prefix always wins over the bounding box. This is
  /// deliberate: a service that explicitly tags its ids with a
  /// country code is a stronger signal than a geometric hit test,
  /// and it keeps existing (#514) behaviour unchanged for the cases
  /// we already covered.
  static CountryConfig? countryForStation({
    required String? id,
    required double lat,
    required double lng,
  }) {
    final byPrefix = countryForStationId(id);
    if (byPrefix != null) return byPrefix;
    final bboxCode = countryCodeFromLatLng(lat, lng);
    if (bboxCode == null) return null;
    return byCode(bboxCode);
  }
}
