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

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('service_status_banner_stale.png'),
      );
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

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('service_status_banner_stale_multi_error.png'),
      );
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
