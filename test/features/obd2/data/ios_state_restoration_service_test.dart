// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/ios_restoration_event.dart';
import 'package:tankstellen/features/obd2/data/ios_state_restoration_service.dart';

import '../../../helpers/silence_error_logger.dart';

/// Unit tests for [FlutterBluePlusIosStateRestorationService] (#1295
/// phase 2).
///
/// These tests run on the Dart VM — no iOS runtime. The iOS-specific
/// path (which actually calls into `flutter_blue_plus`) cannot be
/// exercised here because:
///
/// * `FlutterBluePlus.setOptions` calls a MethodChannel that is
///   unbound in `flutter_test`.
/// * `BluetoothDevice.fromId(...).connect(...)` likewise crosses the
///   platform channel.
///
/// We therefore cover the dispatcher (the `Platform.isIOS` gate) by
/// driving the test seam `debugIsIOSOverride` and asserting that
/// non-iOS branches are no-ops + that the events stream emits the
/// expected sentinel. Phase 5 (device-test acceptance) covers the
/// real iOS path on hardware.
void main() {
  silenceErrorLoggerSpool();

  group(
      'FlutterBluePlusIosStateRestorationService — launch restoration '
      'capture (#3167)', () {
    test(
        'iOS launch WITH bluetoothCentrals launch options caches '
        'launchRestoration and emits willRestore', () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: true,
        debugSetOptionsOverride: () async {},
        debugLaunchCentralIdsFetcher: () async =>
            <String>['flutterBluePlusRestoreIdentifier'],
      );
      final received = <IosRestorationEvent>[];
      final sub = service.events.listen(received.add);

      await service.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(service.launchRestoration, isNotNull,
          reason: 'the cached getter is what late consumers (the iOS '
              'listener arms after app init) read');
      expect(received, [const IosRestorationEvent.willRestore(<String>[])]);

      await sub.cancel();
      await service.dispose();
    });

    test('iOS launch WITHOUT the key leaves launchRestoration null',
        () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: true,
        debugSetOptionsOverride: () async {},
        debugLaunchCentralIdsFetcher: () async => null,
      );
      await service.initialize();
      expect(service.launchRestoration, isNull);
      expect(service.consumeLaunchRestorationTag(), isFalse);
      await service.dispose();
    });

    test('empty central-id list counts as a normal launch', () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: true,
        debugSetOptionsOverride: () async {},
        debugLaunchCentralIdsFetcher: () async => const <String>[],
      );
      await service.initialize();
      expect(service.launchRestoration, isNull);
      await service.dispose();
    });

    test('consumeLaunchRestorationTag is one-shot', () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: true,
        debugSetOptionsOverride: () async {},
        debugLaunchCentralIdsFetcher: () async => <String>['fbp'],
      );
      await service.initialize();
      expect(service.consumeLaunchRestorationTag(), isTrue,
          reason: 'first consumer gets the stateRestoration origin tag');
      expect(service.consumeLaunchRestorationTag(), isFalse,
          reason: 'every later connect of this launch is untagged');
      // The cached event itself survives consumption — only the trace
      // tag is one-shot.
      expect(service.launchRestoration, isNotNull);
      await service.dispose();
    });

    test(
        'fault injection: a throwing channel fetch never throws out of '
        'initialize() (#2349 never-throws contract)', () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: true,
        debugSetOptionsOverride: () async {},
        debugLaunchCentralIdsFetcher: () async =>
            throw MissingPluginException('no host handler'),
      );
      await expectLater(service.initialize(), completes);
      expect(service.launchRestoration, isNull,
          reason: 'a failed fetch leaves the launch untagged — exactly '
              'the pre-#3167 behaviour');
      expect(service.consumeLaunchRestorationTag(), isFalse);
      await service.dispose();
    });

    test('non-iOS never queries the launch channel', () async {
      var fetched = false;
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
        debugLaunchCentralIdsFetcher: () async {
          fetched = true;
          return <String>['x'];
        },
      );
      await service.initialize();
      expect(fetched, isFalse,
          reason: 'Android resolves the platform gate before any '
              'restoration plumbing runs');
      expect(service.launchRestoration, isNull);
      expect(service.consumeLaunchRestorationTag(), isFalse);
      await service.dispose();
    });
  });

  group('FlutterBluePlusIosStateRestorationService — non-iOS branch', () {
    test('initialize() returns without throwing on non-iOS', () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
      );
      // Must complete without touching FlutterBluePlus (which would
      // throw MissingPluginException in the test environment).
      await expectLater(service.initialize(), completes);
      await service.dispose();
    });

    test('initialize() is idempotent — repeat calls are no-ops',
        () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
      );
      await service.initialize();
      // Drain the first emission so the second initialize wouldn't
      // double-emit if it ran twice.
      await expectLater(service.initialize(), completes);
      await expectLater(service.initialize(), completes);
      await service.dispose();
    });

    test(
        'registerPersistedAdapter() is a no-op on non-iOS (no FlutterBluePlus call)',
        () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
      );
      // If the no-op gate is broken this would throw
      // MissingPluginException because the test binding has no FBP.
      await expectLater(
        service.registerPersistedAdapter('fake-uuid'),
        completes,
      );
      await service.dispose();
    });

    test(
        'events stream emits IosRestorationNotSupported then quiets on non-iOS',
        () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
      );

      // Subscribe BEFORE initialize() so the broadcast controller
      // delivers the sentinel synchronously to this listener.
      final received = <IosRestorationEvent>[];
      final sub = service.events.listen(received.add);

      await service.initialize();
      // Pump the event queue so the controller delivers.
      await Future<void>.delayed(Duration.zero);

      expect(
        received,
        [const IosRestorationEvent.notSupported()],
        reason: 'non-iOS must publish exactly one notSupported sentinel '
            'so callers can switch exhaustively without a Platform check',
      );

      // After the sentinel, the stream stays quiet — no more events.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));

      await sub.cancel();
      await service.dispose();
    });

    test(
        'events stream stays usable across multiple subscribers '
        '(broadcast controller)', () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
      );

      final firstReceived = <IosRestorationEvent>[];
      final firstSub = service.events.listen(firstReceived.add);

      await service.initialize();
      await Future<void>.delayed(Duration.zero);

      // Late subscriber — broadcast controller does not replay, so
      // the second listener sees nothing for the already-emitted
      // sentinel. This is the documented contract; the consumer
      // (Phase 3) MUST subscribe before initialize().
      final secondReceived = <IosRestorationEvent>[];
      final secondSub = service.events.listen(secondReceived.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(firstReceived, hasLength(1),
          reason: 'first subscriber must receive the sentinel');
      expect(secondReceived, isEmpty,
          reason: 'broadcast controller does not replay — late '
              'subscribers see nothing for past events');

      await firstSub.cancel();
      await secondSub.cancel();
      await service.dispose();
    });

    test('dispose() closes the events stream', () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
      );
      // Subscribe to the broadcast stream and assert that the
      // subscription's onDone fires once dispose closes the
      // controller. We don't initialize() here — disposing without
      // ever publishing should still terminate the listener cleanly.
      final completer = Completer<void>();
      final sub = service.events.listen(
        (_) {},
        onDone: completer.complete,
      );

      await service.dispose();
      await completer.future.timeout(const Duration(seconds: 1));

      await sub.cancel();
    });

    test('dispose() is idempotent', () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
      );
      await service.dispose();
      await expectLater(service.dispose(), completes);
    });

    test('initialize() after dispose() is a no-op', () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
      );
      await service.dispose();
      await expectLater(service.initialize(), completes);
    });

    test('registerPersistedAdapter() after dispose() is a no-op',
        () async {
      final service = FlutterBluePlusIosStateRestorationService(
        debugIsIOSOverride: false,
      );
      await service.dispose();
      await expectLater(
        service.registerPersistedAdapter('any-uuid'),
        completes,
      );
    });
  });

  group('IosRestorationEvent — sealed class semantics', () {
    test('willRestore equals another willRestore with same UUIDs', () {
      const a = IosRestorationEvent.willRestore(['u1', 'u2']);
      const b = IosRestorationEvent.willRestore(['u1', 'u2']);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('willRestore differs by UUID list', () {
      const a = IosRestorationEvent.willRestore(['u1']);
      const b = IosRestorationEvent.willRestore(['u2']);
      expect(a, isNot(equals(b)));
    });

    test('notSupported is a singleton-equivalent', () {
      const a = IosRestorationEvent.notSupported();
      const b = IosRestorationEvent.notSupported();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('willRestore != notSupported', () {
      const a = IosRestorationEvent.willRestore([]);
      const b = IosRestorationEvent.notSupported();
      expect(a, isNot(equals(b)));
    });

    test('exhaustive switch compiles (sealed-class proof)', () {
      // If a new variant is added without updating this switch the
      // compiler yells. That's the point of the sealed class.
      const event = IosRestorationEvent.willRestore(['x']);
      final result = switch (event) {
        IosRestorationWillRestore(:final peripheralUuids) =>
          'will:${peripheralUuids.length}',
        IosRestorationNotSupported() => 'no',
      };
      expect(result, 'will:1');
    });

    test('toString surfaces UUIDs for debugging', () {
      const event = IosRestorationEvent.willRestore(['abc', 'def']);
      expect(event.toString(), contains('abc'));
      expect(event.toString(), contains('def'));
    });
  });
}
