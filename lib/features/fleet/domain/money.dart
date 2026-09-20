// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// An amount and the ISO 4217 code it is denominated in (#4215).
///
/// Fleet expenses are summed, compared and exported across borders, and
/// a bare `double` cannot say which currency it is in. Two rules make
/// the silent cross-currency sum impossible:
///
///  * the currency is always an ISO 4217 **code**, never a symbol —
///    `€` is not a currency (three currencies print `kr`), and a symbol
///    cannot be compared, grouped or exported;
///  * [plus] refuses a different currency by returning null rather than
///    adding the numbers; the caller decides what to do about it.
///
/// Plain value type with explicit JSON — it rides inside the freezed
/// expense models through `json_serializable`'s `fromJson`/`toJson`
/// convention, so it needs no converter and no extra codegen.
class Money implements Comparable<Money> {
  const Money({required this.amount, required this.currency});

  /// Reads `{"amount": …, "currency": "EUR"}`.
  factory Money.fromJson(Map<String, dynamic> json) => Money(
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
      );

  /// The amount in the currency's MAJOR unit (euros, not cents).
  final double amount;

  /// ISO 4217 code (`EUR`, `GBP`, `CZK`) — never a symbol.
  final String currency;

  /// The smallest amount [currency] can express — what a printed total
  /// is rounded to, and therefore the floor of any arithmetic tolerance.
  /// An unknown code falls back to the two-decimal convention.
  double get minorUnit => kCurrencyMinorUnits[currency.toUpperCase()] ?? 0.01;

  /// [other] added, or null when the currencies differ.
  Money? plus(Money other) =>
      currency.toUpperCase() == other.currency.toUpperCase()
          ? Money(amount: amount + other.amount, currency: currency)
          : null;

  Map<String, dynamic> toJson() => {'amount': amount, 'currency': currency};

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amount == amount &&
      other.currency.toUpperCase() == currency.toUpperCase();

  @override
  int get hashCode => Object.hash(amount, currency.toUpperCase());

  /// Orders by amount; amounts in different currencies are NOT ordered
  /// (they compare equal) because there is no exchange rate here.
  @override
  int compareTo(Money other) =>
      currency.toUpperCase() == other.currency.toUpperCase()
          ? amount.compareTo(other.amount)
          : 0;

  @override
  String toString() => '$amount $currency';
}

/// The smallest expressible amount per ISO 4217 code, as a fuel
/// forecourt actually prints it.
///
/// `CZK` and `HUF` quote fuel to the whole koruna / forint, so a
/// cent-sized tolerance would flag every honest Czech receipt as an
/// arithmetic mismatch. `CHF` cash-rounds to five centimes. This is the
/// currency awareness the reconciler's tolerance is built on.
const Map<String, double> kCurrencyMinorUnits = {
  'EUR': 0.01,
  'GBP': 0.01,
  'USD': 0.01,
  'CHF': 0.05,
  'DKK': 0.01,
  'SEK': 0.01,
  'NOK': 0.01,
  'PLN': 0.01,
  'CZK': 1.0,
  'HUF': 1.0,
};
