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
  final String examplePostalCode;
  final String exampleCity;

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
    this.examplePostalCode = '',
    this.exampleCity = '',
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
    examplePostalCode: '1000',
    exampleCity: 'København',
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
    examplePostalCode: '1000',
    exampleCity: 'Buenos Aires',
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
    examplePostalCode: 'SW1A 1AA',
    exampleCity: 'London',
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
    examplePostalCode: '2000',
    exampleCity: 'Sydney',
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
    examplePostalCode: '06600',
    exampleCity: 'Ciudad de México',
  );

  /// All supported countries, ordered for display.
  static const all = [
    germany, france, austria, spain, italy, denmark, argentina,
    portugal, unitedKingdom, australia, mexico,
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
}
