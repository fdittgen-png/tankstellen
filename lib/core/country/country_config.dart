import '../../features/search/domain/entities/fuel_type.dart';
import 'country_bounding_box.dart';

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

  const CountryConfig({
    required this.code,
    required this.name,
    required this.flag,
    this.currency = 'EUR',
    this.currencySymbol = '\u20ac',
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
    this.pricePerUnitSuffix = '\u20ac/L',
  });
}

class Countries {
  Countries._();

  static const germany = CountryConfig(
    code: 'DE',
    name: 'Deutschland',
    flag: '\u{1F1E9}\u{1F1EA}',
    locale: 'de_DE',
    postalCodeLength: 5,
    postalCodeRegex: r'^\d{5}$',
    postalCodeLabel: 'PLZ',
    requiresApiKey: true,
    apiKeyRegistrationUrl: 'https://creativecommons.tankerkoenig.de/',
    apiProvider: 'Tankerkönig',
    attribution: 'Daten von Tankerkoenig.de (CC BY 4.0)',
    fuelTypes: ['Super E5', 'Super E10', 'Diesel'],
    examplePostalCode: '10115',
    exampleCity: 'Berlin',
  );

  static const france = CountryConfig(
    code: 'FR',
    name: 'France',
    flag: '\u{1F1EB}\u{1F1F7}',
    locale: 'fr_FR',
    postalCodeLength: 5,
    postalCodeRegex: r'^\d{5}$',
    postalCodeLabel: 'Code postal',
    requiresApiKey: false,
    apiProvider: 'Prix-Carburants (gouv.fr)',
    attribution: 'Données: prix-carburants.gouv.fr',
    fuelTypes: ['SP95', 'SP98', 'E10', 'Gazole', 'E85', 'GPLc'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e10,
      FuelType.e98,
      FuelType.diesel,
      FuelType.e85,
      FuelType.lpg,
      FuelType.electric,
    },
    examplePostalCode: '75001',
    exampleCity: 'Lyon',
  );

  static const austria = CountryConfig(
    code: 'AT',
    name: 'Österreich',
    flag: '\u{1F1E6}\u{1F1F9}',
    locale: 'de_AT',
    postalCodeLength: 4,
    postalCodeRegex: r'^\d{4}$',
    postalCodeLabel: 'PLZ',
    requiresApiKey: false,
    apiProvider: 'E-Control Spritpreisrechner',
    attribution: 'Daten von E-Control (spritpreisrechner.at)',
    fuelTypes: ['Super 95', 'Super 95 E10', 'Diesel'],
    examplePostalCode: '1010',
    exampleCity: 'Wien',
  );

  static const spain = CountryConfig(
    code: 'ES',
    name: 'España',
    flag: '\u{1F1EA}\u{1F1F8}',
    locale: 'es_ES',
    postalCodeLength: 5,
    postalCodeRegex: r'^\d{5}$',
    postalCodeLabel: 'Código postal',
    requiresApiKey: false,
    apiProvider: 'Geoportal Gasolineras (MITECO)',
    attribution: 'Datos: geoportalgasolineras.es',
    fuelTypes: ['Gasolina 95', 'Gasolina 98', 'Gasóleo A', 'GLP'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e10,
      FuelType.e98,
      FuelType.diesel,
      FuelType.dieselPremium,
      FuelType.lpg,
      FuelType.electric,
    },
    examplePostalCode: '28001',
    exampleCity: 'Madrid',
  );

  static const italy = CountryConfig(
    code: 'IT',
    name: 'Italia',
    flag: '\u{1F1EE}\u{1F1F9}',
    locale: 'it_IT',
    postalCodeLength: 5,
    postalCodeRegex: r'^\d{5}$',
    postalCodeLabel: 'CAP',
    requiresApiKey: false,
    apiProvider: 'Osservaprezzi (MISE)',
    attribution: 'Dati: osservaprezzi.mise.gov.it',
    fuelTypes: ['Benzina', 'Gasolio', 'GPL', 'Metano'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.diesel,
      FuelType.lpg,
      FuelType.cng,
      FuelType.electric,
    },
    examplePostalCode: '00100',
    exampleCity: 'Roma',
  );

