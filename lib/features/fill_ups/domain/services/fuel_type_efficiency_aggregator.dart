// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel/tank_blend_snapshot.dart';
import '../entities/fill_up.dart';
import '../entities/fuel_type_efficiency_stats.dart';
import 'fuel_type_efficiency_internals.dart';
import 'tank_blend_event_log.dart';

/// Minimum attributed closed intervals a bucket must have before the
/// "cheapest per km" verdict may crown a winner (Epic #2881).
///
/// The verdict is only shown when EVERY compared bucket that has fills clears
/// this bar — one lucky cheap tank must not crown a composition. See
/// `docs/decisions/0015-per-fuel-efficiency-composition-buckets.md`.
const int kMinAttributedIntervalsForVerdict = 2;

/// Largest minority volume share an interval may have and still count as a
/// PURE bucket (ADR 0015). Inclusive: a minority of exactly 15 % is pure
/// (equivalently, a dominant share ≥ 0.85 is pure). Above it the interval is a
/// `dominant/secondary` MIX bucket.
const double kMaxMinorityShareForPure = 0.15;

/// Pure aggregation of [FillUp] entries into per-composition-bucket
/// [FuelTypeEfficiencyStats] under the **v3 CARRIED-CONTENT COMPOSITION**
/// model (Epic #2881, #3764; rule frozen in
/// `docs/decisions/0015-per-fuel-efficiency-composition-buckets.md` — v2
/// composition buckets, amended by the #3764 v3 section — which supersedes
/// ADR 0014's dominant-fuel collapse).
///
/// No Riverpod, no Flutter — drive it directly with a list of fills.
///
/// ## Attribution (summary; the ADR is authoritative)
/// Walks CLOSED plein-to-plein intervals (the same interval definition as
/// `ConsumptionStats.fromFillUps` in `consumption_stats.dart` — replicated
/// faithfully here because that walker does not expose a per-interval hook).
/// Each closed interval's litres-by-fuel composition decides its bucket:
/// dominant ≥ 85 % volume ⇒ PURE (the dominant [FuelType]); otherwise MIX
/// (the `dominant/secondary` blend, dominant first; a 3-way blend takes the
/// two largest for the label, all litres still fold into that bucket). The
/// whole interval's litres / distance / cost fold into that bucket.
/// Corrections inherit the interval's bucket and never enter the composition
/// tally (their `totalCost` is 0, so they do not move €/km).
///
/// ## v3 (#3764) — the composition includes the CARRIED-OVER tank content
/// v2 tallied only the litres of the interval's contributing fills, which
/// made the fuel already in the tank at the opening plein invisible: 14 L of
/// E5 topped with 21 L of E85 to full burns a ~40/60 blend, yet v2 bucketed
/// the interval as pure E85. v3 classifies each interval by what the tank
/// actually HELD while it was being burned:
///
///   composition = opening content + non-correction fills STRICTLY INSIDE
///                 the interval (the closing plein is excluded — its fuel
///                 enters the NEXT interval's tank, via the mix chain)
///
/// where the opening content, knowable only at a physical opening PLEIN
/// with a known [tankCapacityL], is `capacity × the tank blend right after
/// that fill` — the evidence-only `TankBlendEngine` (#4322), the one mix
/// model the Fuel & Tank surface shows. Litres the blend attributes to no
/// grade stay unknown: the interval takes a bucket only when no
/// attribution of them could change it ([classifyComposition]). When the
/// opening content is NOT knowable (capacity unknown, the interval opens
/// on a non-plein first fill / a synthetic correction, or the unknown
/// litres leave the bucket open), the interval falls back to the v2
/// contributing-fills tally EXACTLY and is counted in
/// `legacyAttributedIntervalCount`.
///
/// Metric FOLDING is unchanged from v2: Σlitres/Σcost/Σdistance still come
/// from the contributing fills (pumped litres ≈ burned litres) — only the
/// classification tally changed. See the ADR's v3 section for the
/// price-lag consequence this keeps.
class FuelTypeEfficiencyAggregator {
  FuelTypeEfficiencyAggregator._();

