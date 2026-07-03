// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_events.dart';
import 'package:tankstellen/core/utils/event_loop_yield.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// #3451 — chunked bulk persists: the write loop must periodically yield
/// through the EVENT queue (not just microtasks — those never let the
/// frame scheduler run) while preserving write order, and a 100-row merge
/// must still complete with every row written.
void main() {
  silenceErrorLoggerSpool();

  group('yieldToEventLoopEvery', () {
    test('a 100-iteration loop yields to the event loop mid-loop AND '
        'preserves write order', () async {
      final writes = <int>[];
      var timerFired = false;
      var sawTimerMidLoop = false;
      // A zero-duration TIMER runs from the event queue: it can only fire
      // mid-loop if the loop genuinely yields past the microtask queue.
      unawaited(
          Future<void>.delayed(Duration.zero).then((_) => timerFired = true));

      for (var i = 0; i < 100; i++) {
        writes.add(i);
        await yieldToEventLoopEvery(i);
        if (timerFired) sawTimerMidLoop = true;
      }

      expect(writes, List.generate(100, (i) => i),
          reason: 'yielding must never reorder the writes');
      expect(sawTimerMidLoop, isTrue,
          reason: 'with N=25 a 100-write loop must yield to the event '
              'queue (4 times), letting timers/frames interleave');
    });

    test('control — without reaching the chunk size the loop never leaves '
        'the microtask queue', () async {
      var timerFired = false;
      unawaited(
          Future<void>.delayed(Duration.zero).then((_) => timerFired = true));

      for (var i = 0; i < 20; i++) {
        await yieldToEventLoopEvery(i); // 20 < 25 → no event-loop yield
      }

      expect(timerFired, isFalse,
          reason: 'sub-chunk loops stay microtask-only (cheap path)');
    });
  });

  test('a fake 100-row vehicles mergeFrom completes, writes all rows in '
      'order and emits once (#3451 chunked persist end-to-end)', () async {
    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(FakeHiveStorage()),
    ]);
    addTearDown(container.dispose);
    final events = <SyncTableChanged>[];
    final sub =
        SyncEvents.instance.forTable(SyncTables.vehicles).listen(events.add);
    addTearDown(sub.cancel);

    final incoming =
        List.generate(100, (i) => VehicleProfile(id: 'v-$i', name: 'Car $i'));
    final added = await container
        .read(vehicleProfileListProvider.notifier)
        .mergeFrom(incoming);
    await Future<void>.delayed(Duration.zero); // broadcast delivery

    expect(added, 100);
    expect(
      container.read(vehicleProfileListProvider).map((v) => v.id).toList(),
      List.generate(100, (i) => 'v-$i'),
      reason: 'chunk yields must not reorder the persisted rows',
    );
    expect(events.single.changedCount, 100);
  });
}
