// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Currency-SEGREGATED accumulation of money (#4364, Epic #4358 work
/// package I) — the one place a running monetary total is kept.
///
/// [Money] (#4361) already refuses to add across currencies. What was
/// missing is the shape an *aggregator* needs: a walker over a year of
/// fill-ups cannot stop at the first foreign receipt, it has to keep
/// going and keep the buckets apart. Every historical aggregation in the
/// app used a bare `double` running sum instead, which is how €30 and
/// DKK 225 became "255" and how the active country's symbol got painted
/// on top of it.
///
/// ## Unknown is a bucket, not a currency
///
/// `FillUp.currency` documents null as **unknown** and warns against
/// inferring it from today's country. [kUnknownCurrency] is therefore its
/// own bucket key — never an ISO code, never convertible, never merged
/// into a named currency. An all-unknown history is still one
/// denomination (a driver who never left home and logged before the field
/// existed), so it keeps a single total; the moment a *named* currency
/// joins it, the total is withheld.
///
/// ## Conversion is opt-in and carries its policy
///
/// [combine] takes an [ExchangeRateSnapshot] and an explicit `asOf`
/// instant taken through the `AppClock` seam — never the wall clock, and
/// never the active profile's currency as an unstated assumption. It
/// returns every part's [MoneyConversion] so a caller can show "DKK 225
/// (≈ €30, ECB 12 Sep)" rather than a number whose provenance died in
/// the sum.
library;

import 'package:meta/meta.dart';

import 'money.dart';

/// The bucket amounts with no recorded currency fall into (#4136, #4364).
///
/// Its own key rather than a guess at the active currency: assuming
/// today's is precisely the silent cross-currency sum this exists to
/// prevent. Not a valid ISO 4217 code, so it can never be mistaken for
/// one.
const String kUnknownCurrency = '?';

/// Money accumulated per currency, with the unknown-currency part kept
/// apart and countable.
@immutable
final class MoneyTally {
  const MoneyTally._(this.byCurrency, this.entryCount, this.unknownEntryCount);

  /// Nothing accumulated yet — the additive identity.
  static const MoneyTally empty = MoneyTally._({}, 0, 0);

  /// One denomination's total, keyed by ISO 4217 code or
  /// [kUnknownCurrency]. Never contains a zero-entry bucket for a
  /// currency nothing was booked in.
  final Map<String, double> byCurrency;

  /// How many amounts were folded in (including unknown-currency ones).
  final int entryCount;

  /// How many of [entryCount] carried no currency at all.
  final int unknownEntryCount;

  /// This tally plus [amount] booked in [currencyCode] — null goes to the
  /// [kUnknownCurrency] bucket, and an upper-cased ISO code everywhere
  /// else so `eur` and `EUR` are one denomination, not two.
  MoneyTally plus(double amount, String? currencyCode) {
    if (!amount.isFinite) return this;
    final key = (currencyCode == null || currencyCode.isEmpty)
        ? kUnknownCurrency
        : currencyCode.toUpperCase();
    return MoneyTally._(
      {...byCurrency, key: (byCurrency[key] ?? 0) + amount},
      entryCount + 1,
      unknownEntryCount + (key == kUnknownCurrency ? 1 : 0),
    );
  }

  /// Fold `(amount, currency)` pairs into one tally.
  static MoneyTally of(Iterable<(double, String?)> amounts) {
    var tally = empty;
    for (final (amount, currency) in amounts) {
      tally = tally.plus(amount, currency);
    }
    return tally;
  }

  bool get isEmpty => byCurrency.isEmpty;

  /// Every denomination present, [kUnknownCurrency] included.
  Iterable<String> get currencies => byCurrency.keys;

  /// True when some amount carried no currency.
  bool get hasUnknownCurrency => byCurrency.containsKey(kUnknownCurrency);

  /// True when at most one denomination is present — the only case in
  /// which a single number is true of anything.
  bool get isSingleDenomination => byCurrency.length <= 1;

  /// The one denomination's code, or null when the tally is empty or
  /// mixed. [kUnknownCurrency] when the sole denomination is unknown.
  String? get soleCurrency =>
      byCurrency.length == 1 ? byCurrency.keys.first : null;

  /// The single total when there is exactly one denomination (named OR
  /// unknown), 0 for an empty tally, and **null when denominations are
  /// mixed** — absent, never zero, and never a cross-currency sum.
  double? get soleAmount {
    if (byCurrency.isEmpty) return 0;
    return byCurrency.length == 1 ? byCurrency.values.first : null;
  }

  /// The sole total as [Money], or null when the tally is mixed, empty or
  /// denominated in [kUnknownCurrency] — an unknown currency cannot be
  /// named, and [Money] requires a name.
  Money? get soleMoney {
    final code = soleCurrency;
    if (code == null || code == kUnknownCurrency) return null;
    return Money(byCurrency[code]!, code);
  }

