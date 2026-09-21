// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import '../data_value.dart';
import 'claim_class.dart';
import 'fleet_provenance.dart';

/// The system boundary an emission factor covers (#4219, ADR 0025 D8).
enum EmissionScope {
  /// Combustion only.
  tankToWheel('TtW'),

  /// Production, distribution and combustion. The fleet default, so
  /// fleet reports agree with the personal carbon dashboard.
  wellToWheel('WtW');

  const EmissionScope(this.label);

  /// The conventional abbreviation, for citations and wire rows (not a
  /// translated string — it is the same in every language).
  final String label;
}

/// The unit the factor multiplies.
enum EmissionUnit { kgCo2ePerLitre, kgCo2ePerKilogram, kgCo2ePerKilowattHour }

/// One cited emission factor: the number and everything needed to say
/// where it came from.
@immutable
final class EmissionFactor {
  const EmissionFactor({
    required this.fuelKey,
    required this.scope,
    required this.kgCo2ePerUnit,
    required this.unit,
    required this.source,
    required this.version,
    required this.publication,
    this.geography,
  });

  /// `FuelType.apiValue` (lowercase) — `'diesel'`, `'e10'`, `'cng'`, …
  final String fuelKey;

  final EmissionScope scope;

  /// kg CO2e per [unit].
  final double kgCo2ePerUnit;

  final EmissionUnit unit;

  /// Who published it, e.g. `'ADEME Base Carbone'`.
  final String source;

  /// The source's own version label, e.g. `'v23.6'`.
  final String version;

  /// The publication date **at the precision the citation gives** —
  /// `'2026'` when the source is cited by year. Never padded to a day
  /// the source did not state.
  final String publication;

  /// ISO region the factor is specific to, or null to apply the factor
  /// exactly as published, under the source's own boundary (*France
  /// continentale* for ADEME Base Carbone). A country-specific table —
  /// DESNZ for `GB`, say — is layered on later through this axis; it is
  /// not a reason to fudge the rows that exist.
  final String? geography;

  /// `source version (publication)` — what a report prints beside the
  /// number.
  String get citation => '$source $version ($publication)';

  /// kg CO2e for [quantity] units. Negative quantities clamp to zero,
  /// as `Co2Calculator.co2ForLiters` does.
  double co2eKgFor(double quantity) =>
      quantity <= 0 ? 0 : quantity * kgCo2ePerUnit;

  @override
  bool operator ==(Object other) =>
      other is EmissionFactor &&
      other.fuelKey == fuelKey &&
      other.scope == scope &&
      other.kgCo2ePerUnit == kgCo2ePerUnit &&
      other.unit == unit &&
      other.source == source &&
      other.version == version &&
      other.publication == publication &&
      other.geography == geography;

  @override
  int get hashCode => Object.hash(fuelKey, scope, kgCo2ePerUnit, unit,
      source, version, publication, geography);

  @override
  String toString() =>
      'EmissionFactor($fuelKey ${scope.label} $kgCo2ePerUnit ${unit.name} '
      '— $citation${geography == null ? '' : ' $geography'})';
}

/// A versioned factor registry (#4219): every factor is cited; a lookup
/// that finds nothing says so — never `0`, never a neighbour's value.
///
/// `Co2Calculator` keeps computing the personal carbon dashboard from
/// its own constants; [ademeBaseCarbone] carries those same well-to-wheel
/// numbers with the metadata the calculator lacks — *and* the
/// tank-to-wheel half of every one of them (#4392).
/// `emission_factor_registry_test` pins the two together in both
/// directions so they cannot drift apart silently.
@immutable
final class EmissionFactorRegistry {
  const EmissionFactorRegistry(this.factors);

  /// Fleet reports default to well-to-wheel (ADR 0025 D8).
  static const EmissionScope defaultScope = EmissionScope.wellToWheel;

