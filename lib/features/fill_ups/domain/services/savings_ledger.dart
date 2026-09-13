// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel_type.dart';
import '../entities/fill_up.dart';
import 'price_baseline.dart';

/// One fill that beat — or missed — what this driver normally pays.
class SavingsEntry {
  const SavingsEntry({
    required this.fillUpId,
    required this.date,
    required this.litres,
    required this.pricePaid,
    required this.referencePrice,
  });

  final String fillUpId;
  final DateTime date;
  final double litres;

  /// €/L actually paid, from the fill's own cost and volume.
  final double pricePaid;

  /// €/L this driver normally pays — the baseline this is measured
  /// against, carried so the claim can be reproduced (trust rule 4).
  final double referencePrice;

  /// Positive when the fill beat the baseline, negative when it did not.
  ///
  /// Signed on purpose: a ledger that only counted the wins would be a
  /// marketing number, and the total it rolled up would be a lie of
  /// omission.
  double get amount => (referencePrice - pricePaid) * litres;
}

/// What the driver saved against their own normal price (#4136).
///
/// ## Why this is DERIVED and not stored
///
/// The issue proposed a Hive box of entries written per fill-up. Deriving
/// instead makes several of its own acceptance criteria free rather than
/// implemented: deleting a fill-up removes its entry, editing one
/// corrects it, and the ledger can never drift from the fill-ups it
/// describes because there is no second copy to drift. It also needs no
/// new box, no export entry, no GDPR registry line and no sync decision.
///
/// The cost is recomputation, over a few hundred fills — cheaper than
/// the reconciliation a second source of truth would eventually need.
///
/// ## What it refuses to count
///
/// * **No baseline, no ledger.** Below [kMinBaselineSamples] fills there
///   is nothing honest to measure against (trust rule 1).
/// * **Only fills inside the baseline window**, against the baseline of
///   their own fuel. Comparing an E85 fill to a diesel average would be
///   arithmetic, not a saving.
/// * **Corrections are excluded**, as everywhere else.
/// * **One currency.** A history spanning two currencies produces no
///   total rather than a silently summed one.
class SavingsLedger {
  const SavingsLedger({required this.entries, required this.baseline});

  const SavingsLedger.unavailable()
      : entries = const [],
        baseline = null;

  final List<SavingsEntry> entries;

  /// Null when there was not enough history to measure anything.
  final PriceBaseline? baseline;

  bool get isAvailable => baseline != null;

  /// Net across every counted fill — wins and misses.
  double get total => entries.fold<double>(0, (sum, e) => sum + e.amount);

  /// Only the fills that beat the baseline. Shown BESIDE [total], never
  /// instead of it.
  double get totalSaved =>
      entries.where((e) => e.amount > 0).fold<double>(0, (s, e) => s + e.amount);
}

/// Build the ledger for one fuel from the driver's own history.
SavingsLedger savingsLedgerFor(
  Iterable<FillUp> fillUps, {
  required FuelType fuelType,
  required DateTime now,
}) {
  final baseline =
      priceBaselineFor(fillUps, fuelType: fuelType, now: now);
  if (baseline == null) return const SavingsLedger.unavailable();

  final cutoff = now.subtract(kBaselineWindow);
  final entries = <SavingsEntry>[
    for (final f in fillUps)
      if (!f.isCorrection &&
          f.fuelType == fuelType &&
          f.liters > 0 &&
          f.totalCost > 0 &&
          f.date.isAfter(cutoff))
        SavingsEntry(
          fillUpId: f.id,
          date: f.date,
          litres: f.liters,
          pricePaid: f.totalCost / f.liters,
          referencePrice: baseline.typicalPricePerLitre,
        ),
  ];
  return SavingsLedger(entries: entries, baseline: baseline);
}
