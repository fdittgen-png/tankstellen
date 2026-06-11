// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Cross-check guard for the two parallel fuel-type structures (#2180).
///
/// A country's fuel set is declared twice, in two files, with two
/// consumers:
///
///  * [CountryConfig.supportedFuelTypes] — the **typed picker set**. Read
///    by the profile fuel-type chip picker, the search fuel-type dropdown
///    filter, and the cross-border fuel-availability suggestion. This is
///    "which fuels can this country's user choose / search".
///  * [CountryServiceEntry.availableFuelTypes] — the **selector list**.
///    Read by the search fuel-type selector (`fuelTypesForCountry`). This
///    is "which fuels the live search UI offers for this country", and it
///    is sourced from the order the upstream station service publishes.
///
/// They had drifted (AR/MX/SI/DK in the original audit; GB/AU surfaced by
/// this very test): a country could let a user *configure* a vehicle fuel
/// the search selector never offered, or carry a registry fuel the picker
/// hid — e.g. Argentine GNC stations had real prices the selector could
/// never surface. The ground truth for both is what each
/// `*_station_service.dart` actually maps onto [Station] fuel fields.
///
/// This test is the regression backstop: after the #2180 alignment, the
/// two structures must agree (as sets, ignoring the search-time
/// [FuelType.all] wildcard the registry appends) for **every** registered
/// country. Adding a new country with mismatched lists fails here with a
/// message naming the country and the exact offending fuels.
void main() {
  group('fuel-type parity: supportedFuelTypes vs availableFuelTypes (#2180)',
      () {
    String fmt(Iterable<FuelType> fuels) =>
        (fuels.map((f) => f.apiValue).toList()..sort()).join(', ');

    /// Registry fuel set with the search-time [FuelType.all] wildcard
    /// stripped — the picker set never contains it (asserted separately in
    /// country_supported_fuels_test.dart), so it is excluded from parity.
    Set<FuelType> registrySet(String code) => CountryServiceRegistry
        .fuelTypesFor(code)
        .where((f) => f != FuelType.all)
        .toSet();

    test('every country: picker set == selector set (minus FuelType.all)',
        () {
      final mismatches = <String>[];
      for (final country in Countries.all) {
        final picker = country.supportedFuelTypes;
        final selector = registrySet(country.code);

        final pickerOnly = picker.difference(selector);
        final selectorOnly = selector.difference(picker);
        if (pickerOnly.isEmpty && selectorOnly.isEmpty) continue;

        final parts = <String>[];
        if (pickerOnly.isNotEmpty) {
          parts.add('configured but never offered/searchable: '
              '{${fmt(pickerOnly)}}');
        }
        if (selectorOnly.isNotEmpty) {
          parts.add('offered by search but not configurable: '
              '{${fmt(selectorOnly)}}');
        }
        mismatches.add('${country.code}: ${parts.join('; ')} '
            '(supportedFuelTypes={${fmt(picker)}} '
            'vs availableFuelTypes={${fmt(selector)}})');
      }

      expect(
        mismatches,
        isEmpty,
        reason: 'CountryConfig.supportedFuelTypes and '
            'CountryServiceEntry.availableFuelTypes have drifted. Each fuel '
            'a country lists must be one its station service actually emits '
            '(check lib/features/station_services/<country>/), and both '
            'structures must agree. Offenders:\n  ${mismatches.join('\n  ')}',
      );
    });

    test('regression: Argentina exposes GNC (cng) in BOTH structures (#2180)',
        () {
      // ArgentinaStationService maps the CSV "GNC" product onto Station.cng
      // with a real price, so CNG stations must be both configurable and
      // searchable — the original defect hid them from the search selector.
      expect(
        Countries.argentina.supportedFuelTypes,
        contains(FuelType.cng),
        reason: 'AR picker must offer CNG — GNC stations carry real prices',
      );
      expect(
        registrySet('AR'),
        contains(FuelType.cng),
        reason: 'AR search selector must offer CNG — GNC stations carry '
            'real prices the user must be able to search for',
      );
    });

    test(
        'regression: Slovenia exposes cng but NOT e10 in BOTH structures '
        '(#2180/#3198)', () {
      // SloveniaStationService maps the goriva.si "cng" key onto
      // Station.cng (#2180). The single NMB-95 grade lives in e5 only:
      // #3198 removed the e5→e10 mirror, so neither structure may offer
      // an E10 the feed never publishes.
      expect(
        Countries.slovenia.supportedFuelTypes,
        contains(FuelType.cng),
        reason: 'SI picker must offer CNG',
      );
      expect(
        registrySet('SI'),
        contains(FuelType.cng),
        reason: 'SI search selector must offer CNG',
      );
      expect(
        Countries.slovenia.supportedFuelTypes,
        isNot(contains(FuelType.e10)),
        reason: '#3198 — goriva.si publishes no E10 grade',
      );
      expect(registrySet('SI'), isNot(contains(FuelType.e10)));
    });

    test('regression: Mexico offers e98 (premium grade) not e10 (#2704)', () {
      // #2704 — MexicoStationService maps CRE "premium" (Mexico's
      // high-octane 91–92 grade) onto Station.e98, never e10 (a European
      // ethanol blend that does not exist in Mexico). The picker must offer
      // e98 and must NOT offer e10, otherwise it surfaces an unsearchable
      // grade and hides the one premium prices actually populate.
      expect(Countries.mexico.supportedFuelTypes, contains(FuelType.e98));
      expect(
        Countries.mexico.supportedFuelTypes,
        isNot(contains(FuelType.e10)),
        reason: 'MX premium grade lands in the e98 slot, not e10',
      );
      expect(registrySet('MX'), contains(FuelType.e98));
      expect(registrySet('MX'), isNot(contains(FuelType.e10)));
    });

    test(
        'regression: Denmark offers the real premium grades, NOT e10 '
        '(#3187/#3198)', () {
      // #3198 — no DK feed publishes an E10 grade; the old Blyfri-95
      // mirror is gone. #3187's exact-grade mapping emits Oktan 100 /
      // V-Power → e98 and V-Power Diesel → dieselPremium instead.
      expect(
        Countries.denmark.supportedFuelTypes,
        isNot(contains(FuelType.e10)),
      );
      expect(registrySet('DK'), isNot(contains(FuelType.e10)));
      for (final fuel in const [FuelType.e98, FuelType.dieselPremium]) {
        expect(Countries.denmark.supportedFuelTypes, contains(fuel),
            reason: 'DK picker must offer ${fuel.apiValue}');
        expect(registrySet('DK'), contains(fuel),
            reason: 'DK search selector must offer ${fuel.apiValue}');
      }
    });

    test('regression: UK offers e10, drops dieselPremium (#2180)', () {
      // UkStationService emits e5/e10/e98/diesel, never dieselPremium.
      expect(Countries.unitedKingdom.supportedFuelTypes,
          contains(FuelType.e10));
      expect(
        Countries.unitedKingdom.supportedFuelTypes,
        isNot(contains(FuelType.dieselPremium)),
        reason: 'GB CMA feed has no premium-diesel grade',
      );
      expect(registrySet('GB'), contains(FuelType.e98));
    });
  });
}