  /// Compute one [FuelTypeEfficiencyStats] per composition bucket that has at
  /// least one classified interval, sorted by `avgCostPerKm` ascending
  /// (nulls last). Only buckets ACTUALLY USED appear (ADR 0015).
  ///
  /// [tankCapacityL] enables the v3 carried-content composition (#3764):
  /// when non-null, each interval opening on a physical plein is classified
  /// including the full tank's estimated mix at that fill. Null (or a
  /// non-positive value) reproduces the v2 contributing-fills behaviour for
  /// every interval, all of them marked legacy-attributed.
  static List<FuelTypeEfficiencyStats> byFuelType(
    List<FillUp> fills, {
    double? tankCapacityL,
  }) {
    if (fills.isEmpty) return const [];

    // Chronological copy so callers may pass data in any order — mirrors
    // ConsumptionStats.fromFillUps.
    final sorted = [...fills]..sort((a, b) => a.date.compareTo(b.date));

    // #3846 — what each fuel actually COST per litre, volume-weighted over
    // the real fills of that fuel. The interval's money must come from the
    // fuel that was BURNED; before this, it came from the fill that CLOSED
    // the interval, i.e. the next tank — so E5 was priced with E85's money
    // and vice versa, and the "cheapest to drive on" verdict inverted.
    //
    // #4364 — bounded to the fills up to and including the LAST CLOSING
    // plein. Priced over the whole list, a purchase logged after every
    // counted window moved the volume-weighted mean and silently
    // revalued periods that had already closed: the same history plus one
    // expensive top-up produced a different past. A report must be
    // reproducible from the windows it names.
    final prices = weightedPricePerLitre(_upToLastClose(sorted));

    // Per-bucket accumulators, keyed by FuelEfficiencyBucket.key.
    final acc = <String, BucketAcc>{};
    BucketAcc accFor(FuelEfficiencyBucket bucket) =>
        acc.putIfAbsent(bucket.key, () => BucketAcc(bucket));

    // ── Closed-interval walker (mirrors consumption_stats.dart) ──
    // An interval opens at sorted[openingIndex] (first fill, or the prior
    // closing plein) and closes at the next full-tank fill. Contributing
    // fills are those strictly AFTER the opening up to + including the close.
    var openingIndex = 0;
    final pending = <FillUp>[]; // contributing fills of the current interval
    // #4322 — the evidence-only blend after every fill, folded once. Only
    // the fill log feeds it: without recorded trips every drive between
    // fills is unmeasured, the widest honest volume interval, so no share
    // is ever credited beyond what the fills alone prove.
    final usableCapacity = tankCapacityL != null && tankCapacityL > 0;
    final blendAfter = usableCapacity
        ? tankBlendAfterEachFill(tankCapacityL: tankCapacityL, fillUps: sorted)
        : const <String, TankBlendSnapshot>{};

    for (var i = 1; i < sorted.length; i++) {
      final fill = sorted[i];
      pending.add(fill);
      if (!fill.isFullTank) continue; // interval still open

      // Interval closes here. Distance from the odometer delta, clamped at
      // 0 so an odometer reset / out-of-order import never goes negative
      // (same clamp as consumption_stats.dart).
      final distance = (fill.odometerKm - sorted[openingIndex].odometerKm)
          .clamp(0, double.infinity)
          .toDouble();
      _attributeInterval(
        pending,
        distance,
        accFor,
        openingContent:
            _openingContentAt(sorted[openingIndex], blendAfter, tankCapacityL),
        prices: prices,
      );

      openingIndex = i;
      pending.clear();
    }
    // Anything left in `pending` is the in-progress (open) window after the
    // last plein — excluded from attribution, exactly like the walker.

    final result = [
      for (final a in acc.values) a.toStats(),
    ];
    // Sort by €/km ascending; nulls (no usable distance) last. Stable
    // secondary sort by bucket key for deterministic ordering on ties.
    result.sort((x, y) {
      final cx = x.avgCostPerKm;
      final cy = y.avgCostPerKm;
      if (cx == null && cy == null) {
        return x.bucket.key.compareTo(y.bucket.key);
      }
      if (cx == null) return 1;
      if (cy == null) return -1;
      final byCost = cx.compareTo(cy);
      if (byCost != 0) return byCost;
      return x.bucket.key.compareTo(y.bucket.key);
    });
    return result;
  }

