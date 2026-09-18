// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

  /// Who published it, e.g. `'EU JRC JEC Well-to-Wheels'`.
  final String source;

  /// The source's own version label, e.g. `'v5'`.
  final String version;

  /// The publication date **at the precision the citation gives** —
  /// `'2020'` when the source is cited by year. Never padded to a day
  /// the source did not state.
  final String publication;

  /// ISO region the factor is specific to, or null for the source's own
  /// boundary (EU-wide for JEC).
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
/// its own constants; [jecWtwV5] carries the same eight numbers with the
/// metadata the calculator lacks, and `emission_factor_registry_test`
/// pins the two together so they cannot drift apart silently.
@immutable
final class EmissionFactorRegistry {
  const EmissionFactorRegistry(this.factors);

  /// Fleet reports default to well-to-wheel (ADR 0025 D8).
  static const EmissionScope defaultScope = EmissionScope.wellToWheel;

  /// The v1 seed: exactly what `Co2Calculator` asserts today — eight
  /// WtW values it labels "EU JEC WTW v5 (2020)". No TtW values are
  /// published because the app can cite none; ADR 0025 records that
  /// the inherited numbers are owed a source review, and that this
  /// registry records the claim rather than correcting it.
  static const EmissionFactorRegistry jecWtwV5 =
      EmissionFactorRegistry(_jecWtwV5);

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

const String _jecSource = 'EU JEC WTW';
const String _jecVersion = 'v5';
const String _jecPublication = '2020';

/// The numbers `Co2Calculator` ships (kg CO2e per litre, CNG per kg),
/// under the label it gives them. Do not "correct" a value here — see
/// ADR 0025's consequences for the review that is owed.
const List<EmissionFactor> _jecWtwV5 = [
  EmissionFactor(
    fuelKey: 'e5',
    scope: EmissionScope.wellToWheel,
    kgCo2ePerUnit: 2.31,
    unit: EmissionUnit.kgCo2ePerLitre,
    source: _jecSource,
    version: _jecVersion,
    publication: _jecPublication,
  ),
  EmissionFactor(
    fuelKey: 'e10',
    scope: EmissionScope.wellToWheel,
    kgCo2ePerUnit: 2.27,
    unit: EmissionUnit.kgCo2ePerLitre,
    source: _jecSource,
    version: _jecVersion,
    publication: _jecPublication,
  ),
  EmissionFactor(
    fuelKey: 'e98',
    scope: EmissionScope.wellToWheel,
    kgCo2ePerUnit: 2.31,
    unit: EmissionUnit.kgCo2ePerLitre,
    source: _jecSource,
    version: _jecVersion,
    publication: _jecPublication,
  ),
  EmissionFactor(
    fuelKey: 'diesel',
    scope: EmissionScope.wellToWheel,
    kgCo2ePerUnit: 2.65,
    unit: EmissionUnit.kgCo2ePerLitre,
    source: _jecSource,
    version: _jecVersion,
    publication: _jecPublication,
  ),
  EmissionFactor(
    fuelKey: 'diesel_premium',
    scope: EmissionScope.wellToWheel,
    kgCo2ePerUnit: 2.65,
    unit: EmissionUnit.kgCo2ePerLitre,
    source: _jecSource,
    version: _jecVersion,
    publication: _jecPublication,
  ),
  EmissionFactor(
    fuelKey: 'e85',
    scope: EmissionScope.wellToWheel,
    kgCo2ePerUnit: 1.40,
    unit: EmissionUnit.kgCo2ePerLitre,
    source: _jecSource,
    version: _jecVersion,
    publication: _jecPublication,
  ),
  EmissionFactor(
    fuelKey: 'lpg',
    scope: EmissionScope.wellToWheel,
    kgCo2ePerUnit: 1.61,
    unit: EmissionUnit.kgCo2ePerLitre,
    source: _jecSource,
    version: _jecVersion,
    publication: _jecPublication,
  ),
  EmissionFactor(
    fuelKey: 'cng',
    scope: EmissionScope.wellToWheel,
    kgCo2ePerUnit: 2.54,
    unit: EmissionUnit.kgCo2ePerKilogram,
    source: _jecSource,
    version: _jecVersion,
    publication: _jecPublication,
  ),
];
