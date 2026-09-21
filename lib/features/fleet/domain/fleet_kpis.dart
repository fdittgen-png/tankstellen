// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../../core/domain/data_value.dart';
import '../../../core/domain/fleet/claim_class.dart';

/// One vehicle's figures for one period, exactly as
/// `fleet_period_metrics` returned them (#4216, #4214 KPIs).
///
/// Every number is a [ClaimedValue], so what it may be used for travels
/// with it: litres and spend are class-1 facts off a confirmed receipt,
/// cost/km and L/100 km are class-2 arithmetic over those facts, CO2e is
/// a class-5 environmental estimate under a **named** factor. Nothing
/// here can promote one into another — [ClaimedValue.derive] refuses
/// `measuredFact` as a derivation target, and degrades
/// `calculatedOperational` to `estimate` the moment an input is
/// qualified.
///
/// A [suppressed] row is not an empty row. The server returned the
/// vehicle and then withheld every figure because the period held fewer
/// samples than the organisation's `aggregationMinSamples` (ADR 0025
/// D5.3) — including the sample count itself, so the manager cannot
/// read "one refuelling in March" off the absence. The UI says which
/// threshold applied; it never renders a zero.
@immutable
final class FleetVehicleMetrics {
  const FleetVehicleMetrics({
    required this.fleetVehicleId,
    required this.suppressed,
    required this.spend,
    required this.currency,
    required this.litres,
    required this.km,
    required this.co2eKg,
    required this.co2FactorVersion,
    required this.measuredShare,
    required this.sampleCount,
  });

  /// A row the server suppressed: the vehicle is named, nothing else is.
  factory FleetVehicleMetrics.suppressedRow(String fleetVehicleId) =>
      FleetVehicleMetrics(
        fleetVehicleId: fleetVehicleId,
        suppressed: true,
        spend: _absent(ClaimClass.calculatedOperational),
        currency: null,
        litres: _absent(ClaimClass.measuredFact),
        km: _absent(ClaimClass.measuredFact),
        co2eKg: _absent(ClaimClass.environmentalEstimate),
        co2FactorVersion: null,
        measuredShare: _absent(ClaimClass.calculatedOperational),
        sampleCount: 0,
      );

  /// The company asset, never the employee who drove it.
  final String fleetVehicleId;

  /// Below the organisation's aggregation threshold — every figure is
  /// deliberately absent (D5.3).
  final bool suppressed;

  /// Total charged in [currency]. Absent when the period mixed
  /// currencies: there is no exchange rate here.
  final ClaimedValue<double> spend;

  /// The ISO 4217 code [spend] is in, or null when there is no single
  /// one.
  final String? currency;

  /// Litres dispensed — the sum of confirmed pump readings.
  final ClaimedValue<double> litres;

  /// Distance from odometer readings printed on the receipts. Absent
  /// when the period held fewer than two of them; a distance is not
  /// invented from one.
  final ClaimedValue<double> km;

  /// Class 5. Absent — "not calculated" — when any grade in the period
  /// has no published factor (#4219).
  final ClaimedValue<double> co2eKg;

  /// The factor's own citation plus its boundary, e.g.
  /// `ADEME Base Carbone v23.6 (2026) WtW`. Non-null exactly when
  /// [co2eKg] is known, so a number can never print without its source.
  final String? co2FactorVersion;

  /// The share of the period's litres that sits on a receipt carrying
  /// an odometer reading — how much of the efficiency figure measured
  /// distance actually covers.
  final ClaimedValue<double> measuredShare;

  /// How many expenses the period holds. Zero for a suppressed row.
  final int sampleCount;

  /// Class 2: [spend] / [km]. An unknown input stays unknown.
  ClaimedValue<double> get costPerKm => ClaimedValue.derive<double>(
        [spend, km],
        (v) => (v[0]! as double) / (v[1]! as double),
        claim: ClaimClass.calculatedOperational,
      );

  /// Class 2: litres per 100 km.
  ClaimedValue<double> get lPer100Km => ClaimedValue.derive<double>(
        [litres, km],
        (v) => (v[0]! as double) * 100 / (v[1]! as double),
        claim: ClaimClass.calculatedOperational,
      );
}

