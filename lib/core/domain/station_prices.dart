// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Prices for a single station, returned by the batch price refresh endpoint.
///
/// Carries a nullable price field for **every** priced fuel the [Station]
/// entity exposes — e5, e10, e98, diesel, dieselPremium, e85, lpg, cng (#2249).
/// Before this widening the model only held e5/e10/diesel, so a favorites /
/// alerts price refresh silently dropped LPG / CNG / E98 / diesel-premium /
/// E85 for fuel-rich countries (FR, IT, ES …): the fresh value existed on the
/// wire but had nowhere to land and the old price was kept instead.
///
/// A null value means the station does not sell that fuel or the price is
/// unavailable. The [status] field indicates whether the station is currently
/// open. (Electric / hydrogen are not modelled here because they are not
/// priced on the [Station] entity either — they would need their own units.)
class StationPrices {
  final double? e5;
  final double? e10;
  final double? e98;
  final double? diesel;
  final double? dieselPremium;
  final double? e85;
  final double? lpg;
  final double? cng;
  final String status;

  const StationPrices({
    this.e5,
    this.e10,
    this.e98,
    this.diesel,
    this.dieselPremium,
    this.e85,
    this.lpg,
    this.cng,
    required this.status,
  });

  bool get isOpen => status == 'open';

  Map<String, dynamic> toJson() => {
        'e5': e5,
        'e10': e10,
        'e98': e98,
        'diesel': diesel,
        'dieselPremium': dieselPremium,
        'e85': e85,
        'lpg': lpg,
        'cng': cng,
        'status': status,
      };

  factory StationPrices.fromJson(Map<String, dynamic> json) => StationPrices(
        e5: _price(json['e5']),
        e10: _price(json['e10']),
        e98: _price(json['e98']),
        diesel: _price(json['diesel']),
        dieselPremium: _price(json['dieselPremium']),
        e85: _price(json['e85']),
        lpg: _price(json['lpg']),
        cng: _price(json['cng']),
        status: json['status'] as String? ?? 'closed',
      );

  /// Coerce a raw JSON value to a `double?`: numbers become doubles, anything
  /// else (null, `false` closed-sentinel, stray strings) becomes null. Shared
  /// by every fuel field so the defensive contract is identical across them.
  static double? _price(dynamic value) =>
      value is num ? value.toDouble() : null;
}