  static const denmark = CountryConfig(
    code: 'DK',
    name: 'Danmark',
    flag: '\u{1F1E9}\u{1F1F0}',
    currency: 'DKK',
    currencySymbol: 'kr',
    locale: 'da_DK',
    postalCodeLength: 4,
    postalCodeRegex: r'^\d{4}$',
    postalCodeLabel: 'Postnummer',
    requiresApiKey: false,
    apiProvider: 'OK / Shell / Q8',
    attribution: 'Data: ok.dk, shell.dk, q8.dk',
    fuelTypes: ['Blyfri 95', 'Diesel'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.diesel,
      FuelType.electric,
    },
    examplePostalCode: '1000',
    exampleCity: 'København',
    pricePerUnitSuffix: 'kr/L',
  );

  static const argentina = CountryConfig(
    code: 'AR',
    name: 'Argentina',
    flag: '\u{1F1E6}\u{1F1F7}',
    currency: 'ARS',
    currencySymbol: '\$',
    locale: 'es_AR',
    postalCodeLength: 4,
    postalCodeRegex: r'^\d{4}$',
    postalCodeLabel: 'Código postal',
    requiresApiKey: false,
    apiProvider: 'Secretaría de Energía',
    attribution: 'Datos: datos.energia.gob.ar',
    fuelTypes: ['Nafta', 'Gas Oil', 'GNC'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.diesel,
      FuelType.cng,
      FuelType.electric,
    },
    examplePostalCode: '1000',
    exampleCity: 'Buenos Aires',
    pricePerUnitSuffix: '\$/L',
  );

  // ── New countries (v4.1.0) ──

  static const portugal = CountryConfig(
    code: 'PT',
    name: 'Portugal',
    flag: '\u{1F1F5}\u{1F1F9}',
    locale: 'pt_PT',
    postalCodeLength: 4,
    postalCodeRegex: r'^\d{4}(-\d{3})?$',
    postalCodeLabel: 'Código postal',
    apiProvider: 'DGEG',
    attribution: 'Dados: DGEG (dgeg.gov.pt)',
    fuelTypes: ['Gasolina 95', 'Gasolina 98', 'Gasóleo', 'GPL Auto'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e98,
      FuelType.diesel,
      FuelType.lpg,
      FuelType.electric,
    },
    examplePostalCode: '1000',
    exampleCity: 'Lisboa',
  );

  static const unitedKingdom = CountryConfig(
    code: 'GB',
    name: 'United Kingdom',
    flag: '\u{1F1EC}\u{1F1E7}',
    currency: 'GBP',
    currencySymbol: '\u00a3',
    locale: 'en_GB',
    postalCodeLength: 7,
    postalCodeRegex: r'^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$',
    postalCodeLabel: 'Postcode',
    apiProvider: 'CMA Fuel Finder',
    attribution: 'Data: Competition and Markets Authority',
    fuelTypes: ['Unleaded', 'Super Unleaded', 'Diesel', 'Premium Diesel'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e98,
      FuelType.diesel,
      FuelType.dieselPremium,
      FuelType.electric,
    },
    examplePostalCode: 'SW1A 1AA',
    exampleCity: 'London',
    // UK road signs and speedometers use miles; fuel is still sold by
    // the litre so volume stays 'L'. Price convention is pence-per-
    // litre ("p/L") on forecourt signage.
    distanceUnit: 'mi',
    pricePerUnitSuffix: 'p/L',
  );

  static const australia = CountryConfig(
    code: 'AU',
    name: 'Australia',
    flag: '\u{1F1E6}\u{1F1FA}',
    currency: 'AUD',
    currencySymbol: '\u0024',
    locale: 'en_AU',
    postalCodeLength: 4,
    postalCodeRegex: r'^\d{4}$',
    postalCodeLabel: 'Postcode',
    apiProvider: 'FuelCheck NSW',
    attribution: 'Data: NSW Government FuelCheck',
    fuelTypes: ['Unleaded 91', 'Unleaded 95', 'Unleaded 98', 'Diesel', 'LPG'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e10,
      FuelType.e98,
      FuelType.diesel,
      FuelType.lpg,
      FuelType.electric,
    },
    examplePostalCode: '2000',
    exampleCity: 'Sydney',
    // AU forecourts quote cents-per-litre on signage.
    pricePerUnitSuffix: 'c/L',
  );

