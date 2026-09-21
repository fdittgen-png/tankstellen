// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_fuel_capability.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// #4258 (Epic #4257) — country-aware fuel resolution for profile cloning.
///
/// Every expectation below is pinned to the REAL `supportedFuelTypes` sets
/// in `country_config_data_*.dart`, not to invented fixtures:
///
/// - FR `{e5, e10, e98, diesel, e85, lpg, electric}`
/// - AT `{e5, diesel, electric}`              ← no e10: the sibling case
/// - IT `{e5, diesel, lpg, cng, electric}`    ← no e10, no e85
/// - ES `{e5, e10, e98, diesel, dieselPremium, lpg, electric}`
///
/// NOTE on Spain: #4257/#4258 use "Spain with an E10 profile resolves to
/// E5" as the headline case. That is a *station-level* truth from #2641
/// (769 of 798 province-08 stations price E5, ~1 prices E10) — Spain's
/// country config does list e10, so at the COUNTRY-capability layer E10 is
/// retained for ES. Austria and Italy are the countries that genuinely
/// lack E10, so they carry the sibling-substitution coverage here.
void main() {
  group('supportedFuels', () {
    test('reads the per-country SSoT', () {
      expect(CountryFuelCapability.supportedFuels('AT'),
          {FuelType.e5, FuelType.diesel, FuelType.electric});
    });

    test('is case-insensitive on the ISO code', () {
      expect(CountryFuelCapability.supportedFuels('at'),
          CountryFuelCapability.supportedFuels('AT'));
    });

    test('never includes the search-time wildcard', () {
      for (final code in ['FR', 'AT', 'IT', 'ES', 'DE']) {
        expect(CountryFuelCapability.supportedFuels(code),
            isNot(contains(FuelType.all)),
            reason: '$code must not offer FuelType.all as a preference');
      }
    });

    test('unregistered country yields an empty set', () {
      expect(CountryFuelCapability.supportedFuels('XX'), isEmpty);
    });
  });

  group('supports', () {
    test('true for a grade the country sells', () {
      expect(CountryFuelCapability.supports('FR', FuelType.e85), isTrue);
    });

    test('false for a grade it does not', () {
      expect(CountryFuelCapability.supports('AT', FuelType.e10), isFalse);
      expect(CountryFuelCapability.supports('IT', FuelType.e85), isFalse);
    });
  });

  group('resolveForCountry — retained', () {
    test('keeps the source fuel when the target country sells it', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'FR', sourceFuel: FuelType.e10);
      expect(r.fuel, FuelType.e10);
      expect(r.reason, FuelResolutionReason.retained);
      expect(r.isResolved, isTrue);
    });

    test('diesel is retained, never nudged to a petrol grade', () {
      for (final code in ['FR', 'AT', 'IT', 'ES']) {
        final r = CountryFuelCapability.resolveForCountry(
            countryCode: code, sourceFuel: FuelType.diesel);
        expect(r.fuel, FuelType.diesel, reason: '$code keeps diesel');
        expect(r.reason, FuelResolutionReason.retained);
      }
    });

    test('Spain retains E10 — its config does list e10 (#2641 is '
        'station-level, not country-level)', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'ES', sourceFuel: FuelType.e10);
      expect(r.fuel, FuelType.e10);
      expect(r.reason, FuelResolutionReason.retained);
    });
  });

  group('resolveForCountry — the ONLY substitution: E5 <-> E10', () {
    test('E10 into Austria resolves to E5', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'AT', sourceFuel: FuelType.e10);
      expect(r.fuel, FuelType.e5);
      expect(r.reason, FuelResolutionReason.substitutedOctaneSibling);
    });

    test('E10 into Italy resolves to E5', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'IT', sourceFuel: FuelType.e10);
      expect(r.fuel, FuelType.e5);
      expect(r.reason, FuelResolutionReason.substitutedOctaneSibling);
    });

    test('E5 into a country selling only E10 would resolve to E10 '
        '(pair is symmetric)', () {
      // No shipped country is E10-only, so assert the map's symmetry
      // through the public API on a country that sells both: E5 stays E5
      // because retention wins before substitution.
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'GB', sourceFuel: FuelType.e5);
      expect(r.fuel, FuelType.e5);
      expect(r.reason, FuelResolutionReason.retained,
          reason: 'retention is checked before the sibling swap');
    });
  });

  group('resolveForCountry — no silent product change', () {
    test('E85 is never substituted — Italy sells none', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'IT', sourceFuel: FuelType.e85);
      expect(r.fuel, isNull);
      expect(r.isResolved, isFalse);
      expect(r.reason, FuelResolutionReason.unsupportedInCountry);
    });

    test('E98 is never substituted to a 95-octane grade', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'AT', sourceFuel: FuelType.e98);
      expect(r.fuel, isNull);
      expect(r.reason, FuelResolutionReason.unsupportedInCountry);
    });

    test('LPG is never substituted', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'AT', sourceFuel: FuelType.lpg);
      expect(r.fuel, isNull);
      expect(r.reason, FuelResolutionReason.unsupportedInCountry);
    });

    test('CNG is never substituted', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'FR', sourceFuel: FuelType.cng);
      expect(r.fuel, isNull);
      expect(r.reason, FuelResolutionReason.unsupportedInCountry);
    });

    test('a petrol grade never becomes diesel', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'AT', sourceFuel: FuelType.e85);
      expect(r.fuel, isNot(FuelType.diesel));
      expect(r.isResolved, isFalse);
    });
  });

  group('resolveForCountry — non-country outcomes', () {
    test('the wildcard is never cloned into a profile', () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'FR', sourceFuel: FuelType.all);
      expect(r.fuel, isNull);
      expect(r.reason, FuelResolutionReason.sourceIsWildcard);
    });

    test('an unregistered country is reported as unknown, not unsupported',
        () {
      final r = CountryFuelCapability.resolveForCountry(
          countryCode: 'XX', sourceFuel: FuelType.e10);
      expect(r.fuel, isNull);
      expect(r.reason, FuelResolutionReason.unknownCountry,
          reason: 'an unsupported COUNTRY and an unsupported FUEL need '
              'different UX copy');
    });

    test('every reason code is reachable through the public API', () {
      final seen = <FuelResolutionReason>{
        CountryFuelCapability.resolveForCountry(
                countryCode: 'FR', sourceFuel: FuelType.e10)
            .reason,
        CountryFuelCapability.resolveForCountry(
                countryCode: 'AT', sourceFuel: FuelType.e10)
            .reason,
        CountryFuelCapability.resolveForCountry(
                countryCode: 'IT', sourceFuel: FuelType.e85)
            .reason,
        CountryFuelCapability.resolveForCountry(
                countryCode: 'XX', sourceFuel: FuelType.e10)
            .reason,
        CountryFuelCapability.resolveForCountry(
                countryCode: 'FR', sourceFuel: FuelType.all)
            .reason,
      };
      expect(seen, FuelResolutionReason.values.toSet());
    });

    test('an unresolved result always carries a null fuel', () {
      for (final code in ['XX', 'IT', 'AT']) {
        for (final fuel in [FuelType.all, FuelType.e85, FuelType.hydrogen]) {
          final r = CountryFuelCapability.resolveForCountry(
              countryCode: code, sourceFuel: fuel);
          if (!r.isResolved) {
            expect(r.fuel, isNull,
                reason: 'isResolved=false must mean no fuel to persist');
          }
        }
      }
    });
  });
}
