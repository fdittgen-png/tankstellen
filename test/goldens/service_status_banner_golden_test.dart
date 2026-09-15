// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';

import 'package:tankstellen/l10n/app_localizations.dart';

import '../helpers/pump_app.dart';

void main() {
  group('ServiceStatusBanner golden tests', () {
    testWidgets('fresh data — hidden', (tester) async {
      final result = ServiceResult<List<String>>(
        data: ['ok'],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
        isStale: false,
        errors: [],
      );

      await pumpApp(
        tester,
        RepaintBoundary(
          child: ServiceStatusBanner(result: result),
        ),
      );

      // Fresh result renders SizedBox.shrink — verify it's basically empty
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('service_status_banner_fresh.png'),
      );
    });

    testWidgets('stale data — offline banner', (tester) async {
      final result = ServiceResult<List<String>>(
        data: ['cached'],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isStale: true,
        errors: [],
      );

      await pumpApp(
        tester,
        RepaintBoundary(
          child: ServiceStatusBanner(result: result),
        ),
      );

      // #4134 — structural, not a PNG. This case asserts a COLOUR
      // SEMANTIC (offline must not read as an error), which a pixel diff
      // states only by accident and a Linux/macOS baseline mismatch
      // breaks for unrelated reasons — see `golden_cross_platform_baseline`.
      final ctx = tester.element(find.byType(ServiceStatusBanner));
      final scheme = Theme.of(ctx).colorScheme;
      final box = tester.widget<Container>(find.descendant(
        of: find.byType(ServiceStatusBanner),
        matching: find.byType(Container),
      ));

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(box.color, isNot(scheme.errorContainer),
          reason: 'serving cached prices with no network is the app doing '
              'its job under worse conditions, not something breaking');
      expect(box.color, scheme.secondaryContainer);
    });

    testWidgets('fallback — info banner', (tester) async {
      final result = ServiceResult<List<String>>(
        data: ['fallback data'],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
        isStale: false,
        errors: [
          ServiceError(
            source: ServiceSource.tankerkoenigApi,
            message: 'Timeout after 10s',
            statusCode: 408,
            occurredAt: DateTime.now(),
          ),
        ],
      );

      await pumpApp(
        tester,
        RepaintBoundary(
          child: ServiceStatusBanner(result: result),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('service_status_banner_fallback.png'),
      );
    });

    testWidgets('stale with multiple fallback errors', (tester) async {
      final result = ServiceResult<List<String>>(
        data: ['old cached data'],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isStale: true,
        errors: [
          ServiceError(
            source: ServiceSource.tankerkoenigApi,
            message: 'Connection refused',
            occurredAt: DateTime.now(),
          ),
          ServiceError(
            source: ServiceSource.prixCarburantsApi,
            message: 'HTTP 503',
            statusCode: 503,
            occurredAt: DateTime.now(),
          ),
        ],
      );

      await pumpApp(
        tester,
        RepaintBoundary(
          child: ServiceStatusBanner(result: result),
        ),
      );

      // #4134 — stale wins over the fallbacks: the user is looking at old
      // data, which is the more important thing to say. Structural for
      // the same reason as the case above.
      final ctx = tester.element(find.byType(ServiceStatusBanner));
      final scheme = Theme.of(ctx).colorScheme;
      final box = tester.widget<Container>(find.descendant(
        of: find.byType(ServiceStatusBanner),
        matching: find.byType(Container),
      ));

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsNothing,
          reason: 'one banner, and offline is the one that matters');
      expect(box.color, scheme.secondaryContainer);
      expect(box.color, isNot(scheme.errorContainer));
    });
  });

  /// #4141 — structural, not PNGs, for the same reason the two cases
  /// above became structural at #4134.
  ///
  /// These two were pixel goldens of the failure screen, and #4141
  /// changed that screen: it gained the "can I continue" line, which is
  /// the whole point of the recovery contract. A PNG baseline states
  /// "these pixels" and nothing about WHY, so it fails on a deliberate
  /// improvement with a diff a reader has to interpret — and a
  /// locally-regenerated baseline then reddens Linux CI on the 1.5%
  /// tolerance (`golden_cross_platform_baseline`).
  ///
  /// What a golden was actually protecting here is the ARRANGEMENT: the
  /// four parts in the order a person asks them, and the diagnostic not
  /// being one of them. That is assertable exactly, on any platform.
  group('ServiceChainErrorWidget renders the recovery contract (#4141)', () {
    /// The vertical position of the single widget matching [finder].
    double topOf(WidgetTester tester, Finder finder) =>
        tester.getTopLeft(finder).dy;

    testWidgets('the four parts appear in the order they are asked',
        (tester) async {
      await pumpApp(
        tester,
        ServiceChainErrorWidget(
          error: Exception('No stations found in this area'),
          onRetry: () {},
        ),
      );

      final l10n = AppLocalizations.of(
          tester.element(find.byType(ServiceChainErrorWidget)));

      // 1. what happened, 2. why it matters, 3. can I continue,
      // 4. what do I do.
      final whatHappened = topOf(tester, find.text(l10n.noResults));
      final whyItMatters = topOf(tester, find.text(l10n.errorHintNoStations));
      final canIContinue =
          topOf(tester, find.text(l10n.recoveryStillWorksNoStations));
      final whatDoIDo = topOf(tester, find.widgetWithText(FilledButton, l10n.retry));

      expect(whatHappened, lessThan(whyItMatters));
      expect(whyItMatters, lessThan(canIContinue));
      expect(canIContinue, lessThan(whatDoIDo),
          reason: 'the action comes last: a button above the sentence '
              'explaining whether anything is broken invites a tap '
              'before the reader knows what it costs');
    });

    testWidgets('an empty search is not dressed as a failure', (tester) async {
      await pumpApp(
        tester,
        ServiceChainErrorWidget(
          error: Exception('No stations found in this area'),
          onRetry: () {},
        ),
      );

      final ctx = tester.element(find.byType(ServiceChainErrorWidget));
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.color, isNot(Theme.of(ctx).colorScheme.error),
          reason: 'RecoveryImpact.unaffected — nothing failed, the search '
              'simply came back empty');
    });

    testWidgets('a real failure IS dressed as one, and hides its cause',
        (tester) async {
      await pumpApp(
        tester,
        ServiceChainErrorWidget(
          error: Exception('Connection timeout after 10s'),
          onRetry: () {},
        ),
      );

      final ctx = tester.element(find.byType(ServiceChainErrorWidget));
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.color, Theme.of(ctx).colorScheme.error);

      final l10n = AppLocalizations.of(ctx);
      expect(find.text(l10n.recoveryStillWorksConnection), findsOneWidget,
          reason: 'the cache is what keeps the app useful offline, and the '
              'user cannot see it is being used unless told');
      expect(find.textContaining('Exception'), findsNothing,
          reason: 'the raw error lives behind the details tile, never on '
              'the first screen');
    });
  });
}
