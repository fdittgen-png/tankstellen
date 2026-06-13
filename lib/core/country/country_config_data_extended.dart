// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/fuel_type.dart';
import 'country_config.dart';

/// #3296 — the v4.1.0+ country-definition rows extracted out of `Countries`.
/// `Countries.<name>` stays as a `static const` alias of the matching
/// `k<Name>` here, so every call site is unchanged. The original pre-v4.1.0
/// set lives in `country_config_data_core.dart`.

const kPortugal = CountryConfig(
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

const kUnitedKingdom = CountryConfig(
  code: 'GB',
  name: 'United Kingdom',
  flag: '\u{1F1EC}\u{1F1E7}',
  currency: 'GBP',
  currencySymbol: '£',
  locale: 'en_GB',
  postalCodeLength: 7,
  postalCodeRegex: r'^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$',
  postalCodeLabel: 'Postcode',
  apiProvider: 'CMA Fuel Finder',
  attribution: 'Data: Competition and Markets Authority',
  fuelTypes: ['Unleaded', 'Super Unleaded', 'E10', 'Diesel'],
  // #2180 — UkStationService parses the CMA feed into e5 (E5/unleaded),
  // e10 (E10), e98 (super_unleaded), diesel (B7/diesel). It never emits
  // dieselPremium, so drop it and add e10 to match the live selector.
  supportedFuelTypes: {
    FuelType.e5,
    FuelType.e10,
    FuelType.e98,
    FuelType.diesel,
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

const kAustralia = CountryConfig(
  code: 'AU',
  name: 'Australia',
  flag: '\u{1F1E6}\u{1F1FA}',
  currency: 'AUD',
  currencySymbol: '\$',
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
  // #2264 — AustraliaStationService is a documented stub that throws on
  // every search (the legacy FuelCheckApp/v2 endpoint is retired and the
  // replacement needs OAuth2 we don't ship; tracked in #804). Advertising
  // it as verified put a country in the picker that can only ever error,
  // so gate it out until #804 lands a working endpoint. The entry stays
  // *registered* — an `au-` station id still resolves — it is only hidden
  // from the user-facing pickers via [Countries.verified].
  verified: false,
);

const kSlovenia = CountryConfig(
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
  // #3198 — the single NMB-95 grade is e5 only (the old e5→e10 mirror
  // asserted an E10 price goriva.si never publishes).
  supportedFuelTypes: {
    FuelType.e5,
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

const kMexico = CountryConfig(
  code: 'MX',
  name: 'México',
  flag: '\u{1F1F2}\u{1F1FD}',
  currency: 'MXN',
  currencySymbol: '\$',
  locale: 'es_MX',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'Código postal',
  apiProvider: 'CRE / datos.gob.mx',
  attribution: 'Datos: Comisión Reguladora de Energía',
  fuelTypes: ['Regular', 'Premium', 'Diesel'],
  // #2704 — MexicoStationService maps CRE regular→e5, premium→e98 (MX's
  // high-octane 91–92 grade, NOT the European e10 ethanol blend, absent in
  // MX), diesel→diesel. The picker must offer e98 (not e10) to match the
  // data the search selector surfaces.
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
const kLuxembourg = CountryConfig(
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
const kSouthKorea = CountryConfig(
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
  // #1828 — OPINET endpoint path is a best guess, unverified
  // against the live portal (#1823). Hidden from the picker.
  verified: false,
);

/// Chile — CNE "Bencina en Línea" REST API (#596). ~6 000 service
/// stations nationwide. Gasolina 93/95 (→ e5), Gasolina 97 (→ e98),
/// Diésel, Gas licuado/LPG. Kerosene is published but unmapped until
/// we add a FuelType enum for it. Prices are in CLP per litre.
const kChile = CountryConfig(
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
  apiKeyRegistrationUrl: 'https://apidocs.cne.cl/', // #3200 docs portal
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
  // #3200 — path + Bearer auth match apidocs.cne.cl; hidden until a
  // registered token confirms the payload shape end-to-end.
  verified: false,
);

/// Greece — Paratiritirio Timon (Fuel Price Observatory) via the
/// community [fuelpricesgr](https://github.com/mavroprovato/fuelpricesgr)
/// API (#576). The community feed is free and open — no key required.
/// Coverage is prefecture-level (not station-level): we synthesize one
/// virtual station per major prefecture, each showing that region's
/// daily mean price. Fuels: Αμόλυβδη 95 (→ e5), Αμόλυβδη 100 (→ e98),
/// Diesel (→ diesel), Υγραέριο / LPG (→ lpg). Diesel heating is
/// published but dropped — not a motoring fuel.
const kGreece = CountryConfig(
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
  // #3194 — default host is NXDOMAIN; the service short-circuits to
  // "unavailable" unless self-hosted. Hidden until a real source exists.
  verified: false,
);

/// Romania — *Monitorul Prețurilor*, the Competition Council's
/// official observatory at monitorulpreturilor.info (#577; #3193
/// rebased off the dead third-party pretcarburant.ro). ~1 500
/// stations, public feed, no key. Fuels (catalog ids): Benzină
/// standard 11 (→ e5), premium 12 (→ e98), Motorină standard 21
/// (→ diesel), premium 22 (→ diesel premium), GPL 31 (→ lpg).
const kRomania = CountryConfig(
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
      'Date: Consiliul Concurenței — monitorulpreturilor.info',
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
  // #3193 — rebased onto the real monitorulpreturilor.info backend;
  // hidden until the maintainer field-verifies, then flip to true.
  verified: false,
);
