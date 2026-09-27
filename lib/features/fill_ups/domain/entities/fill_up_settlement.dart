// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

// A fill paid abroad, and the money the driver's bank actually charged
// for it (#4437, follow-up of #4428).
//
// ## Why this is not an FX lookup
//
// The app adopts no paid FX service, and #4364 declared
// `MoneyValuationRule.transactionDateRate` unavailable for exactly that
// reason. A CARD payment removes the blocker for the one record it
// covers: the issuer already performed the conversion and printed the
// result on the statement. That amount is not an approximation of a
// transaction-date rate — it is what the driver paid. So the rate here
// is always DERIVED from two amounts the driver entered, never looked
// up, and it belongs to that record alone.
//
// ## What the rate is used for
//
// * [FillUpSettlementX.bookedSpend] — the one `(amount, currency)` pair
//   every spend aggregate folds for a fill: the settled amount when the
//   record carries one, its native amount otherwise. A settled CHF fill
//   therefore joins a EUR history as the euros the statement shows, and
//   an unsettled one keeps withholding the combined total (#4364).
// * [settledExchangeRateOf] — the directed, sourced, dated
//   [ExchangeRate] the pair implies, for provenance lines and the
//   `exchangeRatesProvider` snapshot.
//
// Pure Dart: no Flutter, no formatting, no wall clock.
//
// A `part` of `fill_up.dart` so every consumer of the entity — including
// other features through the `fill_ups` barrel — books spend the same
// way without the barrel growing a new export.
part of 'fill_up.dart';

/// The rate [f]'s settlement implies, or null when [f] carries no usable
/// settlement.
///
/// Base: the record's currency; quote: `settledCurrency`; rate:
/// `settledAmount / totalCost` — sourced and dated from the record.
/// Null when the record's own currency is unknown (a rate needs a base
/// that can be named), when the two currencies are the same (nothing was
/// converted), or when either amount is not a positive finite number.
ExchangeRate? settledExchangeRateOf(FillUp f) {
  final base = _code(f.currency);
  final quote = _code(f.settledCurrency);
  final settled = f.settledAmount;
  if (base == null || quote == null || settled == null) return null;
  if (base == quote || f.isCorrection) return null;
  if (!settled.isFinite || settled <= 0) return null;
  if (!f.totalCost.isFinite || f.totalCost <= 0) return null;
  return ExchangeRate(
    baseCurrency: base,
    quoteCurrency: quote,
    rate: settled / f.totalCost,
    source: f.rateSource ?? kRateSourceCardSettlement,
    capturedAt: f.rateCapturedAt ?? f.date,
  );
}

/// Every settled rate in [fillUps], newest transaction first — so a
/// snapshot lookup for a currency pair finds the most recent evidence.
ExchangeRateSnapshot settledRatesSnapshot(Iterable<FillUp> fillUps) {
  final rates = [
    for (final f in fillUps) ?settledExchangeRateOf(f),
  ]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  return ExchangeRateSnapshot(rates: List.unmodifiable(rates));
}

String? _code(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed.toUpperCase();
}

/// Settlement accessors on a single [FillUp].
extension FillUpSettlementX on FillUp {
  /// True when this record carries a usable settlement (#4437).
  bool get isSettled => settledExchangeRateOf(this) != null;

  /// What the statement charged, as [Money] — exactly the amount entered,
  /// never recomputed. Null without a usable settlement.
  Money? get settledMoney =>
      isSettled ? Money(settledAmount!, _code(settledCurrency)!) : null;

  /// True when the implied rate was typed in by the driver rather than
  /// read off a card statement — shown differently wherever it is used.
  bool get isRateEnteredByHand =>
      isSettled && rateSource == kRateSourceEnteredByHand;

  /// The `(amount, currency)` a spend aggregate folds for this fill.
  ///
  /// The settled amount in its currency when the record carries a usable
  /// settlement — the money that actually left the driver's account —
  /// and the native `(totalCost, currency)` otherwise. Litres and
  /// distance never pass through here: consumption is identical whether
  /// or not a fill was settled (#4428).
  (double, String?) get bookedSpend {
    final settled = settledMoney;
    return settled == null
        ? (totalCost, currency)
        : (settled.amount, settled.currencyCode);
  }

  /// Price per litre in the currency of [bookedSpend] — the effective
  /// price the driver paid. 0 when no litres were recorded.
  double get bookedPricePerLiter {
    final (amount, _) = bookedSpend;
    return liters > 0 ? amount / liters : 0;
  }

  /// This record settled by a card statement: [amount] in [currency] was
  /// charged. The rate is dated to the TRANSACTION, not to today.
  FillUp settledByCard({required double amount, required String currency}) =>
      copyWith(
        settledAmount: amount,
        settledCurrency: currency.toUpperCase(),
        rateSource: kRateSourceCardSettlement,
        rateCapturedAt: date,
      );

  /// This record converted at a rate the driver typed in: one unit of
  /// the record's currency buys [rate] units of [currency]. Stored as the
  /// amount it implies, and labelled [kRateSourceEnteredByHand].
  FillUp settledByHandRate({required double rate, required String currency}) =>
      copyWith(
        settledAmount: totalCost * rate,
        settledCurrency: currency.toUpperCase(),
        rateSource: kRateSourceEnteredByHand,
        rateCapturedAt: date,
      );

  /// This record with its settlement removed — the native amount is all
  /// that remains, as before the driver entered anything.
  FillUp withoutSettlement() => copyWith(
        settledAmount: null,
        settledCurrency: null,
        rateSource: null,
        rateCapturedAt: null,
      );
}
