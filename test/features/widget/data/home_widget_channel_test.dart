// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/widget/data/home_widget_service.dart';
import 'package:tankstellen/features/widget/presentation/widget_click_listener.dart';

/// Channel-level coverage for the home-screen widget (#2352).
///
/// The existing `home_widget_service_test.dart` only asserts
/// `expect(HomeWidgetService.updateWidget, isNotNull)`; the JSON payload
/// and the warm-tap launch-URI dispatch (#2157/#2158) both bypass the
/// `home_widget` platform channel entirely in the other suites. This
/// file intercepts the real channel via `setMockMethodCallHandler` /
/// `setMockStreamHandler` and asserts:
///
///   1. The `stations_json` payload actually crosses the channel with
///      the expected per-row schema (the bytes the native widget reads).
///   2. The resume-time warm-tap fallback (#2157) reads
///      `initiallyLaunchedFromHomeWidget` off the channel and dispatches
///      the URI to the router — the regression that #2157/#2158 fixed,
///      previously untestable through the channel.

/// Minimal in-memory [FavoriteStorage] — only the three reads
/// `HomeWidgetService.updateWidget` performs are implemented; the rest
/// throw so an accidental new dependency fails loudly.
class _InMemoryFavoriteStorage implements FavoriteStorage {
  _InMemoryFavoriteStorage(this._ids, this._data);

  final List<String> _ids;
  final Map<String, Map<String, dynamic>> _data;

  @override
  List<String> getFavoriteIds() => List.unmodifiable(_ids);

  @override
  Map<String, dynamic>? getFavoriteStationData(String id) => _data[id];

  @override
  Map<String, dynamic> getAllFavoriteStationData() =>
      Map.unmodifiable(_data);

  @override
  int get favoriteCount => _ids.length;
  @override
  bool isFavorite(String id) => _ids.contains(id);
  @override
  Future<void> addFavorite(String id) => throw UnimplementedError();
  @override
  Future<void> removeFavorite(String id) => throw UnimplementedError();
  @override
  Future<void> setFavoriteIds(List<String> ids) => throw UnimplementedError();
  @override
  Future<void> saveFavoriteStationData(String id, Map<String, dynamic> d) =>
      throw UnimplementedError();
  @override
  Future<void> removeFavoriteStationData(String id) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  const updatesChannel = EventChannel('home_widget/updates');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('home_widget channel — JSON payload (#2352)', () {
    late Map<String, Object?> saved;

    setUp(() {
      saved = <String, Object?>{};
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'saveWidgetData':
            final args = (call.arguments as Map).cast<String, Object?>();
            saved[args['id']! as String] = args['data'];
            return true;
          case 'updateWidget':
          case 'setAppGroupId':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test(
        'updateWidget writes station_count + stations_json across the channel '
        'with the full per-row schema the native widget reads', () async {
      final storage = _InMemoryFavoriteStorage(
        ['de-shell-01'],
        {
          'de-shell-01': const {
            'brand': 'Shell',
            'name': 'Shell Berlin',
            'street': 'Oranienstr. 1',
            'postCode': '10969',
            'place': 'Berlin',
            'lat': 52.5041,
            'lng': 13.4081,
            'e5': 1.899,
            'e10': 1.849,
            'diesel': 1.799,
            'isOpen': true,
          },
        },
      );

      await HomeWidgetService.updateWidget(storage);

      // The count crossed the channel.
      expect(saved['station_count'], 1,
          reason: 'station_count must cross the channel for the native '
              'widget to size its list');

      // The JSON payload crossed the channel and carries the row schema.
      final jsonStr = saved['stations_json'] as String?;
      expect(jsonStr, isNotNull,
          reason: 'stations_json must be written on every favorites update');
      final rows = (jsonDecode(jsonStr!) as List).cast<Map<String, dynamic>>();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row['id'], 'de-shell-01',
          reason: 'the id is what the native PendingIntent binds the tap to '
              '(#753) — it must survive the channel hop');
      expect(row['brand'], 'Shell');
      expect(row['e10'], 1.849);
      expect(row['isOpen'], true);
      expect(row['currency'], '€',
          reason: 'currency is resolved server-side of the channel and must '
              'reach the native renderer');

      // An `updated_at` freshness stamp is also pushed.
      expect(saved['updated_at'], isA<String>());
    });

    test('empty favorites writes an empty payload (no stale rows linger)',
        () async {
      final storage = _InMemoryFavoriteStorage([], const {});
      await HomeWidgetService.updateWidget(storage);
      expect(saved['station_count'], 0);
      expect(saved['stations_json'], '[]',
          reason: 'an empty list must clear the rows, not leave the prior '
              'payload on the channel');
    });
  });

  group('home_widget channel — warm-tap launch-URI dispatch (#2157/#2158)',
      () {
    String? launchUri;

    GoRouter buildRouter() => GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (_, _) => const Text('home')),
            GoRoute(
              path: '/station/:id',
              builder: (_, state) =>
                  Text('station ${state.pathParameters['id']}'),
            ),
          ],
        );