  /// The v2 seed (#4392): ADEME Base Carbone® v23.6, both boundaries,
  /// for every fuel the app sells by volume. Electricity and hydrogen
  /// are deliberately absent — the app measures no kWh and no kg of H2,
  /// so publishing a factor for them would be a citation with nothing
  /// to multiply.
  static const EmissionFactorRegistry ademeBaseCarbone =
      EmissionFactorRegistry(_ademeBaseCarbone);

  /// Every factor, in seed order.
  final List<EmissionFactor> factors;

  /// The factor for [fuelKey] under [scope], as a class-average estimate
  /// ([DataBasis.fleetAverage] — a fuel-pathway average is specific to
  /// nothing about *this* vehicle). A [geography]-specific factor wins;
  /// the source's own boundary (`geography == null`) is the fallback;
  /// anything else is [DataUnknownReason.notPublishedForThisItem].
  DataValue<EmissionFactor> lookup(
    String fuelKey,
    EmissionScope scope, {
    String? geography,
  }) {
    final key = fuelKey.toLowerCase();
    EmissionFactor? boundary;
    for (final f in factors) {
      if (f.fuelKey != key || f.scope != scope) continue;
      if (geography != null && f.geography == geography) {
        return DataValue.estimated(f, basis: DataBasis.fleetAverage);
      }
      if (f.geography == null) boundary ??= f;
    }
    if (boundary != null) {
      return DataValue.estimated(boundary, basis: DataBasis.fleetAverage);
    }
    return const DataValue.unknown(
        reason: DataUnknownReason.notPublishedForThisItem);
  }

  /// Which scopes are published for [fuelKey] at all.
  Set<EmissionScope> publishedScopesFor(String fuelKey) {
    final key = fuelKey.toLowerCase();
    return {for (final f in factors) if (f.fuelKey == key) f.scope};
  }
}

/// The class-5 claim: [quantity] (litres, or kg for CNG) × [factor].
///
/// Without a factor the result is `Unknown` under
/// [ClaimClass.environmentalEstimate] — a report renders "not
/// calculated", never a number (#4219: "never substitutes an
/// undocumented factor").
ClaimedValue<double> co2eClaim(
  ClaimedValue<double> quantity,
  DataValue<EmissionFactor> factor,
) =>
    ClaimedValue.derive<double>(
      [
        quantity,
        ClaimedValue<EmissionFactor>.unchecked(factor,
            claim: ClaimClass.environmentalEstimate,
            provenance: const [FleetMetricSource.derived]),
      ],
      (v) => (v[1]! as EmissionFactor).co2eKgFor(v[0]! as double),
      claim: ClaimClass.environmentalEstimate,
    );

const String _src = 'ADEME Base Carbone';
const String _ver = 'v23.6';
const String _pub = '2026';
const EmissionScope _ttw = EmissionScope.tankToWheel;
const EmissionScope _wtw = EmissionScope.wellToWheel;
const EmissionUnit _perL = EmissionUnit.kgCo2ePerLitre;
const EmissionUnit _perKg = EmissionUnit.kgCo2ePerKilogram;

