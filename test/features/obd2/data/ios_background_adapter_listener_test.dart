// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/ios_background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/ios_restoration_event.dart';
import 'package:tankstellen/features/obd2/data/ios_state_restoration_service.dart';

import '../../../helpers/silence_error_logger.dart';

/// Unit tests for [IosBackgroundAdapterListener] (#3167 — hands-free
/// auto-record Phase 3).
///
/// The listener is driven entirely through its seams: a fake
/// [IosStateRestorationService] (recording + fault-injectable) and a
/// controller-backed `connectionStates` factory, so no flutter_blue_plus
/// platform channel is touched. The decision table this file covers:
///
/// | connectionState transition       | event emitted                  |
/// |----------------------------------|--------------------------------|
/// | initial replay `disconnected`    | (nothing — not a transition)   |
/// | initial replay `connected`       | AdapterConnected (restoration  |
/// |                                  | relaunch resume case)          |
/// | connected → disconnected         | AdapterDisconnected            |
/// | repeated equal states            | (de-duplicated)                |
/// | events before first subscriber   | buffered, replayed on listen   |
class _FakeRestorationService implements IosStateRestorationService {
  final List<String> registeredUuids = <String>[];
  int initializeCalls = 0;
  bool throwOnInitialize = false;
  bool throwOnRegister = false;
  IosRestorationWillRestore? launchEvent;
  bool _tagConsumed = false;

  final StreamController<IosRestorationEvent> _events =
      StreamController<IosRestorationEvent>.broadcast();

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (throwOnInitialize) {
      throw StateError('setOptions failed (injected)');
    }
  }

  @override
  Future<void> registerPersistedAdapter(String peripheralUuid) async {
    if (throwOnRegister) {
      throw StateError('pending connect failed (injected)');
    }
    registeredUuids.add(peripheralUuid);
  }

  @override
  Stream<IosRestorationEvent> get events => _events.stream;

  @override
  IosRestorationWillRestore? get launchRestoration => launchEvent;

  @override
  bool consumeLaunchRestorationTag() {
    if (launchEvent == null || _tagConsumed) return false;
    _tagConsumed = true;
    return true;
  }

  @override
  Future<void> dispose() async {
    await _events.close();
  }
}