/// The fleet-wide roll-up of a period (#4216, #4214).
///
/// Three properties it exists to hold, and each one is a rule the
/// dashboard above it cannot break:
///
///  * **provenance survives the sum.** Every total goes through
///    [ClaimedValue.derive], so a measured figure pooled with an
///    estimated one comes out estimated and carries `≈`. A measured
///    fleet total over one estimated vehicle is not a thing this type
///    can produce;
///  * **more than one currency yields no total.** [spend] is null and
///    [spendByCurrency] holds the breakdown — the same refusal
///    `SavingsLedger.total` and `Money.plus` make on the device, for
///    the same reason: €40 + £40 is a number true in no currency;
///  * **an absence is stated, never zeroed.** A figure no vehicle could
///    supply comes back [Unknown] with its reason, and the screen
///    renders "not calculated" rather than `0`.
///
/// Suppressed rows contribute to [suppressedCount] and to nothing else.
/// They are counted so the manager is told that vehicles exist which
/// the threshold hides — absence with an explanation, rather than a
/// fleet that looks smaller than it is.
@immutable
final class FleetKpis {
  const FleetKpis._({
    required this.vehicles,
    required this.spendByCurrency,
    required this.litres,
    required this.km,
    required this.co2eKg,
    required this.co2FactorVersion,
    required this.measuredShare,
    required this.sampleCount,
  });

  /// Roll [rows] up. Deterministic: same rows in, same figures out.
  factory FleetKpis.over(Iterable<FleetVehicleMetrics> rows) {
    final all = List<FleetVehicleMetrics>.unmodifiable(rows);
    final reported = [for (final r in all) if (!r.suppressed) r];

    final byCurrency = <String, List<ClaimedValue<double>>>{};
    for (final r in reported) {
      final code = r.currency;
      if (code == null || !r.spend.value.isKnown) continue;
      (byCurrency[code.toUpperCase()] ??= []).add(r.spend);
    }

    // A factor version the whole fleet agrees on, or none. Two versions
    // in one report would be two methodologies added together, which
    // #4216 forbids in as many words.
    final versions = <String>{
      for (final r in reported)
        if (r.co2FactorVersion != null) r.co2FactorVersion!,
    };

    return FleetKpis._(
      vehicles: all,
      spendByCurrency: Map.unmodifiable({
        for (final e in byCurrency.entries)
          e.key: _sum(e.value, ClaimClass.calculatedOperational),
      }),
      litres: _sum(
          [for (final r in reported) r.litres], ClaimClass.calculatedOperational),
      km: _sum(
          [for (final r in reported) r.km], ClaimClass.calculatedOperational),
      // CO2 is the one total that does NOT skip its gaps. A missing
      // litre of distance still leaves the fuel that was measured; a
      // missing emission FACTOR leaves a period whose emissions are
      // partly unknown, and a partial sum labelled as the period's
      // CO2e is exactly the undocumented substitution #4219 forbids.
      co2eKg: versions.length == 1
          ? _sum([for (final r in reported) r.co2eKg],
              ClaimClass.environmentalEstimate, skipUnknown: false)
          : _absent(ClaimClass.environmentalEstimate),
      co2FactorVersion: versions.length == 1 ? versions.first : null,
      measuredShare: _litreWeightedShare(reported),
      sampleCount: reported.fold<int>(0, (s, r) => s + r.sampleCount),
    );
  }

  /// Every row the period returned, suppressed ones included.
  final List<FleetVehicleMetrics> vehicles;

  /// One total per ISO 4217 code, over the rows that reported one.
  final Map<String, ClaimedValue<double>> spendByCurrency;

  /// Litres across the fleet.
  final ClaimedValue<double> litres;

  /// Distance across the fleet, over the vehicles that had odometer
  /// evidence. [measuredShare] says how much of the fuel that covers.
  final ClaimedValue<double> km;

  /// Class 5, and only when every reporting vehicle used the same
  /// factor version — see [co2FactorVersion].
  final ClaimedValue<double> co2eKg;

  /// The one factor citation behind [co2eKg], or null when there is
  /// none or the fleet disagrees. A report prints this beside the
  /// number or prints "not calculated" instead (#4219).
  final String? co2FactorVersion;

  /// Litre-weighted share of the fleet's fuel backed by measured
  /// distance.
  final ClaimedValue<double> measuredShare;

  /// Expenses behind the figures.
  final int sampleCount;

  /// The rows the server was willing to report.
  List<FleetVehicleMetrics> get reported =>
      [for (final r in vehicles) if (!r.suppressed) r];

  /// How many vehicles the aggregation threshold hid (D5.3).
  int get suppressedCount => vehicles.length - reported.length;

