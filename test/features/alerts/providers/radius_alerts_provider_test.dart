// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/notifications/notification_providers.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_store.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';

/// [RadiusAlertStore] that always throws on [upsert] and [remove], used to
/// verify that write failures surface as AsyncError rather than false success
/// (#2314). [list] returns an empty list so build() succeeds.
class _ThrowingRadiusAlertStore extends RadiusAlertStore {
  @override
  Future<List<RadiusAlert>> list() async => const [];

  @override
  Future<void> upsert(RadiusAlert alert) async =>
      throw Exception('Simulated upsert failure (#2314)');

  @override
  Future<void> remove(String id) async =>
      throw Exception('Simulated remove failure (#2314)');
}

/// No-op NotificationService that counts permission requests so the
/// #2246 radius-permission tests can assert the prompt fires without
/// touching real plugins.
class _NoopNotificationService implements NotificationService {
  int requestPermissionCalls = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return true;
  }

  @override
  Future<bool> areNotificationsEnabled() async => true;
  @override
  Future<void> showPriceAlert(
      {required int id,
      required String title,
      required String body,
      String? payload}) async {}
  @override
  Future<void> showServiceReminder(
      {required int id, required String title, required String body}) async {}
  @override
  Future<void> cancelNotification(int id) async {}
  @override
  Future<void> cancelAll() async {}
}

void main() {
  late Directory tempDir;

  RadiusAlert makeAlert({
    String id = 'r1',
    String fuelType = 'diesel',
    double threshold = 1.55,
    bool enabled = true,
    DateTime? createdAt,
  }) {
    return RadiusAlert(
      id: id,
      fuelType: fuelType,
      threshold: threshold,
      centerLat: 48.0,
      centerLng: 2.0,
      radiusKm: 10,
      label: 'Home',
      createdAt: createdAt ?? DateTime(2026, 1, 1, 10, 0),
      enabled: enabled,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_radius_prov_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(HiveBoxes.alerts)) {
      await Hive.box<dynamic>(HiveBoxes.alerts).close();
    }
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
    await Hive.box<dynamic>(HiveBoxes.alerts).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('radiusAlertsProvider', () {
    test('build() returns the empty list when no alerts are persisted',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(radiusAlertsProvider.future);
      expect(result, isEmpty);
    });

    test('add() persists the alert and pushes it to state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Prime the provider so state transitions from loading → data.
      await container.read(radiusAlertsProvider.future);

      final alert = makeAlert(id: 'added');
      await container.read(radiusAlertsProvider.notifier).add(alert);

      final state = container.read(radiusAlertsProvider).value;
      expect(state, isNotNull);
      expect(state!, hasLength(1));
      expect(state.first.id, 'added');
    });

    test('build() loads previously persisted alerts', () async {
      // Write directly via the store, then spin up the provider.
      final store = RadiusAlertStore();
      await store.upsert(makeAlert(id: 'preloaded'));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(radiusAlertsProvider.future);
      expect(result, hasLength(1));
      expect(result.first.id, 'preloaded');
    });

    test('remove() drops the alert and keeps the rest', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(radiusAlertsProvider.future);

      final notifier = container.read(radiusAlertsProvider.notifier);
      await notifier.add(makeAlert(id: 'keep', createdAt: DateTime(2026, 1, 1)));
      await notifier.add(makeAlert(id: 'drop', createdAt: DateTime(2026, 1, 2)));

      await notifier.remove('drop');

      final state = container.read(radiusAlertsProvider).value!;
      expect(state.map((a) => a.id), ['keep']);
    });

    test('remove() with an unknown id is a silent no-op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(radiusAlertsProvider.future);

      final notifier = container.read(radiusAlertsProvider.notifier);
      await notifier.add(makeAlert(id: 'a1'));

      await notifier.remove('not-there');

      final state = container.read(radiusAlertsProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.id, 'a1');
    });

    test('toggle() flips enabled and persists the change', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(radiusAlertsProvider.future);

      final notifier = container.read(radiusAlertsProvider.notifier);
      await notifier.add(makeAlert(id: 't1', enabled: true));

      await notifier.toggle('t1');

      var state = container.read(radiusAlertsProvider).value!;
      expect(state.single.enabled, isFalse);

      await notifier.toggle('t1');
      state = container.read(radiusAlertsProvider).value!;
      expect(state.single.enabled, isTrue);
    });

    test('toggle() with an unknown id leaves state untouched', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(radiusAlertsProvider.future);

      final notifier = container.read(radiusAlertsProvider.notifier);
      await notifier.add(makeAlert(id: 'real', enabled: true));

      await notifier.toggle('ghost');

      final state = container.read(radiusAlertsProvider).value!;
      expect(state, hasLength(1));
      expect(state.single.id, 'real');
      expect(state.single.enabled, isTrue);
    });
  });

  group('write-error surfaces AsyncValue.error, not false success (#2314)', () {
    test('add(): a store upsert failure sets AsyncError state', () async {
      final throwingStore = _ThrowingRadiusAlertStore();
      final container = ProviderContainer(
        overrides: [
          radiusAlertStoreProvider.overrideWithValue(throwingStore),
        ],
      );
      addTearDown(container.dispose);
      // Prime the provider so we start from a data state.
      await container.read(radiusAlertsProvider.future);
      expect(container.read(radiusAlertsProvider).hasValue, isTrue);

      await container.read(radiusAlertsProvider.notifier).add(makeAlert());
      // The write threw → state must be AsyncError, not stale data.
      expect(container.read(radiusAlertsProvider).hasError, isTrue);
    });
  });

  group('radius alert notification permission (#2246)', () {
    late _NoopNotificationService noopNotifier;

    ProviderContainer makeContainer() {
      noopNotifier = _NoopNotificationService();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(noopNotifier),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('add() requests the OS notification permission', () async {
      final container = makeContainer();
      await container.read(radiusAlertsProvider.future);

      await container
          .read(radiusAlertsProvider.notifier)
          .add(makeAlert(id: 'perm', enabled: true));

      // unawaited fire-and-forget — let the microtask run.
      await Future<void>.delayed(Duration.zero);
      expect(noopNotifier.requestPermissionCalls, 1);
    });

    test('toggle() to enabled requests the permission; disabling does not',
        () async {
      final container = makeContainer();
      await container.read(radiusAlertsProvider.future);
      final notifier = container.read(radiusAlertsProvider.notifier);

      // Start enabled (add prompts once).
      await notifier.add(makeAlert(id: 'tog', enabled: true));
      await Future<void>.delayed(Duration.zero);
      final afterAdd = noopNotifier.requestPermissionCalls;

      // Disable — should NOT prompt.
      await notifier.toggle('tog');
      await Future<void>.delayed(Duration.zero);
      expect(noopNotifier.requestPermissionCalls, afterAdd,
          reason: 'disabling an alert must not re-prompt');

      // Re-enable — should prompt again.
      await notifier.toggle('tog');
      await Future<void>.delayed(Duration.zero);
      expect(noopNotifier.requestPermissionCalls, afterAdd + 1,
          reason: 're-enabling is a user-intent moment → request again');
    });
  });
}
