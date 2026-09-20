// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/transport/background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/transport/ios_background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/transport/ios_restoration_event.dart';
import 'package:tankstellen/features/obd2/data/transport/ios_restoration_fence.dart';
import 'package:tankstellen/features/obd2/data/transport/ios_state_restoration_service.dart';

import '../../../helpers/silence_error_logger.dart';

/// #4357 — which trip may a restored Core Bluetooth peripheral bind to?
///
/// `centralManager:willRestoreState:` is delivered on the OS's schedule,
/// not the app's. Three orderings are not edge cases, they are the
/// normal shape of a background relaunch:
///
/// * **early** — the callback beats the owner that would consume it;
/// * **duplicate** — one relaunch delivers the same peripheral twice;
/// * **late** — the callback lands after the user pressed Stop.
///
/// And a fourth case is the one with teeth: the peripheral iOS hands
/// back is **not this trip's adapter** (a shared garage ELM327, a
/// previously paired car). Adopting it silently reassigns another
/// vehicle's link to the running trip.
///
/// Every one of those is decided by [IosRestorationIdentityFence], with
/// no clock, no channel and no hardware — so all four are pinned here,
/// first on the rule itself and then end-to-end through the
/// `IosAdapterConnectionStates` / restoration-service injection seams of
/// [IosBackgroundAdapterListener].
void main() {
  silenceErrorLoggerSpool();

  const adapterA = '0A1B2C3D-0000-1111-2222-333344445555';
  const adapterB = 'FFFFFFFF-9999-8888-7777-666655554444';

  group('the rule', () {
    late IosRestorationIdentityFence fence;

    setUp(() => fence = IosRestorationIdentityFence());

    test('a peripheral offered before any identity is bound is HELD, not '
        'guessed at', () {
      final decisions = fence.offer([adapterA]);

      expect(decisions.single.verdict, IosRestorationVerdict.deferred);
      expect(decisions.single.isRefusal, isFalse);
      expect(fence.deferredPeripheralUuids, [adapterA]);
    });

    test('binding judges what arrived early — the relaunch iOS performed '
        'to resume the link resumes it', () {
      fence.offer([adapterA]);

      final decisions = fence.bind(adapterA);

      expect(decisions.single.verdict, IosRestorationVerdict.admitted);
      expect(fence.deferredPeripheralUuids, isEmpty,
          reason: 'a held event is judged exactly once');
    });

    test('an early peripheral that turns out to be the WRONG adapter is '
        'refused when the identity arrives, not adopted', () {
      fence.offer([adapterB]);

      final decisions = fence.bind(adapterA);

      expect(decisions.single.verdict,
          IosRestorationVerdict.refusedUnknownAdapter);
      expect(decisions.single.isRefusal, isTrue);
    });

    test('a second delivery of the same peripheral is collapsed', () {
      fence.bind(adapterA);

      expect(fence.offer([adapterA]).single.verdict,
          IosRestorationVerdict.admitted);
      expect(fence.offer([adapterA]).single.verdict,
          IosRestorationVerdict.duplicateIgnored);
      expect(fence.offer([adapterA]).single.verdict,
          IosRestorationVerdict.duplicateIgnored);
    });

    test('a conflicting identity is refused while one is bound', () {
      fence.bind(adapterA);

      final decisions = fence.offer([adapterA, adapterB]);

      expect(decisions.map((d) => d.verdict), [
        IosRestorationVerdict.admitted,
        IosRestorationVerdict.refusedUnknownAdapter,
      ]);
    });

    test('after unbind a late callback is refused, and not held for the '
        'next trip either', () {
      fence.bind(adapterA);
      fence.unbind();

      final decisions = fence.offer([adapterA]);

      expect(decisions.single.verdict, IosRestorationVerdict.refusedAfterStop);
      expect(fence.deferredPeripheralUuids, isEmpty,
          reason: 'a stopped trip must not queue its own revival');
    });

    test('binding a NEW identity re-admits that adapter once', () {
      fence.bind(adapterA);
      fence.offer([adapterA]);

      fence.bind(adapterB);

      expect(fence.offer([adapterB]).single.verdict,
          IosRestorationVerdict.admitted);
      expect(fence.offer([adapterA]).single.verdict,
          IosRestorationVerdict.refusedUnknownAdapter);
    });

    test('the held buffer is bounded — an OS relaunch loop cannot grow it',
        () {
      for (var i = 0; i < 40; i++) {
        fence.offer(['uuid-$i']);
      }

      expect(fence.deferredPeripheralUuids, hasLength(16));
      expect(fence.deferredPeripheralUuids.last, 'uuid-39',
          reason: 'the newest events are the ones worth keeping');
    });
  });

  group('the listener — restoration ordering through the injection seams',
      () {
    late _FakeRestorationService restoration;
    late Map<String, StreamController<bool>> stateControllers;
    late IosBackgroundAdapterListener listener;

    Stream<bool> statesFor(String deviceId) => stateControllers
        .putIfAbsent(deviceId, StreamController<bool>.broadcast)
        .stream;

    setUp(() {
      restoration = _FakeRestorationService();
      stateControllers = <String, StreamController<bool>>{};
      listener = IosBackgroundAdapterListener(
        restoration: restoration,
        connectionStates: statesFor,
        now: () => DateTime.utc(2026, 9, 20, 8),
      );
    });

    tearDown(() async {
      await listener.dispose();
      await restoration.dispose();
      for (final c in stateControllers.values) {
        await c.close();
      }
    });

    /// Deliver a `willRestoreState` and let the subscription run.
    Future<void> restore(List<String> uuids) async {
      restoration.emit(IosRestorationEvent.willRestore(uuids));
      await pumpEventQueue();
    }

    test('EARLY: a restoration delivered before start() is not dropped — it '
        'is judged, and admitted, when the trip arms', () async {
      await restore([adapterA]);
      expect(listener.lastRestorationDecisions.single.verdict,
          IosRestorationVerdict.deferred);
      expect(restoration.registeredUuids, isEmpty);

      await listener.start(mac: adapterA);
      await pumpEventQueue();

      expect(listener.lastRestorationDecisions.single.verdict,
          IosRestorationVerdict.admitted);
      expect(restoration.registeredUuids, [adapterA, adapterA],
          reason: 'the arm itself, then the admitted restoration re-arming '
              'the pending connect for the same adapter');
    });

    test('EARLY + CONFLICT: a held peripheral that is not this trip\'s '
        'adapter is refused, never re-armed', () async {
      await restore([adapterB]);

      await listener.start(mac: adapterA);
      await pumpEventQueue();

      expect(listener.lastRestorationDecisions.single.verdict,
          IosRestorationVerdict.refusedUnknownAdapter);
      expect(restoration.registeredUuids, [adapterA],
          reason: 'only the trip\'s own adapter was ever pended');
    });

    test('DUPLICATE: the same peripheral twice re-arms once', () async {
      await listener.start(mac: adapterA);
      await restore([adapterA]);
      await restore([adapterA]);

      expect(listener.lastRestorationDecisions.single.verdict,
          IosRestorationVerdict.duplicateIgnored);
      expect(restoration.registeredUuids, [adapterA, adapterA],
          reason: 'the arm plus exactly one admitted restoration');
    });

    test('CONFLICT: a foreign peripheral never becomes an AdapterConnected',
        () async {
      final events = <BackgroundAdapterEvent>[];
      final sub = listener.events.listen(events.add);
      await listener.start(mac: adapterA);

      await restore([adapterB]);
      // The foreign adapter's own connection stream is irrelevant: it
      // was never watched.
      stateControllers
          .putIfAbsent(adapterB, StreamController<bool>.broadcast)
          .add(true);
      await pumpEventQueue();

      expect(events, isEmpty);
      expect(listener.lastRestorationDecisions.single.verdict,
          IosRestorationVerdict.refusedUnknownAdapter);
      await sub.cancel();
    });

    test('LATE: a restoration after stop() cannot revive the trip', () async {
      await listener.start(mac: adapterA);
      await listener.stop();
      final armsAtStop = restoration.registeredUuids.length;
      final events = <BackgroundAdapterEvent>[];
      final sub = listener.events.listen(events.add);

      await restore([adapterA]);

      expect(listener.lastRestorationDecisions.single.verdict,
          IosRestorationVerdict.refusedAfterStop);
      expect(restoration.registeredUuids, hasLength(armsAtStop),
          reason: 'Stop is authoritative — nothing re-pends behind it');
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('LATE then RESTART: the next trip binds cleanly, and the stale '
        'peripheral stays refused', () async {
      await listener.start(mac: adapterA);
      await listener.stop();
      await restore([adapterA]);

      await listener.start(mac: adapterB);
      await restore([adapterA]);

      expect(listener.lastRestorationDecisions.single.verdict,
          IosRestorationVerdict.refusedUnknownAdapter);

      await restore([adapterB]);
      expect(listener.lastRestorationDecisions.single.verdict,
          IosRestorationVerdict.admitted);
    });

    test('an admitted restoration still routes the live link through the '
        'connection-state watch, not through the restoration event',
        () async {
      final events = <BackgroundAdapterEvent>[];
      final sub = listener.events.listen(events.add);
      await listener.start(mac: adapterA);

      await restore([adapterA]);
      expect(events, isEmpty,
          reason: 'admission re-arms the pending connect; it does not '
              'fabricate a connection');

      stateControllers[adapterA]!.add(true);
      await pumpEventQueue();

      expect(events.single, isA<AdapterConnected>());
      expect((events.single as AdapterConnected).mac, adapterA);
      await sub.cancel();
    });

    test('a restoration-service stream error does not kill the fence',
        () async {
      restoration.emitError(StateError('restoration channel blew up'));
      await pumpEventQueue();

      await listener.start(mac: adapterA);
      await restore([adapterA]);

      expect(listener.lastRestorationDecisions.single.verdict,
          IosRestorationVerdict.admitted);
    });
  });
}

class _FakeRestorationService implements IosStateRestorationService {
  final List<String> registeredUuids = <String>[];
  int initializeCalls = 0;

  final StreamController<IosRestorationEvent> _events =
      StreamController<IosRestorationEvent>.broadcast();

  void emit(IosRestorationEvent event) => _events.add(event);

  void emitError(Object error) => _events.addError(error, StackTrace.current);

  @override
  Future<void> initialize() async => initializeCalls++;

  @override
  Future<void> registerPersistedAdapter(String peripheralUuid) async {
    registeredUuids.add(peripheralUuid);
  }

  @override
  Stream<IosRestorationEvent> get events => _events.stream;

  @override
  IosRestorationWillRestore? get launchRestoration => null;

  @override
  bool consumeLaunchRestorationTag() => false;

  @override
  Future<void> dispose() async {
    if (!_events.isClosed) await _events.close();
  }
}
