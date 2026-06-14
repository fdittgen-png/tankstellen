// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// A structured EV charging price parsed from the free-form
/// `ChargingStation.usageCost` string (#1785).
///
/// OpenChargeMap's `UsageCost` field has no schema — it carries
/// anything from `"0.49 EUR/kWh"` to `"Free"` to `"Ask operator"`.
/// [EvPrice.parse] turns the common shapes into a typed value so the
/// UI can render a consistent price and later features (favorites
/// merge, sorting) can reason about it; anything it cannot classify
/// degrades to [EvPriceKind.unknown] and the caller falls back to the
/// raw string.
library;

/// What kind of EV charging tariff [EvPrice] describes.
enum EvPriceKind {
  /// Energy-metered — a price per kilowatt-hour.
  perKwh,

  /// A flat fee per charging session.
  perSession,

  /// Charging is free of charge.
  free,

  /// The `usageCost` string could not be classified — callers should
  /// fall back to showing the raw string.
  unknown,
}

/// A parsed EV charging price. Immutable value type.
class EvPrice {
  /// The tariff kind.
  final EvPriceKind kind;

  /// The numeric amount for [EvPriceKind.perKwh] / [EvPriceKind.perSession];
  /// `null` for [EvPriceKind.free] and [EvPriceKind.unknown].
  final double? amount;

  /// ISO-ish currency token detected in the source string (`EUR`, `GBP`,
  /// `USD`, …); `null` when no currency could be identified.
  final String? currency;

  /// The original, untouched `usageCost` string (empty when the source
  /// was null/blank) — callers render this for the `unknown` kind.
  final String raw;

  const EvPrice({
    required this.kind,
    required this.raw,
    this.amount,
    this.currency,
  });

  /// True when the price carries a numeric amount worth rendering.
  bool get hasAmount => amount != null;

  /// A render-ready price label for the structured kinds (`perKwh` /
  /// `perSession`), or `null` for [EvPriceKind.free] /
  /// [EvPriceKind.unknown] — for which the caller shows [raw] instead.
  ///
  /// [perKwhUnit] / [perSessionUnit] are the localised unit suffixes
  /// (`AppLocalizations.refuelUnitPerKwh` / `refuelUnitPerSession`,
  /// e.g. `"/kWh"`). The amount is shown without a trailing `.0`.
  String? label({
    required String perKwhUnit,
    required String perSessionUnit,
  }) {
    final value = amount;
    if (value == null) return null;
    final n = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
    final money = currency == null ? n : '$n $currency';
    switch (kind) {
      case EvPriceKind.perKwh:
        return '$money$perKwhUnit';
      case EvPriceKind.perSession:
        return '$money$perSessionUnit';
      case EvPriceKind.free:
      case EvPriceKind.unknown:
        return null;
    }
  }

  static final _amount = RegExp(r'(\d+(?:[.,]\d+)?)');

  /// #3340 — the amount ATTACHED to a per-kWh unit (`0,40 €/kWh`,
  /// `0.49 EUR/kWh`, `€0,50/kWh`, `0.40 kw/h`). Anchoring on the unit means a
  /// multi-component tariff like `"0,1008 €/min …, 0,4008 €/kWh"` yields the
  /// €/kWh figure (0.4008), not the first (per-minute) number in the string.
  /// Matches against the already-lowercased text.
  static final _perKwhAmount = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(?:€|eur|£|gbp|\$|usd|chf|kr|zł|pln)?\s*(?:/|per)?\s*kw\s*/?\s*h',
  );
  static const _freeWords = <String>[
    'free', 'gratis', 'gratuit', 'kostenlos', 'gratuito', 'gratuita',
    'bezpłatn', 'ingyenes', 'nemokama', 'zdarma', 'besplatno',
  ];
  static const _currencyTokens = <String, String>{
    '€': 'EUR', 'eur': 'EUR',
    '£': 'GBP', 'gbp': 'GBP',
    r'$': 'USD', 'usd': 'USD',
    'chf': 'CHF', 'kr': 'SEK', 'zł': 'PLN', 'pln': 'PLN',
  };

  /// Parses a free-form `usageCost` string into a typed [EvPrice].
  ///
  /// Classification order matters: a string like `"Free parking,
  /// 0.79 EUR/kWh"` is a per-kWh tariff, not free — so a structured
  /// per-kWh / per-session price is detected *before* the free-words
  /// check. Decimal commas (`0,49`) are normalised to dots.
  factory EvPrice.parse(String? usageCost) {
    final raw = usageCost?.trim() ?? '';
    if (raw.isEmpty) return const EvPrice(kind: EvPriceKind.unknown, raw: '');

    final low = raw.toLowerCase();
    final currency = _detectCurrency(low);

    // #3340 — per-kWh first, using the amount ATTACHED to the kWh unit so a
    // multi-component string ("0,1008 €/min …, 0,4008 €/kWh") reports the
    // €/kWh figure, not the first (per-minute) number.
    final perKwhMatch = _perKwhAmount.firstMatch(low);
    if (perKwhMatch != null) {
      final perKwhAmount =
          double.tryParse(perKwhMatch.group(1)!.replaceAll(',', '.'));
      if (perKwhAmount != null && perKwhAmount > 0) {
        return EvPrice(
          kind: EvPriceKind.perKwh,
          amount: perKwhAmount,
          currency: currency,
          raw: raw,
        );
      }
    }

    final amountMatch = _amount.firstMatch(raw);
    final amount = amountMatch == null
        ? null
        : double.tryParse(amountMatch.group(1)!.replaceAll(',', '.'));

    final perSession = low.contains('session') ||
        low.contains('charge') ||
        low.contains('flat') ||
        low.contains('par recharge');

    if (amount != null && amount > 0 && perSession) {
      return EvPrice(
        kind: EvPriceKind.perSession,
        amount: amount,
        currency: currency,
        raw: raw,
      );
    }
    // No structured price — a "free" wording (or a bare 0) means free.
    final saysFree = _freeWords.any(low.contains);
    if (saysFree || (amount == 0 && !perSession)) {
      return EvPrice(kind: EvPriceKind.free, raw: raw);
    }
    return EvPrice(kind: EvPriceKind.unknown, raw: raw);
  }

  static String? _detectCurrency(String lower) {
    for (final entry in _currencyTokens.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is EvPrice &&
      other.kind == kind &&
      other.amount == amount &&
      other.currency == currency &&
      other.raw == raw;

  @override
  int get hashCode => Object.hash(kind, amount, currency, raw);

  @override
  String toString() =>
      'EvPrice($kind, amount: $amount, currency: $currency, raw: "$raw")';
}
