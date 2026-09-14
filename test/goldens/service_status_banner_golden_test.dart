// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';

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

  group('ServiceChainErrorWidget golden tests', () {
    testWidgets('generic error with retry button', (tester) async {
      await pumpApp(
        tester,
        RepaintBoundary(
          child: ServiceChainErrorWidget(
            error: Exception('No stations found in this area'),
            onRetry: () {},
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('service_chain_error_generic.png'),
      );
    });

    testWidgets('timeout error', (tester) async {
      await pumpApp(
        tester,
        RepaintBoundary(
          child: ServiceChainErrorWidget(
            error: Exception('Connection timeout after 10s'),
            onRetry: () {},
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('service_chain_error_timeout.png'),
      );
    });
  });
}