void main() {
  silenceErrorLoggerSpool();

  late _FakeRestorationService restoration;
  late Map<String, StreamController<bool>> stateControllers;
  late IosBackgroundAdapterListener listener;

  Stream<bool> statesFor(String deviceId) {
    return stateControllers
        .putIfAbsent(deviceId, StreamController<bool>.broadcast)
        .stream;
  }

  setUp(() {
    restoration = _FakeRestorationService();
    stateControllers = <String, StreamController<bool>>{};
    listener = IosBackgroundAdapterListener(
      restoration: restoration,
      connectionStates: statesFor,
      now: () => DateTime.utc(2026, 6, 10, 12),
    );
  });

  tearDown(() async {
    await listener.dispose();
    await restoration.dispose();
    for (final c in stateControllers.values) {
      await c.close();
    }
  });

  const uuid = '0A1B2C3D-0000-1111-2222-333344445555';

  test('start() initializes restoration + registers the persisted adapter',
      () async {
    await listener.start(mac: uuid);
    expect(restoration.initializeCalls, 1);
    expect(restoration.registeredUuids, [uuid]);
  });

  test('start() is idempotent for the same uuid', () async {
    await listener.start(mac: uuid);
    await listener.start(mac: uuid);
    expect(restoration.initializeCalls, 1,
        reason: 're-arming the same adapter must not re-run the chain');
    expect(restoration.registeredUuids, [uuid]);
  });

  test('start() with a different uuid re-arms onto the new peripheral',
      () async {
    await listener.start(mac: uuid);
    const other = 'FFFFFFFF-9999-8888-7777-666655554444';
    await listener.start(mac: other);
    expect(restoration.registeredUuids, [uuid, other]);

    final events = <BackgroundAdapterEvent>[];
    final sub = listener.events.listen(events.add);
    // The OLD peripheral's stream is detached — its transitions are
    // dropped; the NEW one is live.
    stateControllers[uuid]!.add(true);
    stateControllers[other]!.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    expect(events.single, isA<AdapterConnected>());
    expect(events.single.mac, other);
    await sub.cancel();
  });

  test('connected transition emits AdapterConnected with the uuid as mac',
      () async {
    await listener.start(mac: uuid);
    final events = <BackgroundAdapterEvent>[];
    final sub = listener.events.listen(events.add);

    stateControllers[uuid]!.add(true);
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    final event = events.single as AdapterConnected;
    expect(event.mac, uuid);
    expect(event.at, DateTime.utc(2026, 6, 10, 12));
    await sub.cancel();
  });

  test(
      'initial replayed "disconnected" is swallowed — a normal launch '
      'must not arm the disconnect-save debounce', () async {
    await listener.start(mac: uuid);
    final events = <BackgroundAdapterEvent>[];
    final sub = listener.events.listen(events.add);

    stateControllers[uuid]!.add(false); // FBP replays current state
    await Future<void>.delayed(Duration.zero);
    expect(events, isEmpty);

    // A real transition afterwards flows normally.
    stateControllers[uuid]!.add(true);
    stateControllers[uuid]!.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(2));
    expect(events[0], isA<AdapterConnected>());
    expect(events[1], isA<AdapterDisconnected>());
    await sub.cancel();
  });

  test('repeated equal states are de-duplicated', () async {
    await listener.start(mac: uuid);
    final events = <BackgroundAdapterEvent>[];
    final sub = listener.events.listen(events.add);

    stateControllers[uuid]!.add(true);
    stateControllers[uuid]!.add(true);
    stateControllers[uuid]!.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1),
        reason: 'FBP replays the current state to every new stream '
            'listener — only TRANSITIONS may reach the coordinator');
    await sub.cancel();
  });

  test(
      'events emitted before the first subscriber are buffered and '
      'replayed on listen (late-subscriber contract)', () async {
    await listener.start(mac: uuid);
    // Restoration-relaunch shape: the replayed state is already
    // "connected" BEFORE the coordinator has subscribed.
    stateControllers[uuid]!.add(true);
    await Future<void>.delayed(Duration.zero);

    final events = <BackgroundAdapterEvent>[];
    final sub = listener.events.listen(events.add);
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1),
        reason: 'the restored connect must not be dropped just because '
            'the coordinator attached after start() returned');
    expect(events.single, isA<AdapterConnected>());
    await sub.cancel();
  });

  test('stop() detaches the watch — later transitions are dropped',
      () async {
    await listener.start(mac: uuid);
    final events = <BackgroundAdapterEvent>[];
    final sub = listener.events.listen(events.add);

    await listener.stop();
    stateControllers[uuid]!.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(events, isEmpty);
    await sub.cancel();
  });

  test('stop() without a prior start() completes (never throws)', () async {
    await expectLater(listener.stop(), completes);
  });

  group('fault injection (#2349 never-throws contract)', () {
    test(
        'a throwing initialize() never throws out of start() and the '
        'connection watch is still armed', () async {
      restoration.throwOnInitialize = true;
      await expectLater(listener.start(mac: uuid), completes);
      // Restoration is degraded but the live watch still works — the
      // foreground-arm path must keep functioning.
      expect(restoration.registeredUuids, [uuid],
          reason: 'a failed setOptions must not block the pending '
              'connect registration');

      final events = <BackgroundAdapterEvent>[];
      final sub = listener.events.listen(events.add);
      stateControllers[uuid]!.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      await sub.cancel();
    });

    test(
        'a throwing registerPersistedAdapter() never throws out of '
        'start()', () async {
      restoration.throwOnRegister = true;
      await expectLater(listener.start(mac: uuid), completes);

      final events = <BackgroundAdapterEvent>[];
      final sub = listener.events.listen(events.add);
      stateControllers[uuid]!.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      await sub.cancel();
    });

    test('an error on the connection-state stream is logged, not thrown',
        () async {
      await listener.start(mac: uuid);
      final events = <BackgroundAdapterEvent>[];
      final sub = listener.events.listen(events.add);

      stateControllers[uuid]!.addError(StateError('BLE stack hiccup'));
      stateControllers[uuid]!.add(true);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1),
          reason: 'the watch survives a stream error (cancelOnError is '
              'false) and keeps delivering transitions');
      await sub.cancel();
    });
  });
}
