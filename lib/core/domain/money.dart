// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// An amount of money that knows which currency it is (#4361, Epic
/// #4358, work package D).
///
/// Every total in the refuel economics used to be a bare `double`. On a
/// domestic list that is harmless; on a DE→DK route it is a defect —
/// 13 (DKK) sorts below 1.80 (EUR) and the app recommends the more
/// expensive station with total confidence. A country-specific display
/// symbol does not make the numbers comparable; only a stated rate does.
///
/// ## The three rules this type exists to enforce
///
/// 1. **Arithmetic never crosses a currency.** [Money.+] and [Money.-]
///    return null for a mismatch instead of producing a number whose
///    unit nobody can name.
/// 2. **A comparison is converted or it is refused.** There is no
///    implicit 1:1. A missing or stale rate produces
///    [MoneyConversionRefusal], and the caller shows the native quotes
///    side by side and withholds the combined winner.
/// 3. **A rate carries its direction, source and timestamp.** `7.50 DKK
///    = €1` is stored once as base EUR / quote DKK / rate 7.5, and
///    [ExchangeRate.convert] reads it in both directions from that one
///    fact, so an inverted rate cannot be introduced by a caller.
///
/// Amounts are always in the currency's PRIMARY unit (GBP, not pence;
/// EUR, not cents). The pence/cents convention is a display scale that
/// `UnitFormatter.formatPricePerUnit` applies — see
/// [FuelPriceQuote.fromSubUnit] in `fuel_offer.dart` for the one place a
/// sub-unit figure is allowed to enter the domain.
///
/// Pure Dart: no Flutter, no formatting, no locale. A formatted string is
/// never compared.
library;

import 'package:meta/meta.dart';

/// How long a rate stays usable for a money RANKING.
///
/// Rates move by fractions of a percent a day, and the app adopts no paid
/// FX service, so a snapshot may legitimately be hours old. Past this it
/// is still shown as context and no longer allowed to decide a winner.
const Duration kExchangeRateMaxAge = Duration(hours: 24);

/// An amount in one named currency.
@immutable
class Money implements Comparable<Money> {
  const Money(this.amount, this.currencyCode);

  /// Zero in [currencyCode] — a currency-carrying additive identity, so a
  /// running total never has to start life as a bare `0`.
  const Money.zero(this.currencyCode) : amount = 0;

  final double amount;

  /// ISO 4217, upper case (`EUR`, `DKK`, `GBP`). Never a symbol: `$`
  /// names four different currencies in this app's country table.
  final String currencyCode;

  bool isSameCurrencyAs(Money other) => other.currencyCode == currencyCode;

  /// Sum, or null across currencies. Null is the point: a caller that
  /// wanted one number has to say which currency it wanted it in.
  Money? operator +(Money other) =>
      isSameCurrencyAs(other) ? Money(amount + other.amount, currencyCode) : null;

  Money? operator -(Money other) =>
      isSameCurrencyAs(other) ? Money(amount - other.amount, currencyCode) : null;

  Money operator *(double factor) => Money(amount * factor, currencyCode);

  bool get isFinite => amount.isFinite;

  /// Orders two amounts of the SAME currency. Cross-currency ordering is
  /// [compareInCurrency] on a snapshot, never this.
  @override
  int compareTo(Money other) => isSameCurrencyAs(other)
      ? amount.compareTo(other.amount)
      : currencyCode.compareTo(other.currencyCode);

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amount == amount &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(amount, currencyCode);

  @override
  String toString() => 'Money($amount $currencyCode)';
}

/// Sum [amounts], or null when they are not all one currency (or the
/// list is empty and no [fallbackCurrency] was named).
Money? sumMoney(Iterable<Money> amounts, {String? fallbackCurrency}) {
  Money? total;
  for (final m in amounts) {
    total = total == null ? m : total + m;
    if (total == null) return null;
  }
  return total ?? (fallbackCurrency == null ? null : Money.zero(fallbackCurrency));
}

/// One directed rate: `1 [baseCurrency] = [rate] [quoteCurrency]`.
///
/// The direction is part of the value, not a convention the caller has to
/// remember. `ExchangeRate(base: 'EUR', quote: 'DKK', rate: 7.5)` reads
/// "€1 buys 7.50 DKK" and converts both ways.
@immutable
class ExchangeRate {
  const ExchangeRate({
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
    required this.source,
    required this.capturedAt,
  });

  final String baseCurrency;
  final String quoteCurrency;

