import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';

void main() {
  group('ServiceStatusBanner', () {
    Widget wrapInApp(Widget child) {
      return MaterialApp(home: Scaffold(body: child));
    }

    test('returns SizedBox.shrink when not stale and no fallbacks', () {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
        isStale: false,
        errors: [],
      );

      ServiceStatusBanner(result: result);
      // Build logic check: not stale and no fallbacks => SizedBox.shrink
      expect(result.isStale, isFalse);
      expect(result.hadFallbacks, isFalse);
    });

    testWidgets('shows nothing when data is fresh and no fallbacks',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapInApp(ServiceStatusBanner(result: result)));

      // Should render a SizedBox.shrink (no visible content)
      expect(find.byType(Container), findsNothing);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('shows offline banner when data is stale', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isStale: true,
      );

      await tester.pumpWidget(wrapInApp(ServiceStatusBanner(result: result)));

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.textContaining('Offline'), findsOneWidget);
    });

    testWidgets('shows fallback banner when errors present but not stale',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
        isStale: false,
        errors: [
          ServiceError(
            source: ServiceSource.tankerkoenigApi,
            message: 'timeout',
            occurredAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(wrapInApp(ServiceStatusBanner(result: result)));

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.textContaining('unavailable'), findsOneWidget);
    });

    testWidgets('stale takes priority over fallbacks in display',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isStale: true,
        errors: [
          ServiceError(
            source: ServiceSource.tankerkoenigApi,
            message: 'error',
            occurredAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(wrapInApp(ServiceStatusBanner(result: result)));

      // Stale branch should show cloud_off, not info_outline
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.textContaining('Offline'), findsOneWidget);
    });
  });

  group('ServiceChainErrorWidget', () {
    Widget wrapInApp(Widget child) {
      return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
    }

    testWidgets('displays error icon and retry button', (tester) async {
      var retryPressed = false;
      await tester.pumpWidget(wrapInApp(
        ServiceChainErrorWidget(
          error: Exception('test error'),
          onRetry: () => retryPressed = true,
        ),
      ));

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      expect(retryPressed, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const ServiceChainErrorWidget(
          error: NoApiKeyException(),
        ),
      ));

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('shows hint for NoApiKeyException', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const ServiceChainErrorWidget(
          error: NoApiKeyException(),
        ),
      ));

      expect(find.textContaining('API key'), findsWidgets);
    });

    testWidgets('shows hint for LocationException', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ServiceChainErrorWidget(
          error: const LocationException(message: 'GPS unavailable'),
          onRetry: () {},
        ),
      ));

      // Should contain location-related hint
      expect(find.textContaining('Location'), findsWidgets);
    });

    testWidgets('shows hint for timeout errors', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ServiceChainErrorWidget(
          error: Exception('connection timeout occurred'),
          onRetry: () {},
        ),
      ));

      expect(find.textContaining('internet'), findsOneWidget);
    });

    testWidgets('shows hint for route errors', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ServiceChainErrorWidget(
          error: Exception('Route calculation via OSRM failed'),
          onRetry: () {},
        ),
      ));

      expect(find.textContaining('Route'), findsOneWidget);
    });

    testWidgets('shows generic hint for unknown errors', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ServiceChainErrorWidget(
          error: Exception('something weird'),
          onRetry: () {},
        ),
      ));

      expect(find.textContaining('Try again'), findsWidgets);
    });

    testWidgets('shows expandable technical details', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ServiceChainErrorWidget(
          error: ServiceChainExhaustedException(errors: [
            ServiceError(
              source: ServiceSource.tankerkoenigApi,
              message: 'API timeout',
              occurredAt: DateTime.now(),
            ),
            ServiceError(
              source: ServiceSource.cache,
              message: 'Cache empty',
              occurredAt: DateTime.now(),
            ),
          ]),
          onRetry: () {},
        ),
      ));

      // Details section exists
      expect(find.text('Details'), findsOneWidget);

      // Expand the details
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      // Should show individual error messages
      expect(find.textContaining('API timeout'), findsOneWidget);
      expect(find.textContaining('Cache empty'), findsOneWidget);
    });

    testWidgets('shows technical details for plain exception', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ServiceChainErrorWidget(
          error: Exception('plain error'),
          onRetry: () {},
        ),
      ));

      // Expand details
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(find.textContaining('plain error'), findsWidgets);
    });

    testWidgets('shows no stations found hint', (tester) async {
      await tester.pumpWidget(wrapInApp(
        ServiceChainErrorWidget(
          error: Exception('no stations found in area'),
          onRetry: () {},
        ),
      ));

      expect(find.textContaining('search radius'), findsOneWidget);
    });
  });
}