    setUp(() {
      launchUri = null;
      // Mock the MethodChannel: the resume-time fallback reads
      // `initiallyLaunchedFromHomeWidget` off this channel (#2157).
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'initiallyLaunchedFromHomeWidget') {
          return launchUri;
        }
        return null;
      });
      // Mock the EventChannel the `widgetClicked` Stream subscribes to in
      // initState so the subscription doesn't error; it emits nothing —
      // the warm tap is delivered via the resume-time fallback instead,
      // which is the exact #2157 OEM path the Stream loses.
      messenger.setMockStreamHandler(
        updatesChannel,
        MockStreamHandler.inline(onListen: (_, _) {}),
      );
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      messenger.setMockStreamHandler(updatesChannel, null);
    });

    Future<ProviderContainer> pumpListener(
      WidgetTester tester,
      GoRouter router,
    ) async {
      final container = ProviderContainer(
        overrides: [routerProvider.overrideWith((_) => router)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) =>
                WidgetClickListener(child: child ?? const SizedBox.shrink()),
          ),
        ),
      );
      return container;
    }

    testWidgets(
        'a warm tap delivered via initiallyLaunchedFromHomeWidget on resume '
        'pushes /station/:id (the #2157 resume-time fallback)',
        (tester) async {
      final router = buildRouter();
      await pumpListener(tester, router);
      expect(find.text('home'), findsOneWidget);

      // The OS reports the activity's current intent carries the widget
      // URI; the listener re-reads it on resume.
      launchUri = 'tankstellenwidget://station?id=de-77';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/station/de-77',
          reason: 'the resume-time fallback must read the launch URI off '
              'the channel and navigate — #2157/#2158 regressed exactly '
              'this path on singleTop OEM ROMs');
      expect(find.text('station de-77'), findsOneWidget);
    });

    testWidgets(
        'the same launch URI re-reported on a second resume is NOT pushed '
        'twice (#2157 _lastDispatched dedupe)', (tester) async {
      final router = buildRouter();
      await pumpListener(tester, router);

      launchUri = 'tankstellenwidget://station?id=de-99';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/station/de-99');

      // The activity intent still carries the same URI on the next resume.
      // The dedupe guard must keep it a no-op (no second push of the same
      // station on top of itself).
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Still on the same single station route — not stacked twice.
      expect(router.state.matchedLocation, '/station/de-99');
      expect(
        find.text('station de-99'),
        findsOneWidget,
        reason: 'a duplicate resume of the same widget URI must not '
            're-dispatch — the _lastDispatched guard (#2157) prevents the '
            'double navigation that flashed the detail screen.',
      );
    });

    testWidgets(
        'no launch URI on resume → no navigation (ordinary app resume)',
        (tester) async {
      final router = buildRouter();
      await pumpListener(tester, router);

      // launchUri stays null — a normal resume with no widget tap.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/',
          reason: 'a resume with no pending widget URI must not navigate');
      expect(find.text('home'), findsOneWidget);
    });
  });
}
