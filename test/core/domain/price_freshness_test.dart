// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/price_freshness.dart';

/// #4092 — price age becomes four bands with words, and the bands are
/// coarse ON PURPOSE: the underlying stamp is a lossy, per-country
/// pre-formatted string ("14:22" with no date in some countries), so a
/// precise "3 h 12 min" would claim a precision the data does not have.
///
/// The band that matters most is [PriceFreshness.unknown]: an unreadable
/// or absent stamp must never be reported as fresh — that is a price the
/// user would trust without cause — and must never be reported as stale
/// either, which is the false "old price" flag #3905 explicitly refused
/// to ship.
void main() {
  // Mid-month Wednesday, per the AppClock guidance: no band boundary and
  // no month/year rollover lands on it.
  final now = DateTime(2026, 9, 16, 14, 30);

  String ago(Duration d) => now.subtract(d).toIso8601String();

  group('bands', () {
    test('within six hours is fresh', () {
      expect(priceFreshness(ago(const Duration(minutes: 1)), now: now),
          PriceFreshness.fresh);
      expect(priceFreshness(ago(const Duration(hours: 5, minutes: 59)),
              now: now),
          PriceFreshness.fresh);
      expect(priceFreshness(ago(PriceFreshnessBands.fresh), now: now),
          PriceFreshness.fresh,
          reason: 'the boundary itself is the last fresh instant');
    });

    test('within a day is recent', () {
      expect(
          priceFreshness(ago(const Duration(hours: 6, minutes: 1)), now: now),
          PriceFreshness.recent);
      expect(priceFreshness(ago(PriceFreshnessBands.recent), now: now),
          PriceFreshness.recent);
    });

    test('within the stale threshold is aging', () {
      expect(priceFreshness(ago(const Duration(days: 1, hours: 1)), now: now),
          PriceFreshness.aging);
      expect(priceFreshness(ago(kStalePriceThreshold), now: now),
          PriceFreshness.aging,
          reason: 'exactly seven days is still the last non-stale instant, '
              'matching isStalePrice');
    });

    test('past the stale threshold is stale, and agrees with isStalePrice',
        () {
      final stamp = ago(const Duration(days: 8));
      expect(priceFreshness(stamp, now: now), PriceFreshness.stale);
      expect(isStalePrice(stamp, now: now), isTrue,
          reason: 'the two must never disagree about the same stamp');
    });
  });

  group('unknown is its own answer', () {
    test('a missing stamp is neither fresh nor stale', () {
      expect(priceFreshness(null, now: now), PriceFreshness.unknown);
    });

    test('a shape the reader does not know is unknown, not stale', () {
      for (final raw in ['', '   ', 'gestern', '99/99', 'N/A', '13:xx']) {
        expect(priceFreshness(raw, now: now), PriceFreshness.unknown,
            reason: '"$raw" must not produce a verdict');
        expect(isStalePrice(raw, now: now), isFalse);
      }
    });
  });

  group('clock skew', () {
    test('a stamp in the future is fresh, not aging', () {
      // The provider's clock running three minutes ahead of the phone is
      // routine; reporting the price as old because of it would be a lie
      // in the less useful direction.
      final future = now.add(const Duration(minutes: 3)).toIso8601String();
      expect(priceFreshness(future, now: now), PriceFreshness.fresh);
    });
  });

  group('the year-less European form', () {
    test('"16/07 11:00" read in September is stale, not next July', () {
      expect(priceFreshness('16/07 11:00', now: now), PriceFreshness.stale);
    });

    test('a stamp from this morning in that form is fresh', () {
      expect(priceFreshness('16/09 11:00', now: now), PriceFreshness.fresh);
    });
  });
}