  /// The total booked in [currencyCode] (0 when none was).
  double amountIn(String currencyCode) =>
      byCurrency[currencyCode.toUpperCase()] ?? 0;

  /// This tally expressed in [target] under an explicit, dated rate
  /// snapshot.
  ///
  /// [asOf] is the report instant the rates are judged fresh against —
  /// injected, never read from the wall clock here. Any unknown-currency
  /// part makes the combined total unavailable: an amount whose currency
  /// is not recorded has no rate, and picking one would invent history.
  MoneyTallyCombination combine({
    required String target,
    required ExchangeRateSnapshot rates,
    required DateTime asOf,
  }) {
    final code = target.toUpperCase();
    final parts = <MoneyConversion>[];
    var total = 0.0;
    MoneyConversionRefusal? refusal;
    for (final entry in byCurrency.entries) {
      if (entry.key == kUnknownCurrency) continue;
      final conversion =
          rates.convert(Money(entry.value, entry.key), code, asOf);
      parts.add(conversion);
      final converted = conversion.converted;
      if (converted == null) {
        refusal ??= conversion.refusal;
      } else {
        total += converted.amount;
      }
    }
    final blocked = refusal != null || hasUnknownCurrency;
    return MoneyTallyCombination(
      total: blocked ? null : Money(total, code),
      parts: List.unmodifiable(parts),
      refusal: refusal,
      unknownCurrencyEntryCount: unknownEntryCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! MoneyTally) return false;
    if (other.entryCount != entryCount ||
        other.unknownEntryCount != unknownEntryCount ||
        other.byCurrency.length != byCurrency.length) {
      return false;
    }
    for (final e in byCurrency.entries) {
      if (other.byCurrency[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        entryCount,
        unknownEntryCount,
        Object.hashAllUnordered(
          [for (final e in byCurrency.entries) Object.hash(e.key, e.value)],
        ),
      );

  @override
  String toString() => 'MoneyTally($byCurrency, n=$entryCount)';
}

/// How a historical amount may be re-expressed in another currency
/// (#4364) — the documented policy a conversion must carry.
///
/// A conversion is always OPTIONAL and always LABELLED. There is no
/// implicit rate, and neither the active profile's currency nor today's
/// rate may be presented as a historical fact: a receipt is what was
/// paid, and anything else is a valuation made under a rule someone can
/// name. [rates] carries the source, direction and capture date of every
/// rate used, and [asOf] is the report instant they are judged fresh
/// against — injected, so a report replays identically.
@immutable
final class MoneyValuationPolicy {
  const MoneyValuationPolicy({
    required this.targetCurrency,
    required this.rates,
    required this.asOf,
    this.rule = MoneyValuationRule.reportDateRate,
  });

  /// ISO code every part is re-expressed in.
  final String targetCurrency;

  /// The dated, sourced rates. Never fetched here.
  final ExchangeRateSnapshot rates;

  /// The instant rate freshness is judged at.
  final DateTime asOf;

  final MoneyValuationRule rule;

  /// [tally] under this policy.
  MoneyTallyCombination apply(MoneyTally tally) =>
      tally.combine(target: targetCurrency, rates: rates, asOf: asOf);
}

/// Which dated rate a [MoneyValuationPolicy] uses.
enum MoneyValuationRule {
  /// One rate, captured at (or before) the report instant, applied to
  /// every historical amount. Honest and reproducible — and explicitly
  /// NOT a claim about what each purchase cost on its own day.
  reportDateRate,

  /// Each amount at the rate of its own transaction date. Not yet
  /// available: the app adopts no paid FX history service, so a policy
  /// naming this must be refused rather than approximated.
  transactionDateRate,
}

/// The result of asking a [MoneyTally] for one number in one currency.
///
/// [total] is non-null only when EVERY named part converted under a
/// usable, fresh rate and no unknown-currency amount was present. The
/// [parts] carry each native amount with the rate that moved it, so the
/// explanation can quote source and date instead of asserting a figure.
@immutable
final class MoneyTallyCombination {
  const MoneyTallyCombination({
    required this.total,
    required this.parts,
    required this.refusal,
    required this.unknownCurrencyEntryCount,
  });

  /// The combined amount, or null when the combination was refused.
  final Money? total;

  /// One conversion per named denomination, native amount included.
  final List<MoneyConversion> parts;

  /// Why a named part could not be converted, when one could not.
  final MoneyConversionRefusal? refusal;

  /// How many folded amounts carried no currency at all. Non-zero always
  /// withholds [total].
  final int unknownCurrencyEntryCount;

  bool get isAvailable => total != null;
}