  /// The prefix of [sorted] the counted closed intervals actually cover:
  /// everything up to and including the LAST full-tank fill (#4364).
  ///
  /// Fills after it are the in-progress window, which the walker never
  /// attributes. Letting their prices into the pricing table is how an
  /// unrelated later purchase rewrote a closed period's cost.
  static List<FillUp> _upToLastClose(List<FillUp> sorted) {
    for (var i = sorted.length - 1; i >= 1; i--) {
      if (sorted[i].isFullTank) return sorted.sublist(0, i + 1);
    }
    return const [];
  }

  /// The lowest-`avgCostPerKm` bucket — but ONLY when every entry that has
  /// fills has `attributedIntervalCount >= kMinAttributedIntervalsForVerdict`.
  /// Returns `null` below the threshold (no crown) or when no bucket has a
  /// non-null €/km. Compares across ALL buckets (pure + mix — ADR 0015).
  static FuelEfficiencyBucket? cheapestPerKm(
    List<FuelTypeEfficiencyStats> stats,
  ) {
    if (stats.isEmpty) return null;
    final withFills = stats.where((s) => s.fillCount > 0);
    final everyBucketHasEnough = withFills.every(
      (s) => s.attributedIntervalCount >= kMinAttributedIntervalsForVerdict,
    );
    if (!everyBucketHasEnough) return null;

    FuelTypeEfficiencyStats? best;
    for (final s in stats) {
      if (s.avgCostPerKm == null) continue;
      if (best == null || s.avgCostPerKm! < best.avgCostPerKm!) {
        best = s;
      }
    }
    return best?.bucket;
  }

  /// The per-fuel litres in the tank right AFTER the [opening] fill — the
  /// interval's carried-over opening content (v3, #3764). Knowable only
  /// when the opening fill is a physical PLEIN and [tankCapacityL] is
  /// known: the content is then the full tank, as the evidence-only blend
  /// after that fill describes it (#4322), unknown litres included.
  /// Returns null — the caller falls back to the v2 contributing-fills
  /// tally and marks the interval legacy-attributed — when the capacity is
  /// unknown/non-positive, the opening fill is not a full tank (only
  /// possible for the very first fill), it is a synthetic correction
  /// (#1361 — never a physical visit to a pump), or the blend guarantees
  /// no grade at all.
  static OpeningContent? _openingContentAt(
    FillUp opening,
    Map<String, TankBlendSnapshot> blendAfter,
    double? tankCapacityL,
  ) {
    if (tankCapacityL == null || tankCapacityL <= 0) return null;
    if (!opening.isFullTank || opening.isCorrection) return null;
    final after = blendAfter[opening.id];
    return after == null ? null : OpeningContent.ofBlend(after, tankCapacityL);
  }

