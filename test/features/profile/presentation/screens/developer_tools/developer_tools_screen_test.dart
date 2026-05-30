// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/notification_providers.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/features/approach/presentation/widgets/approach_test_panel.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/developer_tools_screen.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../../../helpers/pump_app.dart';

/// SearchState override that emits a fixed list of search results, so the
/// dev-tools "Run test alert" action can resolve a REAL station to fire
/// against (#2408). An empty list models "user has not searched yet".
class _FakeSearchState extends SearchState {
  _FakeSearchState(this.items);

  final List<SearchResultItem> items;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return AsyncValue.data(ServiceResult(
      data: items,
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }
}

const _station = Station(
  id: 'de-12345',
  name: 'Shell Hauptstraße',
  brand: 'Shell',
  street: 'Hauptstraße 1',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5,
  lng: 13.4,
  e10: 1.789,
  diesel: 1.659,
  isOpen: true,
);

/// TraceStorage that never touches Hive — the screen reads `count`
/// during build.
class _StubTraceStorage extends TraceStorage {
  @override
  int get count => 0;
}

/// Records every notification fired by the screen's actions so the test
/// can assert the test-alert / test-notification path reaches the
/// service. Permission is granted by default; set [permissionGranted] to
/// false to exercise the blocked path.
class _FakeNotifier implements NotificationService {
  _FakeNotifier({this.permissionGranted = true});

  final bool permissionGranted;
  final List<({int id, String title, String body})> fired = [];

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    fired.add((id: id, title: title, body: body));
  }

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  group('DeveloperToolsScreen (#2248)', () {
    List<Object> overrides({
      required bool debugOn,
      _FakeNotifier? notifier,
      List<SearchResultItem> searchResults = const [],
    }) =>
        [
          enabledFeaturesProvider.overrideWithValue(
            debugOn ? {Feature.debugMode} : <Feature>{},
          ),
          buildChannelProvider.overrideWithValue(BuildChannel.beta),
          traceStorageProvider.overrideWithValue(_StubTraceStorage()),
          notificationServiceProvider
              .overrideWithValue(notifier ?? _FakeNotifier()),
          searchStateProvider.overrideWith(
            () => _FakeSearchState(searchResults),
          ),
        ];

    testWidgets('renders the dev tools when debugMode is ON', (tester) async {
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: true),
      );

      expect(find.byKey(const ValueKey('error-log-export-button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('debug-fire-test-notification')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('debug-run-test-alert')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('debug-feature-flag-dump')),
          findsOneWidget);
      // #2471 — the OBD2 communication-health row joins the Diagnostics
      // section. Its arrival pushes the rows below it off the first fold,
      // so scroll each remaining target into view before asserting.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('debug-obd2-health')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('debug-obd2-health')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('debug-copy-diagnostics')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('debug-clear-caches')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('debug-copy-diagnostics')),
          findsOneWidget);
    });

    testWidgets('hosts the approach-overlay test panel (#2382 — moved here '
        'from the Privacy Dashboard)', (tester) async {
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: true),
      );

      // The panel sits near the bottom of the scrollable dev-tools list,
      // so scroll it into view before asserting it renders.
      await tester.scrollUntilVisible(
        find.byType(ApproachTestPanel),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byType(ApproachTestPanel), findsOneWidget,
          reason: 'the approach-overlay simulator is a dev test surface and '
              'belongs in Developer tools, not the Privacy Dashboard');
    });

    testWidgets('renders nothing when debugMode is OFF (defensive guard)',
        (tester) async {
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: false),
      );

      // The defensive guard collapses the body to an empty shrink so a
      // stale deep-link can never expose the tools.
      expect(find.byKey(const ValueKey('error-log-export-button')),
          findsNothing);
      expect(find.byKey(const ValueKey('debug-fire-test-notification')),
          findsNothing);
      expect(find.byKey(const ValueKey('debug-run-test-alert')),
          findsNothing);
    });

    testWidgets('Fire test notification invokes the notification service',
        (tester) async {
      final notifier = _FakeNotifier();
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: true, notifier: notifier),
      );

      await tester.tap(
        find.byKey(const ValueKey('debug-fire-test-notification')),
      );
      await tester.pumpAndSettle();

      expect(notifier.fired, hasLength(1));
    });

    testWidgets(
        'Run test alert pipeline fires against the real search-result station',
        (tester) async {
      final notifier = _FakeNotifier();
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(
          debugOn: true,
          notifier: notifier,
          searchResults: const [FuelStationResult(_station)],
        ),
      );

      await tester.tap(find.byKey(const ValueKey('debug-run-test-alert')));
      await tester.pumpAndSettle();

      expect(notifier.fired, hasLength(1),
          reason: 'a real station resolved from search drives the pipeline '
              'to deliver exactly one notification');
      // #2408 — the body names the real station via the interpolated ARB.
      expect(notifier.fired.single.body, contains('Shell'));
    });

    testWidgets(
        'Run test alert with no search results shows search-first and fires '
        'nothing (#2408)', (tester) async {
      final notifier = _FakeNotifier();
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        // No search results → no resolvable station id.
        overrides: overrides(debugOn: true, notifier: notifier),
      );

      await tester.tap(find.byKey(const ValueKey('debug-run-test-alert')));
      await tester.pumpAndSettle();

      expect(notifier.fired, isEmpty,
          reason: 'firing a non-resolving synthetic deep link is exactly the '
              'stuck-shimmer bug — guide the user to search first instead');
      expect(find.textContaining('Search for stations first'), findsOneWidget);
    });

    testWidgets('blocked notifications fire nothing on Fire test notification',
        (tester) async {
      final notifier = _FakeNotifier(permissionGranted: false);
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: true, notifier: notifier),
      );

      await tester.tap(
        find.byKey(const ValueKey('debug-fire-test-notification')),
      );
      await tester.pumpAndSettle();

      expect(notifier.fired, isEmpty);
    });
  });
}