  /// Whether every reported spend is in one currency (an empty fleet
  /// counts as one, like `SavingsLedger.isSingleCurrency`).
  bool get isSingleCurrency => spendByCurrency.length <= 1;

  /// The fleet's fuel spend — **null when the period spans more than
  /// one currency**, in which case the caller shows [spendByCurrency].
  ClaimedValue<double>? get spend {
    if (!isSingleCurrency) return null;
    for (final v in spendByCurrency.values) {
      return v;
    }
    return null;
  }

  /// The ISO code [spend] is in, or null when there is no single one.
  String? get currency {
    if (!isSingleCurrency) return null;
    for (final k in spendByCurrency.keys) {
      return k;
    }
    return null;
  }

  /// Class 2: fleet cost per kilometre. Absent across currencies.
  ClaimedValue<double> get costPerKm {
    final total = spend;
    if (total == null) return _absent(ClaimClass.calculatedOperational);
    return ClaimedValue.derive<double>(
      [total, km],
      (v) => (v[0]! as double) / (v[1]! as double),
      claim: ClaimClass.calculatedOperational,
    );
  }

  /// Class 2: fleet litres per 100 km.
  ClaimedValue<double> get lPer100Km => ClaimedValue.derive<double>(
        [litres, km],
        (v) => (v[0]! as double) * 100 / (v[1]! as double),
        claim: ClaimClass.calculatedOperational,
      );
}

/// "Not calculated", under the class the figure would have had.
ClaimedValue<double> _absent(ClaimClass claim) =>
    ClaimedValue<double>.notCalculated(
        reason: DataUnknownReason.notMeasuredYet, claim: claim);

/// Sum the inputs, keeping provenance and adding up the evidence.
///
/// With [skipUnknown] (the default) an unknown input is left out
/// rather than short-circuiting the whole total: one vehicle without
/// an odometer must not erase the distance the rest of the fleet did
/// measure. What that must not do is hide the gap, which is why
/// [FleetKpis.measuredShare] and the attention list exist.
///
/// [skipUnknown] is false for the totals where a gap invalidates the
/// figure rather than shrinking it — CO2e, where a missing factor
/// makes the period's emissions partly unknown and a partial sum
/// would be presented as the whole. With nothing known at all the
/// result is an absence either way.
///
/// [ClaimedValue.derive] supplies the part that matters: if any
/// contributing figure is qualified the sum is qualified too, so a
/// measured total over an estimated input cannot be produced. The
/// sample count it computes is the minimum over the inputs, which is
/// the right rule for a RATIO and the wrong one for a SUM — a total
/// rests on every observation under it — so the result is re-stamped
/// with the total.
ClaimedValue<double> _sum(
  List<ClaimedValue<double>> inputs,
  ClaimClass claim, {
  bool skipUnknown = true,
}) {
  final known = [for (final i in inputs) if (i.value.isKnown) i];
  if (known.isEmpty) return _absent(claim);
  if (!skipUnknown && known.length != inputs.length) {
    // `derive` would short-circuit on the unknown anyway; this states
    // the rule where a reader looks for it, and keeps the reason the
    // fleet's own rather than one vehicle's.
    return _absent(claim);
  }
  final summed = ClaimedValue.derive<double>(
    known,
    (v) => v.fold<double>(0, (s, x) => s + (x! as double)),
    claim: claim,
  );
  final samples = known.fold<int>(0, (s, i) => s + i.sampleCount);
  return ClaimedValue<double>.unchecked(summed.value,
      claim: summed.claim,
      sampleCount: samples,
      provenance: summed.provenance);
}

/// The fleet's measured coverage, weighted by litres rather than by
/// vehicle: a van that burns ten times the fuel moves the number ten
/// times as much, which is what "share of the fleet's consumption
/// backed by measured data" means.
ClaimedValue<double> _litreWeightedShare(List<FleetVehicleMetrics> rows) {
  var litres = 0.0;
  var covered = 0.0;
  final contributing = <ClaimedValue<double>>[];
  for (final r in rows) {
    final l = r.litres.valueOrNull;
    final s = r.measuredShare.valueOrNull;
    if (l == null || s == null || l <= 0) continue;
    litres += l;
    covered += l * s;
    contributing.add(r.measuredShare);
  }
  if (litres <= 0) return _absent(ClaimClass.calculatedOperational);
  final share = covered / litres;
  return ClaimedValue.derive<double>(
    contributing,
    (_) => share,
    claim: ClaimClass.calculatedOperational,
  );
}