  static const slovenia = CountryConfig(
    code: 'SI',
    name: 'Slovenija',
    flag: '\u{1F1F8}\u{1F1EE}',
    locale: 'sl_SI',
    postalCodeLength: 4,
    postalCodeRegex: r'^\d{4}$',
    postalCodeLabel: 'Poštna številka',
    requiresApiKey: false,
    apiProvider: 'goriva.si (gov.si)',
    attribution: 'Podatki: goriva.si / Ministrstvo za gospodarstvo',
    fuelTypes: ['NMB-95', 'NMB-100', 'Dizel', 'Dizel Premium', 'LPG'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e10,
      FuelType.e98,
      FuelType.diesel,
      FuelType.dieselPremium,
      FuelType.lpg,
      FuelType.cng,
      FuelType.electric,
    },
    examplePostalCode: '1000',
    exampleCity: 'Ljubljana',
  );

  static const mexico = CountryConfig(
    code: 'MX',
    name: 'México',
    flag: '\u{1F1F2}\u{1F1FD}',
    currency: 'MXN',
    currencySymbol: '\u0024',
    locale: 'es_MX',
    postalCodeLength: 5,
    postalCodeRegex: r'^\d{5}$',
    postalCodeLabel: 'Código postal',
    apiProvider: 'CRE / datos.gob.mx',
    attribution: 'Datos: Comisión Reguladora de Energía',
    fuelTypes: ['Regular', 'Premium', 'Diesel'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e98,
      FuelType.diesel,
      FuelType.electric,
    },
    examplePostalCode: '06600',
    exampleCity: 'Ciudad de México',
    pricePerUnitSuffix: '\$/L',
  );

  /// Luxembourg has government-regulated fuel prices — uniform nationally
  /// by ministerial arrêté, with no station-level variance. See
  /// `LuxembourgStationService` for the uniform-price model.
  static const luxembourg = CountryConfig(
    code: 'LU',
    name: 'Luxembourg',
    flag: '\u{1F1F1}\u{1F1FA}',
    locale: 'fr_LU',
    postalCodeLength: 4,
    postalCodeRegex: r'^\d{4}$',
    postalCodeLabel: 'Code postal',
    apiProvider: 'Ministère de l\'Économie (LU)',
    attribution: 'Prix réglementés — gouvernement.lu',
    fuelTypes: ['Sans Plomb 95', 'Sans Plomb 98', 'Diesel', 'LPG'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e10,
      FuelType.e98,
      FuelType.diesel,
      FuelType.lpg,
      FuelType.electric,
    },
    examplePostalCode: '1009',
    exampleCity: 'Luxembourg',
  );

  /// South Korea — OPINET (Korea National Oil Corporation) REST API
  /// (#597). ~14 000 stations nationwide; gasoline, premium gasoline,
  /// diesel, LPG (kerosene published but unmapped until we add a
  /// FuelType enum for it). Prices are in KRW per litre (integer).
  static const southKorea = CountryConfig(
    code: 'KR',
    name: '대한민국',
    flag: '\u{1F1F0}\u{1F1F7}',
    currency: 'KRW',
    currencySymbol: '₩',
    locale: 'ko_KR',
    postalCodeLength: 5,
    postalCodeRegex: r'^\d{5}$',
    postalCodeLabel: '우편번호',
    requiresApiKey: true,
    apiKeyRegistrationUrl: 'https://www.opinet.co.kr/',
    apiProvider: 'OPINET (KNOC)',
    attribution: 'Data: OPINET / Korea National Oil Corporation',
    fuelTypes: ['휘발유', '고급휘발유', '경유', 'LPG'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e98,
      FuelType.diesel,
      FuelType.lpg,
      FuelType.electric,
    },
    examplePostalCode: '04524',
    exampleCity: '서울',
    pricePerUnitSuffix: '₩/L',
  );

