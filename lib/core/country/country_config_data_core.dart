// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/fuel_type.dart';
import 'country_config.dart';

/// #3296 — the original (pre-v4.1.0) country-definition rows extracted out of
/// `Countries`. `Countries.<name>` stays as a `static const` alias of the
/// matching `k<Name>` here, so every call site is unchanged. The v4.1.0+
/// additions live in `country_config_data_extended.dart`.

const kGermany = CountryConfig(
  code: 'DE',
  name: 'Deutschland',
  flag: '\u{1F1E9}\u{1F1EA}',
  locale: 'de_DE',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'PLZ',
  requiresApiKey: true,
  apiKeyRegistrationUrl: 'https://onboarding.tankerkoenig.de/',
  apiProvider: 'Tankerkönig',
  attribution: 'Daten von Tankerkoenig.de (CC BY 4.0)',
  fuelTypes: ['Super E5', 'Super E10', 'Diesel'],
  examplePostalCode: '10115',
  exampleCity: 'Berlin',
);

const kFrance = CountryConfig(
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

const kAustria = CountryConfig(
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
  fuelTypes: ['Super 95', 'Diesel'],
  // #3198 — E-Control publishes exactly one petrol grade (SUP); the old
  // default set advertised an E10 the feed never carries (the service
  // mirrored e5 into e10 to fill it). Catalog now matches the source.
  supportedFuelTypes: {
    FuelType.e5,
    FuelType.diesel,
    FuelType.electric,
  },
  examplePostalCode: '1010',
  exampleCity: 'Wien',
);

const kSpain = CountryConfig(
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

const kItaly = CountryConfig(
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

const kDenmark = CountryConfig(
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
  fuelTypes: ['Blyfri 95', 'Oktan 100', 'Diesel', 'V-Power Diesel'],
  // #3198 — the single Danish 95-octane grade is e5 only (the #2180
  // e5→e10 mirror asserted an E10 price no DK feed publishes); the
  // #3187 exact-grade mapping added the real premium grades instead:
  // Oktan 100 / V-Power → e98, V-Power Diesel → dieselPremium.
  supportedFuelTypes: {
    FuelType.e5,
    FuelType.e98,
    FuelType.diesel,
    FuelType.dieselPremium,
    FuelType.electric,
  },
  examplePostalCode: '1000',
  exampleCity: 'København',
  pricePerUnitSuffix: 'kr/L',
);

const kArgentina = CountryConfig(
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
  // #2180/#3198 — aligned to what ArgentinaStationService actually
  // emits: Nafta súper → e5 (no e10 — the old mirror asserted an E10
  // price the feed never publishes), Nafta premium → e98, Gas oil →
  // diesel, Gas oil premium → dieselPremium, GNC → cng (see
  // classifyArgentinaProduct and the service's Station mapping).
  supportedFuelTypes: {
    FuelType.e5,
    FuelType.e98,
    FuelType.diesel,
    FuelType.dieselPremium,
    FuelType.cng,
    FuelType.electric,
  },
  examplePostalCode: '1000',
  exampleCity: 'Buenos Aires',
  pricePerUnitSuffix: '\$/L',
  // #3198 — GNC (CNG) is priced per cubic metre upstream, not per
  // litre; the per-fuel override keeps every other fuel on \$/L.
  pricePerUnitSuffixByFuel: {FuelType.cng: '\$/m³'},
);
