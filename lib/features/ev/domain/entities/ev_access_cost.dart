// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'ev_price.dart';

/// What the user-facing free/paid access signal is for a charging
/// station, derived from OpenChargeMap's `UsageType` object (#2618).
///
/// OCM already fetches a structured `UsageType` ({IsPayAtLocation,
/// IsMembershipRequired, Title}) but the search service used to discard
/// it. [EvAccessCost.from] is the single source of truth that turns the
/// flags + title + the free-form `UsageCost` text into one of these
/// kinds — no other layer string-matches the access signal.
enum EvAccessCostKind {
  /// Charging is free of charge (no payment, no membership).
  free,

  /// Payment is required at the location (pay-as-you-go tariff).
  paid,

  /// A network membership / RFID card is required to charge.
  membership,

  /// The signal could not be classified — the UI shows no badge.
  unknown,
}

/// A classified free/paid access signal for a [ChargingStation].
///
/// Immutable value type. Construct via [EvAccessCost.from]; the decision
/// rule there is the only place that interprets OCM's `UsageType` flags,
/// the `UsageType.Title`, and the indicative `UsageCost` string.
class EvAccessCost {
  /// The classified access kind.
  final EvAccessCostKind kind;

  const EvAccessCost(this.kind);

  /// `true` when the signal is classified (worth rendering a badge).
  bool get isKnown => kind != EvAccessCostKind.unknown;

  /// Classifies a station's access cost from OCM's `UsageType` object
  /// fields plus the free-form `usageCost` indicative text.
  ///
  /// Decision rule (single source of truth — #2618):
  ///   1. Structured flags win first: [isMembershipRequired] → membership,
  ///      else [isPayAtLocation] == true → paid.
  ///   2. When the flags are null/false, fall back to the lowercased
  ///      [usageTypeTitle] heuristic: 'membership' → membership,
  ///      'pay at location' → paid, 'notice required' → unknown,
  ///      'free' → free.
  ///   3. When `isPayAtLocation == false && isMembershipRequired == false`
  ///      and no paid title marker, the structured signal is free.
  ///   4. Cross-check the indicative [usageCost] via [EvPrice.parse]:
  ///      a real per-kWh / per-session amount > 0 OVERRIDES a 'free'
  ///      classification to paid (a real tariff always wins); a parsed
  ///      `free` promotes an otherwise-unknown signal to free.
  ///   5. Otherwise unknown (→ no badge).
  factory EvAccessCost.from({
    int? usageTypeId,
    String? usageTypeTitle,
    bool? isPayAtLocation,
    bool? isMembershipRequired,
    String? usageCost,
  }) {
    final title = usageTypeTitle?.toLowerCase().trim() ?? '';
    final price = EvPrice.parse(usageCost);
    final hasRealTariff = (price.kind == EvPriceKind.perKwh ||
            price.kind == EvPriceKind.perSession) &&
        (price.amount ?? 0) > 0;

    // 1. Structured flags win first.
    if (isMembershipRequired == true) return _override(EvAccessCostKind.membership, hasRealTariff);
    if (isPayAtLocation == true) return const EvAccessCost(EvAccessCostKind.paid);

    // Title heuristic markers (lowercased).
    final titleSaysMembership = title.contains('membership');
    final titleSaysPay = title.contains('pay at location');
    final titleSaysNoticeRequired = title.contains('notice required');
    final titleSaysFree = title.contains('free');

    // 2. Title heuristic when flags are null/false.
    if (titleSaysMembership) return _override(EvAccessCostKind.membership, hasRealTariff);
    if (titleSaysPay) return const EvAccessCost(EvAccessCostKind.paid);
    if (titleSaysNoticeRequired) {
      // "Notice required" carries no free/paid signal on its own — but a
      // parsed real tariff still resolves it to paid.
      return hasRealTariff
          ? const EvAccessCost(EvAccessCostKind.paid)
          : const EvAccessCost(EvAccessCostKind.unknown);
    }

    // 3. Structured "free": both flags explicitly false, or a 'free'
    //    title with no paid marker.
    final structuredFree =
        (isPayAtLocation == false && isMembershipRequired == false) ||
            titleSaysFree;
    if (structuredFree) {
      // 4a. A real tariff in usageCost overrides 'free' → paid.
      return hasRealTariff
          ? const EvAccessCost(EvAccessCostKind.paid)
          : const EvAccessCost(EvAccessCostKind.free);
    }

    // 4b. No structured signal: a real tariff means paid; a parsed
    //     'free' promotes unknown → free.
    if (hasRealTariff) return const EvAccessCost(EvAccessCostKind.paid);
    if (price.kind == EvPriceKind.free) {
      return const EvAccessCost(EvAccessCostKind.free);
    }

    // 5. Otherwise unknown — no badge.
    return const EvAccessCost(EvAccessCostKind.unknown);
  }

  /// A free/membership classification only survives if a real tariff in
  /// `usageCost` does not contradict it — a parsed per-kWh/per-session
  /// amount > 0 always demotes to [EvAccessCostKind.paid].
  static EvAccessCost _override(EvAccessCostKind kind, bool hasRealTariff) {
    if (kind == EvAccessCostKind.free && hasRealTariff) {
      return const EvAccessCost(EvAccessCostKind.paid);
    }
    return EvAccessCost(kind);
  }

  @override
  bool operator ==(Object other) =>
      other is EvAccessCost && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() => 'EvAccessCost($kind)';
}
