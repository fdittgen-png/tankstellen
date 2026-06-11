// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Tests for the per-platform native-widget reload dispatch (#3171).
//
// Three concerns:
//
//   1. **Dispatch shape** — on iOS the home_widget plugin REQUIRES a
//      widget name (`reloadTimelines(ofKind:)`), so the dispatcher must
//      issue one `updateWidget` per WidgetKit kind with the `ios` arg
//      set. On Android it must keep the single fully-qualified-name call
//      (#2206/#2207 — short `android` name stays null).
//
//   2. **Swift lock-step guards** — `kIosWidgetKinds` must match the
//      `kind` literals in the widget extension, and the manual-refresh
//      UserDefaults key must match the one `WidgetRefreshIntent.swift`
//      writes. Drift on either side silently kills reloads / the refresh
//      button, so the contract is pinned here.
//
//   3. **Favorites payload content** — the favorites snapshot the iOS
//      Favorites widget renders must carry the `isCheapest` flag
//      (#2600-parity with the nearest payload).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/widget/data/home_widget_service.dart';
import 'package:tankstellen/features/widget/data/impl/widget_reload_dispatcher.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../fakes/fake_storage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getInstalledWidgets') return <dynamic>[];
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugNotifyNativeWidgetsIsIos = null;
  });

  List<MethodCall> updateCalls() =>
      calls.where((c) => c.method == 'updateWidget').toList();

  group('notifyNativeWidgets dispatch (#3171)', () {
    test('iOS: one reload per WidgetKit kind, `ios` arg set, no Android '
        'name', () async {
      debugNotifyNativeWidgetsIsIos = true;

      await notifyNativeWidgets();

      final updates = updateCalls();
      expect(updates, hasLength(kIosWidgetKinds.length));
      final reloadedKinds = updates.map((c) {
        final args = (c.arguments as Map).cast<String, dynamic>();
        expect(args['qualifiedAndroidName'], isNull,
            reason: 'the iOS branch must not carry Android resolution args');
        expect(args['android'], isNull);
        return args['ios'] as String?;
      }).toList();
      expect(reloadedKinds, kIosWidgetKinds,
          reason: 'every kind in the bundle must be reloaded — a missing '
              'kind silently stops that widget from refreshing on writes');
    });

    test('Android: single call with ONLY the fully-qualified provider name '
        '(#2206/#2207)', () async {
      debugNotifyNativeWidgetsIsIos = false;

      await notifyNativeWidgets();

      final updates = updateCalls();
      expect(updates, hasLength(1));
      final args = (updates.single.arguments as Map).cast<String, dynamic>();
      expect(args['qualifiedAndroidName'], kWidgetQualifiedAndroidName);
      expect(args['android'], isNull,
          reason: 'the short androidName must stay null so a failure can '
              'never report the wrong (short) name');
      expect(args['ios'], isNull);
    });
  });

  group('Swift lock-step guards (#3171)', () {
    // Repo-relative — `flutter test` runs from the package root.
    final widgetDir = Directory('ios/TankstellenWidget');

    test('kIosWidgetKinds matches the `kind` literals in the widget '
        'extension', () {
      final kindPattern =
          RegExp(r'let kind: String = "([A-Za-z]+)"', multiLine: true);
      final swiftKinds = <String>{};
      for (final entity in widgetDir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.swift')) continue;
        for (final m in kindPattern.allMatches(entity.readAsStringSync())) {
          swiftKinds.add(m.group(1)!);
        }
      }
      expect(swiftKinds, kIosWidgetKinds.toSet(),
          reason: 'kIosWidgetKinds and the Swift `kind` literals break '
              'together — a drift means a widget that never reloads when '
              'the Dart side writes new data');
    });

    test('manual-refresh UserDefaults key matches WidgetRefreshIntent.swift',
        () {
      final intentSource =
          File('ios/TankstellenWidget/WidgetRefreshIntent.swift')
              .readAsStringSync();
      expect(
        intentSource,
        contains('"$kWidgetManualRefreshRequestedAtKey"'),
        reason: 'the AppIntent writes — and the Dart heartbeat reads — '
            'this exact key; a drift makes the refresh button a no-op',
      );
    });
  });

  group('favorites payload content (#3171 — iOS favorites variant)', () {
    test('stations_json rows carry isCheapest, true only on the '
        'minimum-priced favorite', () async {
      final fake = FakeHiveStorage();
      await fake.saveProfile('p1', const {
        'id': 'p1',
        'name': 'Std',
        'preferredFuelType': 'e10',
        'defaultSearchRadius': 10.0,
      });
      await fake.setActiveProfileId('p1');
      await fake.addFavorite('de-cheap');
      await fake.addFavorite('de-pricey');
      await fake.saveFavoriteStationData('de-cheap', const {
        'brand': 'Jet',
        'street': 'A-Str. 1',
        'lat': 52.5,
        'lng': 13.4,
        'e10': 1.799,
        'isOpen': true,
      });
      await fake.saveFavoriteStationData('de-pricey', const {
        'brand': 'Aral',
        'street': 'B-Str. 2',
        'lat': 52.6,
        'lng': 13.5,
        'e10': 1.899,
        'isOpen': true,
      });
      final storage = FakeStorageRepository(inner: fake);

      await HomeWidgetService.updateWidget(
        storage,
        profileStorage: storage,
        settingsStorage: storage,
      );

      final saved = calls
          .where((c) =>
              c.method == 'saveWidgetData' &&
              (c.arguments as Map)['id'] == 'stations_json')
          .toList();
      expect(saved, isNotEmpty,
          reason: 'updateWidget must write the favorites snapshot');
      final rows = (jsonDecode(
        (saved.last.arguments as Map)['data'] as String,
      ) as List)
          .cast<Map<String, dynamic>>();
      expect(rows, hasLength(2));

      final byId = {for (final r in rows) r['id'] as String: r};
      expect(byId['de-cheap']!['isCheapest'], isTrue);
      expect(byId['de-pricey']!['isCheapest'], isFalse);
    });
  });
}