  /// Units of [quoteCurrency] per one [baseCurrency]. Must be finite and
  /// strictly positive to be usable — [isUsable].
  final double rate;

  /// Where the figure came from, named so an explanation can quote it.
  /// The app adopts no paid FX API, so this is a manual or bundled
  /// snapshot and the UI says so.
  final String source;

  final DateTime capturedAt;

  bool get isUsable => rate.isFinite && rate > 0;

  /// The multiplier taking [from] to [to], or null when this rate does
  /// not relate the two.
  double? factor(String from, String to) {
    if (!isUsable) return null;
    if (from == baseCurrency && to == quoteCurrency) return rate;
    if (from == quoteCurrency && to == baseCurrency) return 1 / rate;
    return null;
  }
}

/// Why a conversion did not happen. Each one leaves the native amount
/// intact and the combined winner withheld — never a silent 1:1.
enum MoneyConversionRefusal {
  /// No rate in the snapshot relates the two currencies.
  noRate,

  /// A rate exists but is older than [kExchangeRateMaxAge].
  rateStale,

  /// The rate itself is not a usable positive finite number.
  invalidRate,
}

/// The outcome of asking for an amount in another currency.
///
/// Always carries [native]. [converted] is non-null only when a usable,
/// fresh rate did the work; [refusal] says why not otherwise. Both are
/// meant to be shown: "DKK 13.00 (≈ €1.73, ECB 12 Sep)" is the honest
/// rendering, and "DKK 13.00 (rate unavailable)" is the honest failure.
@immutable
class MoneyConversion {
  const MoneyConversion.same(this.native)
      : converted = native,
        rate = null,
        refusal = null;

  const MoneyConversion.converted(
    this.native, {
    required Money this.converted,
    required ExchangeRate this.rate,
  }) : refusal = null;

  const MoneyConversion.refused(this.native, this.refusal, {this.rate})
      : converted = null;

  final Money native;
  final Money? converted;
  final ExchangeRate? rate;
  final MoneyConversionRefusal? refusal;

  /// Whether this amount may take part in a combined money ranking.
  bool get isUsable => converted != null;

  /// True when no conversion was needed at all — the same-currency case,
  /// which must never require an FX lookup.
  bool get wasAlreadyInTargetCurrency => rate == null && refusal == null;
}

/// A dated set of rates from one named source.
///
/// Snapshot, not service: the domain never fetches. Whoever has rates
/// (a bundled table, a user entry, a future provider) builds one of
/// these, and the arithmetic layer can be replayed exactly.
@immutable
class ExchangeRateSnapshot {
  const ExchangeRateSnapshot({
    required this.rates,
    this.maxAge = kExchangeRateMaxAge,
  });

  /// No rates at all — the honest default before anything supplies them.
  const ExchangeRateSnapshot.empty()
      : rates = const [],
        maxAge = kExchangeRateMaxAge;

  final List<ExchangeRate> rates;

  /// How old a rate may be and still decide a winner.
  final Duration maxAge;

  ExchangeRate? _rateFor(String from, String to) {
    for (final r in rates) {
      if (r.factor(from, to) != null) return r;
    }
    return null;
  }

  /// [amount] in [target] at [now].
  ///
  /// Same currency short-circuits with no rate lookup at all — a
  /// domestic comparison must never depend on FX being present.
  MoneyConversion convert(Money amount, String target, DateTime now) {
    if (amount.currencyCode == target) return MoneyConversion.same(amount);
    final rate = _rateFor(amount.currencyCode, target);
    if (rate == null) {
      return MoneyConversion.refused(amount, MoneyConversionRefusal.noRate);
    }
    final factor = rate.factor(amount.currencyCode, target);
    if (factor == null || !factor.isFinite || factor <= 0) {
      return MoneyConversion.refused(
          amount, MoneyConversionRefusal.invalidRate, rate: rate);
    }
    if (now.difference(rate.capturedAt).abs() > maxAge) {
      return MoneyConversion.refused(
          amount, MoneyConversionRefusal.rateStale, rate: rate);
    }
    return MoneyConversion.converted(
      amount,
      converted: Money(amount.amount * factor, target),
      rate: rate,
    );
  }

  /// Order [a] against [b] in [target], or null when either side cannot
  /// be converted. A null answer is a withheld winner, not a tie.
  int? compareInCurrency(Money a, Money b, String target, DateTime now) {
    final ca = convert(a, target, now).converted;
    final cb = convert(b, target, now).converted;
    if (ca == null || cb == null) return null;
    return ca.amount.compareTo(cb.amount);
  }
}
