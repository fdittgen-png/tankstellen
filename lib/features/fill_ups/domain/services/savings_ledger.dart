// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/money_tally.dart';
import '../entities/fill_up.dart';
import 'price_baseline.dart';

// #4364 — `kUnknownCurrency` moved to `core/domain/money_tally.dart`
// when currency segregation became the app-wide rule; re-exported so the
// #4136 callers of this library keep resolving it.
export '../../../../core/domain/money_tally.dart' show kUnknownCurrency;

/// One fill that beat — or missed — what this driver normally pays.
class SavingsEntry {
  const SavingsEntry({
    required this.fillUpId,
    required this.date,
    required this.litres,
    required this.pricePaid,
    required this.referencePrice,
    this.currency,
  });

  final String fillUpId;
  final DateTime date;
  final double litres;

  /// €/L actually paid, from the fill's own cost and volume.
  final double pricePaid;

  /// €/L this driver normally pays — the baseline this is measured
  /// against, carried so the claim can be reproduced (trust rule 4).
  final double referencePrice;

  /// ISO code [amount] is denominated in, or null for a fill logged
  /// before the currency was recorded (#4136).
  final String? currency;

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
///   single total — [total] is null and [totalsByCurrency] holds the
///   breakdown. Adding €40 to £40 produces a number that is true in no
///   currency at all.
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
  ///
  /// #4364 — accumulated by the canonical [MoneyTally], the one
  /// currency-segregating aggregator, so this ledger and the
  /// consumption/per-fuel summaries can never disagree about what "one
  /// currency" means.
  MoneyTally get tally => MoneyTally.of([
        for (final e in entries) (e.amount, e.currency),
      ]);

  /// Every currency present, with its own net. The key is the ISO code,
  /// or [kUnknownCurrency] for fills logged before the currency was
  /// recorded (#4136).
  Map<String, double> get totalsByCurrency => tally.byCurrency;

  /// Whether every counted fill is in the same currency.
  ///
  /// An all-unknown history counts as one: a driver who never left their
  /// country has exactly one currency and simply logged before the field
  /// existed. A history that mixes a KNOWN currency with unknowns does
  /// not, because the unknowns cannot be placed.
  bool get isSingleCurrency => tally.isSingleDenomination;

  /// Net across every counted fill — wins and misses.
  ///
  /// **Null when the history spans more than one currency.** The caller
  /// shows [totalsByCurrency] instead. There is no conversion here: a
  /// rate would have to be the rate on each fill's own date, the app
  /// does not have one, and a wrong rate is worse than two honest
  /// totals.
  double? get total => isSingleCurrency
      ? entries.fold<double>(0, (sum, e) => sum + e.amount)
      : null;

  /// Only the fills that beat the baseline. Shown BESIDE [total], never
  /// instead of it.
  double? get totalSaved => isSingleCurrency
      ? entries
          .where((e) => e.amount > 0)
          .fold<double>(0, (s, e) => s + e.amount)
      : null;
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
          currency: f.currency,
        ),
  ];
  return SavingsLedger(entries: entries, baseline: baseline);
}