  /// Classify the interval into a PURE or MIX [FuelEfficiencyBucket] by its
  /// composition (ADR 0015) and fold the interval's litres / distance / cost
  /// (incl. corrections, which inherit the bucket) into that bucket.
  ///
  /// The composition tally is v3 (#3764) when [openingContent] is known:
  /// the carried-over tank content plus the non-correction fills STRICTLY
  /// INSIDE the interval (the closing plein excluded — its fuel enters the
  /// next interval's tank). Otherwise the v2 legacy tally over ALL the
  /// [contributing] non-correction fills (closing plein included), and the
  /// interval is counted legacy-attributed — also when the opening
  /// content's unknown litres leave the v3 bucket open (#4322).
  static void _attributeInterval(
    List<FillUp> contributing,
    double distance,
    BucketAcc Function(FuelEfficiencyBucket) accFor, {
    required OpeningContent? openingContent,
    required FuelPriceTable prices,
  }) {
    if (contributing.isEmpty) return;

    // An interval of corrections-only has no physical fill to credit —
    // attribute nothing, exactly as v2, even when the opening content is
    // known (a full-tank correction never was a visit to a pump, #1361).
    if (contributing.every((f) => f.isCorrection)) return;

    // v3: only the fills strictly inside the interval join the burned-tank
    // tally; the closing plein (always the last contributing entry) refuels
    // the NEXT tank.
    var tally = openingContent == null
        ? null
        : _tally(contributing.sublist(0, contributing.length - 1),
            from: openingContent);
    var bucket = tally == null
        ? null
        : classifyComposition(tally.litresByFuel, tally.fuelByApiValue,
            unknownLitres: openingContent!.unknownLitres);
    // Legacy/v2: every contributing fill, close included.
    final legacy = bucket == null;
    if (legacy) tally = _tally(contributing);
    final litresByFuel = tally!.litresByFuel;

    // No composition at all (legacy corrections-only interval) — attribute
    // nothing (its litres/distance/cost have no real fuel to credit).
    if (litresByFuel.isEmpty) return;
    bucket ??= classifyComposition(litresByFuel, tally.fuelByApiValue)!;

    // Litres + cost include corrections (they inherit the bucket); distance
    // is the whole interval's odometer delta. fillCount counts only the
    // non-correction fills folded into this bucket.
    var intervalLitres = 0.0;
    var pricedLitres = 0.0;
    var intervalFills = 0;
    // #4364 — what the pump ACTUALLY charged for this interval's fills,
    // kept per denomination and apart from the modelled valuation below.
    final recorded = <(double, String?)>[];
    var unpriced = 0;
    for (final f in contributing) {
      // Litres stay the plein-to-plein REFILL volume — that is what was
      // burned over the interval, and it is what avgL100km must use.
      // Corrections are included here (they inherit the bucket and DO
      // represent fuel that went through the engine).
      intervalLitres += f.liters;
      if (f.isCorrection) continue;
      // ...but they are never PRICED: a correction is a bookkeeping
      // adjustment, not a visit to a pump, and carries no money. Pricing
      // its litres would invent a purchase — a 999 L correction priced at
      // the fuel's rate produced 2.57 EUR/km in the #3846 first draft.
      pricedLitres += f.liters;
      intervalFills += 1;
      if (f.totalCost > 0) {
        recorded.add((f.totalCost, f.currency));
      } else {
        unpriced += 1;
      }
    }

    // #3846 — money follows the fuel BURNED. Split the burned volume across
    // the interval's composition and price each share at what that fuel
    // actually cost, instead of charging the interval whatever was paid at
    // the pump that closed it (which bought the NEXT tank, often a
    // different fuel). Only litres a grade is guaranteed to hold are priced
    // (#4322): the burned volume is split over the characterised part of
    // the tank, never charged at a price guessed for its unknown litres.
    final compositionLitres =
        litresByFuel.values.fold<double>(0, (a, b) => a + b);
    var intervalCost = 0.0;
    if (compositionLitres > 0) {
      for (final entry in litresByFuel.entries) {
        final price = prices.pricePerLitre[entry.key];
        if (price == null) continue; // never invent a price
        final burnedShare = entry.value / compositionLitres;
        intervalCost += pricedLitres * burnedShare * price;
      }
    }

    final a = accFor(bucket);
    a.intervalLitres += intervalLitres;
    a.intervalDistance += distance;
    a.intervalCost += intervalCost;
    a.attributedIntervalCount += 1;
    if (legacy) a.legacyAttributedIntervalCount += 1;
    a.fillCount += intervalFills;
    for (final (amount, currency) in recorded) {
      a.recordedSpend = a.recordedSpend.plus(amount, currency);
    }
    a.unpricedFillCount += unpriced;
    if (prices.mixedCurrencies) a.pricingDenominable = false;
  }

  /// Litres per fuel of [fills] (corrections never enter a composition
  /// tally), on top of the known part of [from] when given.
  static OpeningContent _tally(List<FillUp> fills, {OpeningContent? from}) {
    final litres = {...?from?.litresByFuel};
    final fuels = {...?from?.fuelByApiValue};
    for (final f in fills) {
      if (f.isCorrection) continue;
      litres.update(f.fuelType.apiValue, (v) => v + f.liters,
          ifAbsent: () => f.liters);
      fuels[f.fuelType.apiValue] = f.fuelType;
    }
    return OpeningContent(litres, fuels);
  }
}