  /// Chile — CNE "Bencina en Línea" REST API (#596). ~6 000 service
  /// stations nationwide. Gasolina 93/95 (→ e5), Gasolina 97 (→ e98),
  /// Diésel, Gas licuado/LPG. Kerosene is published but unmapped until
  /// we add a FuelType enum for it. Prices are in CLP per litre.
  static const chile = CountryConfig(
    code: 'CL',
    name: 'Chile',
    flag: '\u{1F1E8}\u{1F1F1}',
    currency: 'CLP',
    currencySymbol: '\$',
    locale: 'es_CL',
    postalCodeLength: 7,
    // Chilean postal codes are 7 digits (RUT-style "1234567"). The
    // regex is lenient enough to accept the common "123-4567" form as
    // well — both variants appear on government records.
    postalCodeRegex: r'^\d{7}$',
    postalCodeLabel: 'Código postal',
    requiresApiKey: true,
    apiKeyRegistrationUrl: 'https://api.cne.cl/',
    apiProvider: 'CNE Bencina en Linea',
    attribution: 'Datos: Comisión Nacional de Energía (cne.cl)',
    fuelTypes: ['Gasolina 93', 'Gasolina 95', 'Gasolina 97', 'Diésel', 'GLP'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e98,
      FuelType.diesel,
      FuelType.lpg,
      FuelType.electric,
    },
    examplePostalCode: '8320000',
    exampleCity: 'Santiago',
    pricePerUnitSuffix: '\$/L',
  );

  /// Greece — Paratiritirio Timon (Fuel Price Observatory) via the
  /// community [fuelpricesgr](https://github.com/mavroprovato/fuelpricesgr)
  /// API (#576). The community feed is free and open — no key required.
  /// Coverage is prefecture-level (not station-level): we synthesize one
  /// virtual station per major prefecture, each showing that region's
  /// daily mean price. Fuels: Αμόλυβδη 95 (→ e5), Αμόλυβδη 100 (→ e98),
  /// Diesel (→ diesel), Υγραέριο / LPG (→ lpg). Diesel heating is
  /// published but dropped — not a motoring fuel.
  static const greece = CountryConfig(
    code: 'GR',
    name: 'Ελλάδα',
    flag: '\u{1F1EC}\u{1F1F7}',
    locale: 'el_GR',
    postalCodeLength: 5,
    postalCodeRegex: r'^\d{5}$',
    postalCodeLabel: 'Ταχυδρομικός κώδικας',
    requiresApiKey: false,
    apiProvider: 'Paratiritirio Timon',
    attribution:
        'Data: fuelprices.gr (Paratiritirio Timon) via fuelpricesgr community API',
    fuelTypes: ['Αμόλυβδη 95', 'Αμόλυβδη 100', 'Diesel', 'LPG'],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e98,
      FuelType.diesel,
      FuelType.lpg,
      FuelType.electric,
    },
    examplePostalCode: '10431',
    exampleCity: 'Αθήνα',
  );

  /// Romania — *Monitorul Prețurilor la Carburanți* (pretcarburant.ro),
  /// the Competition Council + ANPC joint observatory (#577). Romanian
  /// law mandates 15-minute price updates from every retailer and ~1 500
  /// stations are covered (Petrom / OMV / Rompetrol / MOL / Lukoil /
  /// Socar). The feed is public — no key required. Fuels: Benzină
  /// Standard (→ e5), Benzină Premium (→ e98), Motorină Standard
  /// (→ diesel), Motorină Premium (→ diesel premium), GPL (→ lpg).
  static const romania = CountryConfig(
    code: 'RO',
    name: 'România',
    flag: '\u{1F1F7}\u{1F1F4}',
    currency: 'RON',
    currencySymbol: 'lei',
    locale: 'ro_RO',
    postalCodeLength: 6,
    postalCodeRegex: r'^\d{6}$',
    postalCodeLabel: 'Cod poștal',
    requiresApiKey: false,
    apiProvider: 'Monitorul Prețurilor',
    attribution:
        'Date: Consiliul Concurenței + ANPC — pretcarburant.ro',
    fuelTypes: [
      'Benzină Standard',
      'Benzină Premium',
      'Motorină Standard',
      'Motorină Premium',
      'GPL',
    ],
    supportedFuelTypes: {
      FuelType.e5,
      FuelType.e98,
      FuelType.diesel,
      FuelType.dieselPremium,
      FuelType.lpg,
      FuelType.electric,
    },
    examplePostalCode: '010101',
    exampleCity: 'București',
    pricePerUnitSuffix: 'lei/L',
  );

  /// All supported countries, ordered for display.
  static const all = [
    germany, france, austria, spain, italy, denmark, argentina,
    portugal, unitedKingdom, australia, mexico, luxembourg, slovenia,
    southKorea, chile, greece, romania,
  ];

  /// Find country by ISO code.
  static CountryConfig? byCode(String code) {
    for (final c in all) {
      if (c.code == code) return c;
    }
    return null;
  }

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
