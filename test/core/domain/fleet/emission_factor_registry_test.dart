// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fleet/claim_class.dart';
import 'package:tankstellen/core/domain/fleet/emission_factor_registry.dart';
import 'package:tankstellen/core/domain/fleet/fleet_provenance.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/services/co2_calculator.dart';

/// #4219 — a versioned factor registry: every factor is cited, a
/// missing factor is *stated* (never `0`, never a neighbour's value),
/// and a CO2 claim without a factor has no number to show.
///
/// #4392 — and the seed now publishes BOTH boundaries from one source
/// (ADEME Base Carbone v23.6), with `Co2Calculator` pinned to the
/// well-to-wheel column in both directions.
void main() {
  const registry = EmissionFactorRegistry.ademeBaseCarbone;

  group('every seeded factor is fully cited', () {
    test('source, version, publication, unit, scope, fuel key', () {
      expect(registry.factors, isNotEmpty);
      for (final f in registry.factors) {
        expect(f.source, isNotEmpty, reason: '${f.fuelKey}: no source');
        expect(f.version, isNotEmpty, reason: '${f.fuelKey}: no version');
        expect(f.publication, isNotEmpty,
            reason: '${f.fuelKey}: no publication');
        expect(f.fuelKey, f.fuelKey.toLowerCase());
        expect(f.kgCo2ePerUnit, greaterThan(0));
        expect(f.citation, contains(f.version));
      }
    });

    test('the seed publishes both boundaries, from one source, applied '
        'as published', () {
      expect(registry.factors.map((f) => f.scope).toSet(),
          {EmissionScope.wellToWheel, EmissionScope.tankToWheel});
      expect(registry.factors.map((f) => f.geography).toSet(), {null},
          reason: 'ADEME publishes one boundary (France continentale); '
              'the rows are applied as published, not re-regioned');
      expect(registry.factors.map((f) => f.citation).toSet(),
          {'ADEME Base Carbone v23.6 (2026)'},
          reason: 'one row, one source — never an averaged blend of '
              'ADEME, DESNZ and the FQD');
    });

    test('every fuel that is published at all is published at BOTH '
        'boundaries — a half-published fuel would make the scope '
        'selector silently change the answer to "not calculated"', () {
      for (final key in registry.factors.map((f) => f.fuelKey).toSet()) {
        expect(registry.publishedScopesFor(key),
            {EmissionScope.tankToWheel, EmissionScope.wellToWheel},
            reason: key);
      }
    });

    test('tank-to-wheel is never above well-to-wheel: the upstream half '
        'cannot be negative (#4392)', () {
      for (final key in registry.factors.map((f) => f.fuelKey).toSet()) {
        final ttw = registry
            .lookup(key, EmissionScope.tankToWheel)
            .valueOrNull!
            .kgCo2ePerUnit;
        final wtw = registry
            .lookup(key, EmissionScope.wellToWheel)
            .valueOrNull!
            .kgCo2ePerUnit;
        expect(ttw, lessThan(wtw), reason: key);
      }
    });

    test('no fuel key is seeded twice for the same scope and geography', () {
      final keys = registry.factors
          .map((f) => '${f.fuelKey}|${f.scope.name}|${f.geography}')
          .toList();
      expect(keys.toSet().length, keys.length);
    });
  });

  group('lookup', () {
    test('returns a published factor as a class-average estimate', () {
      final v = registry.lookup('diesel', EmissionScope.wellToWheel);
      expect(v, isA<Estimated<EmissionFactor>>());
      final f = (v as Estimated<EmissionFactor>).value;
      expect(v.basis, DataBasis.fleetAverage);
      expect(f.kgCo2ePerUnit, 3.10,
          reason: 'ADEME element 25775 Gazole routier B7, total');
      expect(f.unit, EmissionUnit.kgCo2ePerLitre);
    });

    test('is case-insensitive on the fuel key', () {
      expect(registry.lookup('Diesel', EmissionScope.wellToWheel).isKnown,
          isTrue);
    });

    test('agrees with Co2Calculator for every fuel it publishes (and no '
        'other), so the two cannot drift apart silently', () {
      for (final fuel in FuelType.values) {
        final calc = Co2Calculator.emissionFactorFor(fuel);
        final reg = registry.lookup(fuel.apiValue, EmissionScope.wellToWheel);
        if (calc == null) {
          expect(reg.isKnown, isFalse,
              reason: '${fuel.apiValue}: the calculator has no factor, so '
                  'the registry must say so too');
          expect(registry.publishedScopesFor(fuel.apiValue), isEmpty,
              reason: '${fuel.apiValue}: not even a TtW row may exist for '
                  'a fuel the calculator refuses');
        } else {
          expect(reg.valueOrNull?.kgCo2ePerUnit, calc,
              reason: '${fuel.apiValue}: registry ≠ Co2Calculator');
        }
      }
    });

    test('the calculator is the WtW column and says so — scope label and '
        'citation come from the same rows (#4392)', () {
      expect(Co2Calculator.scopeLabel, EmissionScope.wellToWheel.label);
      expect(Co2Calculator.factorCitation,
          registry.lookup('e10', EmissionScope.wellToWheel)
              .valueOrNull!
              .citation);
    });

    test('the reviewed ADEME values, by element (#4392)', () {
      double at(String key, EmissionScope scope) =>
          registry.lookup(key, scope).valueOrNull!.kgCo2ePerUnit;
      // element 25763 — Supercarburant sans plomb (95, 95-E10, 98)
      expect(at('e5', EmissionScope.tankToWheel), 2.20);
      expect(at('e5', EmissionScope.wellToWheel), 2.69);
      expect(at('e98', EmissionScope.tankToWheel), 2.20);
      expect(at('e98', EmissionScope.wellToWheel), 2.69);
      // element 13988 — Essence E10
      expect(at('e10', EmissionScope.tankToWheel), 2.19);
      expect(at('e10', EmissionScope.wellToWheel), 2.69);
      // element 25775 — Gazole routier B7 (premium shares the grade)
      expect(at('diesel', EmissionScope.tankToWheel), 2.49);
      expect(at('diesel', EmissionScope.wellToWheel), 3.10);
      expect(at('diesel_premium', EmissionScope.tankToWheel), 2.49);
      expect(at('diesel_premium', EmissionScope.wellToWheel), 3.10);
      // element 25766 — Essence E85 (biogenic CO2 booked upstream)
      expect(at('e85', EmissionScope.tankToWheel), 0.366);
      expect(at('e85', EmissionScope.wellToWheel), 1.11);
      // element 14031 — GPL pour véhicule routier, per litre
      expect(at('lpg', EmissionScope.tankToWheel), 1.60);
      expect(at('lpg', EmissionScope.wellToWheel), 1.86);
      // element 27095 — GNC pour véhicule routier, per kilogram
      expect(at('cng', EmissionScope.tankToWheel), 2.41);
      expect(at('cng', EmissionScope.wellToWheel), 2.96);
    });

    test('CNG is published per kilogram, like the calculator sells it', () {
      final f = registry.lookup('cng', EmissionScope.wellToWheel).valueOrNull;
      expect(f?.unit, EmissionUnit.kgCo2ePerKilogram);
    });

    test('an unpublished fuel is Unknown(notPublishedForThisItem) — not 0',
        () {
      for (final key in const ['electric', 'hydrogen', 'all', 'kerosene']) {
        final v = registry.lookup(key, EmissionScope.wellToWheel);
        expect(v,
            const DataValue<EmissionFactor>.unknown(
                reason: DataUnknownReason.notPublishedForThisItem),
            reason: key);
        expect(v.valueOrNull, isNull);
      }
    });

    test('an unsourced fuel is refused at BOTH boundaries — electricity '
        'and hydrogen are measured in units the app never records, so '
        'no row exists to multiply (#4392)', () {
      for (final key in const ['electric', 'hydrogen']) {
        for (final scope in EmissionScope.values) {
          expect(
              registry.lookup(key, scope),
              const DataValue<EmissionFactor>.unknown(
                  reason: DataUnknownReason.notPublishedForThisItem),
              reason: '$key / ${scope.label}');
        }
        expect(registry.publishedScopesFor(key), isEmpty, reason: key);
      }
      expect(registry.publishedScopesFor('diesel'),
          {EmissionScope.tankToWheel, EmissionScope.wellToWheel});
    });

    test('a kWh row would need the unit the registry already models — '
        'it is absent because nothing cites it, not because the unit '
        'is missing', () {
      expect(EmissionUnit.values,
          contains(EmissionUnit.kgCo2ePerKilowattHour));
      expect(
          registry.factors
              .where((f) => f.unit == EmissionUnit.kgCo2ePerKilowattHour),
          isEmpty);
    });

    test('geography: an exact match wins, the source boundary is the '
        'fallback, and nothing else substitutes', () {
      const eu = EmissionFactor(
        fuelKey: 'diesel',
        scope: EmissionScope.tankToWheel,
        kgCo2ePerUnit: 2.0,
        unit: EmissionUnit.kgCo2ePerLitre,
        source: 'test',
        version: '1',
        publication: '2026',
      );
      const fr = EmissionFactor(
        fuelKey: 'diesel',
        scope: EmissionScope.tankToWheel,
        kgCo2ePerUnit: 2.1,
        unit: EmissionUnit.kgCo2ePerLitre,
        source: 'test',
        version: '1',
        publication: '2026',
        geography: 'FR',
      );
      const r = EmissionFactorRegistry([eu, fr]);
      expect(
          r.lookup('diesel', EmissionScope.tankToWheel, geography: 'FR')
              .valueOrNull,
          fr);
      expect(
          r.lookup('diesel', EmissionScope.tankToWheel, geography: 'DE')
              .valueOrNull,
          eu,
          reason: 'no DE-specific factor: the source boundary applies');
      expect(r.lookup('diesel', EmissionScope.tankToWheel).valueOrNull, eu);
      // A geography-only publication never leaks to other geographies.
      const frOnly = EmissionFactorRegistry([fr]);
      expect(
          frOnly.lookup('diesel', EmissionScope.tankToWheel, geography: 'DE')
              .isKnown,
          isFalse);
      expect(frOnly.lookup('diesel', EmissionScope.tankToWheel).isKnown,
          isFalse);
    });
  });

  group('co2eClaim — the environmental estimate', () {
    final litres = ClaimedValue<double>.measuredFact(10.0,
        source: FleetMetricSource.measuredFillUp);

    test('with a factor: a qualified environmental estimate whose '
        'provenance names the factor as derived', () {
      final out =
          co2eClaim(litres, registry.lookup('e10', EmissionScope.wellToWheel));
      expect(out.claim, ClaimClass.environmentalEstimate);
      expect(out.valueOrNull, closeTo(26.9, 1e-9));
      expect(out.isQualified, isTrue,
          reason: 'a factor is a class average; the figure carries ≈');
      expect(out.rendersAsMeasured, isFalse);
      expect(out.provenance, contains(FleetMetricSource.derived));
    });

    test('without a factor: blocked from producing a numeric claim', () {
      final out = co2eClaim(
          litres, registry.lookup('electric', EmissionScope.wellToWheel));
      expect(out.claim, ClaimClass.environmentalEstimate);
      expect(out.valueOrNull, isNull);
      expect(out.value,
          const DataValue<double>.unknown(
              reason: DataUnknownReason.notPublishedForThisItem));
    });

    test('unknown litres stay unknown even with a factor', () {
      final noLitres = ClaimedValue<double>.notCalculated(
          reason: DataUnknownReason.notMeasuredYet,
          claim: ClaimClass.measuredFact);
      final out = co2eClaim(
          noLitres, registry.lookup('diesel', EmissionScope.wellToWheel));
      expect(out.valueOrNull, isNull);
    });

    test('a negative quantity clamps to zero like Co2Calculator', () {
      const f = EmissionFactor(
        fuelKey: 'x',
        scope: EmissionScope.wellToWheel,
        kgCo2ePerUnit: 2.0,
        unit: EmissionUnit.kgCo2ePerLitre,
        source: 's',
        version: 'v',
        publication: '2026',
      );
      expect(f.co2eKgFor(-1), 0);
      expect(f.co2eKgFor(0), 0);
      expect(f.co2eKgFor(2), 4);
    });
  });

  group('scope labels', () {
    test('are the two boundaries #4219 names, defaulting to WtW (D8)', () {
      expect(EmissionScope.wellToWheel.label, 'WtW');
      expect(EmissionScope.tankToWheel.label, 'TtW');
      expect(EmissionFactorRegistry.defaultScope, EmissionScope.wellToWheel);
    });
  });
}