/// ADEME Base Carbone® v23.6 (updated 2026-06-30, Licence Ouverte),
/// boundary *France continentale*, category `Combustibles > Fossiles >
/// Liquides > Usage sources mobiles > Usage routier`. Each element
/// publishes a total and a two-poste split; the app reads the
/// `Combustion` poste as tank-to-wheel and the element total
/// (`Amont` + `Combustion`) as well-to-wheel:
///
/// | element | grade | Combustion | Amont | total |
/// |---|---|---|---|---|
/// | 25763 | Supercarburant sans plomb (95, 95-E10, 98) | 2.20 | 0.491 | 2.69 |
/// | 13988 | Essence E10 | 2.19 | 0.502 | 2.69 |
/// | 25766 | Essence E85 | 0.366 | 0.743 | 1.11 |
/// | 25775 | Gazole routier B7 | 2.49 | 0.609 | 3.10 |
/// | 14031 | GPL pour véhicule routier (per litre) | 1.60 | 0.257 | 1.86 |
/// | 27095 | GNC pour véhicule routier (per kg) | 2.41 | 0.545 | 2.96 |
///
/// Cross-checks on the well-to-wheel column, for order of magnitude
/// only — neither is seeded, because neither publishes per-litre values
/// for these grades directly:
///
/// * Directive (EU) 2018/2001 (RED II) Annex V Part C point 19 puts the
///   fossil-fuel comparator at 94 gCO2eq/MJ; at Annex III's 32 MJ/l
///   (petrol) and 36 MJ/l (diesel) that is 3.01 and 3.38 kg CO2e/L.
///   (Council Directive (EU) 2015/652's per-fuel defaults — 93.3 and
///   95.1 gCO2eq/MJ — say the same, but that instrument was repealed
///   with effect from 2025-01-01 by Directive (EU) 2023/2413 Art. 6,
///   so it is history, not a source.)
/// * UK DESNZ GHG conversion factors 2026 (Scope 1 + Scope 3 "WTT-")
///   give 2.96 kg CO2e/L for 100% mineral petrol and 3.29 for 100%
///   mineral diesel. Its forecourt-blend rows are not comparable: the
///   Scope 1 half books biofuel combustion CO2 as net zero and parks
///   it on an "Outside of scopes" sheet.
///
/// ADEME sits below both because its `Amont` reflects the French
/// refining and electricity mix. Do not average them: one row, one
/// source.
const List<EmissionFactor> _ademeBaseCarbone = [
  // Petrol — SP95 (E5) and SP98 are named in element 25763 itself.
  EmissionFactor(fuelKey: 'e5', scope: _ttw, kgCo2ePerUnit: 2.20,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'e5', scope: _wtw, kgCo2ePerUnit: 2.69,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'e98', scope: _ttw, kgCo2ePerUnit: 2.20,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'e98', scope: _wtw, kgCo2ePerUnit: 2.69,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  // E10 has its own element (13988) — same total, 0.01 lower on burn.
  EmissionFactor(fuelKey: 'e10', scope: _ttw, kgCo2ePerUnit: 2.19,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'e10', scope: _wtw, kgCo2ePerUnit: 2.69,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  // Diesel — ADEME publishes one road grade, B7; premium shares it.
  EmissionFactor(fuelKey: 'diesel', scope: _ttw, kgCo2ePerUnit: 2.49,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'diesel', scope: _wtw, kgCo2ePerUnit: 3.10,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'diesel_premium', scope: _ttw,
      kgCo2ePerUnit: 2.49, unit: _perL, source: _src, version: _ver,
      publication: _pub),
  EmissionFactor(fuelKey: 'diesel_premium', scope: _wtw,
      kgCo2ePerUnit: 3.10, unit: _perL, source: _src, version: _ver,
      publication: _pub),
  // E85 — the biogenic CO2 burnt at the tailpipe is booked against the
  // uptake upstream in ADEME's own CO2b column, which is why the
  // combustion poste is 0.366 and not ~1.6.
  EmissionFactor(fuelKey: 'e85', scope: _ttw, kgCo2ePerUnit: 0.366,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'e85', scope: _wtw, kgCo2ePerUnit: 1.11,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'lpg', scope: _ttw, kgCo2ePerUnit: 1.60,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'lpg', scope: _wtw, kgCo2ePerUnit: 1.86,
      unit: _perL, source: _src, version: _ver, publication: _pub),
  // CNG is sold per kilogram, and ADEME publishes it per kilogram.
  EmissionFactor(fuelKey: 'cng', scope: _ttw, kgCo2ePerUnit: 2.41,
      unit: _perKg, source: _src, version: _ver, publication: _pub),
  EmissionFactor(fuelKey: 'cng', scope: _wtw, kgCo2ePerUnit: 2.96,
      unit: _perKg, source: _src, version: _ver, publication: _pub),
];
