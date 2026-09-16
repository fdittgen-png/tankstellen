// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/background/notification_templates.dart';

/// #2306 — the background price-alert / velocity / radius notifications
/// used to ship hard-coded English (or a de/en `Platform.localeName`
/// branch) from the OS-spawned WorkManager isolate, which has no
/// BuildContext. They now render from [BackgroundNotificationTemplates],
/// resolved in the MAIN isolate for the active in-app language and handed
/// to the isolate via Hive settings.
///
/// These tests cover the three load-bearing behaviours:
///   * the templates resolve for any shipped locale (not just en/de);
///   * runtime interpolation fills the right placeholders;
///   * the JSON round-trip used by the Hive channel is lossless.
void main() {
  group('BackgroundNotificationTemplates — locale resolution', () {
    test('resolves French copy for fr (not English)', () {
      final t = BackgroundNotificationTemplates.resolveForLanguage('fr');
      expect(
        t.renderVelocityTitle(fuelLabel: 'DIESEL'),
        'DIESEL en baisse dans les stations proches',
      );
      // The target-price body keyword is localized ("objectif", not
      // "target").
      expect(
        t.renderPriceAlertBody(price: '1.559', target: '1.600'),
        contains('objectif'),
      );
    });

    test('resolves German copy for de', () {
      final t = BackgroundNotificationTemplates.resolveForLanguage('de');
      expect(
        t.renderVelocityTitle(fuelLabel: 'E10'),
        'E10 an Tankstellen in der Nähe gefallen',
      );
    });

    test('resolves a non-en/de locale (Polish) — the original bug', () {
      // Polish was one of the 13 locales that fell back to English under
      // the old `Platform.localeName` de/en branch.
      final t = BackgroundNotificationTemplates.resolveForLanguage('pl');
      expect(t.priceAlertBody, contains('cel:'));
    });

    test('falls back to English for an unknown language code', () {
      final t = BackgroundNotificationTemplates.resolveForLanguage('zz');
      expect(t.priceAlertBody, contains('target:'));
    });
  });

  group('BackgroundNotificationTemplates — interpolation', () {
    final t = BackgroundNotificationTemplates.resolveForLanguage('en');

    test('price-alert title fills station + fuel grade', () {
      expect(
        t.renderPriceAlertTitle(station: 'Aral Berlin', fuelType: 'Super E5'),
        'Aral Berlin - Super E5',
      );
    });

    test('price-alert body fills price, target and the € currency symbol',
        () {
      expect(
        t.renderPriceAlertBody(price: '1.559', target: '1.600'),
        '1.559 € (target: 1.600 €)',
      );
    });

    test('price-alert body honours a per-alert currency override (#2864)', () {
      // A GB alert renders the body in £, not a forced euro.
      expect(
        t.renderPriceAlertBody(price: '1.459', target: '1.500', currency: '£'),
        '1.459 £ (target: 1.500 £)',
      );
    });

    test('velocity body fills count + cents', () {
      expect(
        t.renderVelocityBody(count: 4, cents: 7),
        '4 stations dropped by up to 7¢ in the last hour',
      );
    });

    test('radius title fills label, count, threshold + currency', () {
      expect(
        t.renderRadiusTitle(label: 'Home', count: 3, threshold: '1.600'),
        'Home: 3 stations ≤ 1.600 €',
      );
    });

    test('radius title honours a per-alert currency override (#2864)', () {
      expect(
        t.renderRadiusTitle(
            label: 'Home', count: 3, threshold: '1.600', currency: 'kr'),
        'Home: 3 stations ≤ 1.600 kr',
      );
    });

    test('radius "+ N more" line fills count', () {
      expect(t.renderRadiusMore(count: 5), '+ 5 more');
    });
  });

  group('currencyForCountry (#2864) — derive symbol from country', () {
    final t = BackgroundNotificationTemplates.resolveForLanguage('en');

    test('resolves the registered currency per country', () {
      expect(t.currencyForCountry('DE'), '€');
      expect(t.currencyForCountry('GB'), '£');
      expect(t.currencyForCountry('DK'), 'kr');
      expect(t.currencyForCountry('KR'), '₩');
    });

    test('falls back to the template default (euro) for null / unknown', () {
      expect(t.currencyForCountry(null), '€');
      expect(t.currencyForCountry('ZZ'), '€');
    });
  });

  group('BackgroundNotificationTemplates — Hive JSON channel', () {
    test('encode → tryDecode round-trips every field', () {
      final original = BackgroundNotificationTemplates.resolveForLanguage('it');
      final decoded =
          BackgroundNotificationTemplates.tryDecode(original.encode());
      expect(decoded, isNotNull);
      expect(decoded!.priceAlertTitle, original.priceAlertTitle);
      expect(decoded.priceAlertBody, original.priceAlertBody);
      expect(decoded.velocityTitle, original.velocityTitle);
      expect(decoded.velocityBody, original.velocityBody);
      expect(decoded.radiusGroupedTitle, original.radiusGroupedTitle);
      expect(decoded.radiusGroupedMore, original.radiusGroupedMore);
      expect(decoded.currencySymbol, original.currencySymbol);
      expect(decoded.fuelLabels, original.fuelLabels);
    });

    test('the fuel labels are localized, not FuelType.displayName (#4301)',
        () {
      // Italian, matching the round-trip case above. `it` is a real probe:
      // lpg is `GPL` and e85 `Bioetanolo E85`, where FuelType.displayName
      // says `GPL / LPG` and `E85 / Bioéthanol`. For diesel/e10 the two
      // spellings coincide, so those grades could never detect this.
      final templates = BackgroundNotificationTemplates.resolveForLanguage('it');

      expect(templates.fuelLabelFor('lpg'), 'GPL');
      expect(templates.fuelLabelFor('e85'), 'Bioetanolo E85');
      // The hybrids must be absent. Without this the assertions above
      // could pass while displayName still leaked through some other
      // path — and a negative against a string no code can emit is the
      // vacuous-negative trap #4295 had to undo five times.
      expect(templates.fuelLabels.values, isNot(contains('GPL / LPG')));
      expect(templates.fuelLabels.values,
          isNot(contains('E85 / Bioéthanol')));
    });

    test('the search wildcard is never an alert subject (#4301)', () {
      final templates = BackgroundNotificationTemplates.resolveForLanguage('en');

      expect(templates.fuelLabels.containsKey('all'), isFalse,
          reason: 'FuelType.all is a search-time wildcard; an alert is '
              'always about one grade');
    });

    test('an unknown apiValue falls back to itself, never null (#4301)', () {
      final templates = BackgroundNotificationTemplates.resolveForLanguage('en');

      // A blob predating a grade, or a grade this build does not know.
      // `e10` reads as a label; `null` interpolated into a sentence reads
      // as a bug.
      expect(templates.fuelLabelFor('some_future_grade'), 'some_future_grade');
    });

    test('a blob without fuelLabels decodes to null, so the caller '
        're-resolves (#4301 / #4183 path)', () {
      final encoded =
          BackgroundNotificationTemplates.resolveForLanguage('de').encode();
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      // Exactly what a blob written before #4301 looks like.
      map.remove('fuelLabels');

      expect(BackgroundNotificationTemplates.tryDecode(jsonEncode(map)), isNull,
          reason: 'null sends the caller down the existing '
              'fall-back-to-live-resolution path, and the main isolate '
              'rewrites the blob on the next launch');
    });

    test('tryDecode returns null for null / empty / malformed blobs', () {
      expect(BackgroundNotificationTemplates.tryDecode(null), isNull);
      expect(BackgroundNotificationTemplates.tryDecode(''), isNull);
      expect(BackgroundNotificationTemplates.tryDecode('{not json'), isNull);
      // Valid JSON but missing required fields.
      expect(BackgroundNotificationTemplates.tryDecode('{"foo":"bar"}'), isNull);
    });
  });
}
