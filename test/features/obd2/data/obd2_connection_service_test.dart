// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/negotiated_protocol_cache.dart';
import 'package:tankstellen/features/obd2/data/supported_pids_cache.dart';
import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();
  final registry = Obd2AdapterRegistry.defaults();

  group('Obd2ConnectionService.scan (#741)', () {
    test('throws Obd2PermissionDenied when the user refuses', () async {
      final svc = _build(
        permState: Obd2PermissionState.denied,
        bt: _FakeFacade(batches: const [[]]),
      );
      await expectLater(svc.scan().toList(), throwsA(isA<Obd2PermissionDenied>()));
    });

    test(
      'propagates Obd2BluetoothOff from the BLE facade verbatim — the '
      'service must not catch it as a scan timeout (#1369)',
      () async {
        // The facade emits a typed Obd2BluetoothOff once it has
        // identified that FlutterBluePlus rejected startScan with
        // "Bluetooth must be turned on". The connection service is a
        // pass-through; the picker / VIN reader catches the typed
        // error and renders the "Turn on Bluetooth" message.
        final svc = _build(
          permState: Obd2PermissionState.granted,
          bt: _FakeFacade(
            batches: const [],
            error: const Obd2BluetoothOff(),
          ),
        );
        await expectLater(
          svc.scan().toList(),
          throwsA(isA<Obd2BluetoothOff>()),
        );
      },
    );

    test('throws Obd2ScanTimeout when nothing rankable is seen (#741, #3103)',
        () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        // A NAMELESS beacon in range — not an adapter, and #3103 drops
        // nameless devices, so ranked batches stay empty and the window
        // times out as before.
        bt: _FakeFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'beacon',
              deviceName: '',
              advertisedServiceUuids: const [
                '0000180f-0000-1000-8000-00805f9b34fb', // battery service
              ],
              rssi: -55,
            ),
          ],
        ]),
      );
      await expectLater(svc.scan().toList(), throwsA(isA<Obd2ScanTimeout>()));
    });

    test(
        '#3103 — a NAMED but unrecognized device is SURFACED (not timed out) '
        'so the user can still try it', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'phone',
              deviceName: 'Pixel 9',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ]),
      );
      final emitted = await svc.scan().toList();
      expect(emitted, hasLength(1));
      expect(emitted.single.single.recognized, isFalse);
      expect(emitted.single.single.candidate.deviceName, 'Pixel 9');
    });

    test('emits ranked vLinker candidate + completes without throwing',
        () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FS',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ]),
      );
      final emitted = await svc.scan().toList();
      expect(emitted, hasLength(1));
      // #761 — "vLinker FS" resolves to the Classic profile, not BLE.
      expect(emitted.single.single.profile.id, 'vlinker-fs-classic');
    });

    test('accumulates across batches and preserves RSSI ranking', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'a',
              deviceName: 'vLinker FS',
              advertisedServiceUuids: const [],
              rssi: -80,
            ),
          ],
          [
            Obd2AdapterCandidate(
              deviceId: 'a',
              deviceName: 'vLinker FS',
              advertisedServiceUuids: const [],
              rssi: -80,
            ),
            Obd2AdapterCandidate(
              deviceId: 'b',
              deviceName: 'OBDLink MX+',
              advertisedServiceUuids: const [],
              rssi: -50,
            ),
          ],
        ]),
      );
      final emitted = await svc.scan().toList();
      expect(emitted.last.first.profile.id, 'obdlink-mx',
          reason: 'strongest RSSI must rank first');
    });

    test(
        'requests an UNFILTERED BLE scan (empty serviceUuids) so iOS sees '
        'name-only ELM327 adapters (#3097)', () async {
      // A service-UUID filter becomes startScan(withServices:), and on iOS
      // CoreBluetooth only returns peripherals that ADVERTISE one of those
      // UUIDs — but most ELM327 BLE clones advertise a NAME and no service,
      // so the filtered scan returned nothing on iPhone. The service must
      // request an empty (unfiltered) set; resolve()/rank still drop noise.
      final fake = _FakeFacade(batches: const [[]]);
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);
      // The empty batch yields no known adapter, so scan throws ScanTimeout;
      // we only care that the facade was driven with an empty filter.
      await expectLater(svc.scan().toList(), throwsA(isA<Obd2ScanTimeout>()));
      expect(fake.lastScanServiceUuids, isNotNull,
          reason: 'the BLE facade scan must have been invoked');
      expect(fake.lastScanServiceUuids, isEmpty,
          reason: 'the BLE scan must be UNFILTERED (#3097) — a non-empty '
              'withServices filter starves iOS of name-only adapters');
    });

    test(
        'a BLE-discovered generic "OBDII" resolves to a BLE profile, not '
        'Classic (#3097)', () async {
      // End-to-end through the real registry: a generic ELM327 advertising a
      // name and NO service over BLE must rank as a BLE profile so it connects
      // on iPhone (a Classic profile cannot — no MFi). Would FAIL on master:
      // pre-#3097 the only generic matchers lived on generic-classic.
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'ios-uuid-1',
              deviceName: 'OBDII',
              advertisedServiceUuids: const [],
              rssi: -50,
              discoveryTransport: BluetoothTransport.ble,
            ),
          ],
        ]),
      );
      final emitted = await svc.scan().toList();
      final resolved = emitted.single.single;
      expect(resolved.profile.id, 'generic-ble');
      expect(resolved.profile.transport, BluetoothTransport.ble,
          reason: 'a BLE-discovered generic ELM327 must resolve to a BLE '
              'profile so the BLE connect path runs on iPhone (#3097)');
    });
  });

  group('Obd2ConnectionService.connect (#741)', () {
    test('returns a ready Obd2Service on successful init', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          channel: _FakeChannel(respondTo: _elmOkResponses()),
        ),
      );
      final candidate = _resolvedVlinker(registry);
      final ready = await svc.connect(candidate);
      expect(ready.isConnected, isTrue);
      await ready.disconnect();
    });

    test('throws Obd2AdapterUnresponsive when the init sequence fails',
        () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          // Channel never emits — BluetoothObd2Transport's 5 s timeout
          // flips the service connect() to return false, which the
          // connection service translates to the typed error.
          channel: _FakeChannel(silent: true),
        ),
      );
      final candidate = _resolvedVlinker(registry);
      await expectLater(
        svc.connect(candidate),
        throwsA(isA<Obd2AdapterUnresponsive>()),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('Obd2ConnectionService dual-transport (#761)', () {
    test('connect dispatches to ClassicBluetoothFacade when the '
        'resolved profile is Classic', () async {
      // Covers the user's actual vLinker FS flow: scan sees a Classic
      // adapter via the classic facade; connect must route through
      // the same facade to build the RFCOMM-backed channel.
      final classicFake = _FakeClassicFacade(
        batches: const [[]],
        channel: _FakeChannel(respondTo: _elmOkResponses()),
      );
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.granted),
        bluetooth: _FakeFacade(batches: const [[]]),
        classicBluetooth: classicFake,
      );
      final candidate = ResolvedObd2Candidate(
        candidate: Obd2AdapterCandidate(
          deviceId: 'cc:dd',
          deviceName: 'vLinker FS 14884',
          advertisedServiceUuids: const [],
          rssi: 0,
        ),
        profile: registry.profiles
            .firstWhere((p) => p.id == 'vlinker-fs-classic'),
      );
      final ready = await svc.connect(candidate);
      expect(ready.isConnected, isTrue);
      expect(classicFake.channelForCalls, ['cc:dd']);
      await ready.disconnect();
    });

    test('connect throws Obd2AdapterUnresponsive on Classic profile '
        'when no Classic facade was wired', () async {
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.granted),
        bluetooth: _FakeFacade(batches: const [[]]),
        // classicBluetooth: null — misconfiguration safeguard.
      );
      final candidate = ResolvedObd2Candidate(
        candidate: Obd2AdapterCandidate(
          deviceId: 'cc:dd',
          deviceName: 'vLinker FS',
          advertisedServiceUuids: const [],
          rssi: 0,
        ),
        profile: registry.profiles
            .firstWhere((p) => p.id == 'vlinker-fs-classic'),
      );
      await expectLater(
        svc.connect(candidate),
        throwsA(isA<Obd2AdapterUnresponsive>()),
      );
    });

    test('scan merges Classic-only candidates alongside BLE', () async {
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.granted),
        bluetooth: _FakeFacade(batches: const [[]]),
        classicBluetooth: _FakeClassicFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'cc:dd',
              deviceName: 'vLinker FS 14884',
              advertisedServiceUuids: const [],
              rssi: 0,
            ),
          ],
        ]),
      );
      final emitted = await svc.scan().toList();
      expect(emitted, isNotEmpty);
      expect(emitted.last.single.profile.id, 'vlinker-fs-classic');
    });
  });

  group('Obd2ConnectionService.connectBest', () {
    test('returns null when no scan has happened yet', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(batches: const [[]]),
      );
      expect(await svc.connectBest(), isNull);
    });
  });

  group('Obd2ConnectionService.connectByMacDirect (#2242)', () {
    test('connects WITHOUT scanning on the happy path + runs init',
        () async {
      final directChannel = _FakeChannel(respondTo: _elmOkResponses());
      final fake = _FakeFacade(
        // Non-empty scan batches: if the direct path ever fell back to
        // scan, this would be observable via scanInvoked.
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        directChannel: directChannel,
      );
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: fake,
      );

      final ready = await svc.connectByMacDirect('aa:bb');

      expect(ready, isNotNull);
      expect(ready!.isConnected, isTrue);
      expect(fake.scanInvoked, isFalse,
          reason: 'direct connect must NOT scan on the happy path');
      expect(fake.directMac, 'aa:bb');
      expect(directChannel.openCalls, 1);
      await ready.disconnect();
    });

    test('Android → a 4 s cold direct-connect timeout (LOAD-BEARING, #2242)',
        () async {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final fake = _FakeFacade(
        batches: const [[]],
        directChannel: _FakeChannel(respondTo: _elmOkResponses()),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacDirect('aa:bb');
      expect(fake.directTimeout, const Duration(seconds: 4));
      await ready!.disconnect();
    });

    test('#3113 — iOS → a 7 s cold direct-connect timeout (a cold CoreBluetooth '
        'GATT connect to an ELM clone exceeds 4s)', () async {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final fake = _FakeFacade(
        batches: const [[]],
        directChannel: _FakeChannel(respondTo: _elmOkResponses()),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacDirect('aa:bb');
      expect(fake.directTimeout, const Duration(seconds: 7));
      await ready!.disconnect();
    });

    test('tears down a prior direct channel before reopening', () async {
      final first = _FakeChannel(respondTo: _elmOkResponses());
      final second = _FakeChannel(respondTo: _elmOkResponses());
      var call = 0;
      final fake = _SequencedDirectFacade(
        sequence: [first, second],
        onDirect: () => call++,
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready1 = await svc.connectByMacDirect('aa:bb');
      expect(first.closeCalls, 0, reason: 'first channel still open');

      final ready2 = await svc.connectByMacDirect('aa:bb');
      expect(first.closeCalls, greaterThanOrEqualTo(1),
          reason: 'prior channel must be torn down before the 2nd open');
      expect(second.openCalls, 1);

      await ready1?.disconnect();
      await ready2?.disconnect();
    });

    test('falls back to the scan path when the direct open times out',
        () async {
      // Direct channel.open() throws (simulates connect timeout / GATT
      // 133); the scan batch carries the same MAC so the fallback
      // connectByMac succeeds.
      final fake = _FakeFacade(
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        channel: _FakeChannel(respondTo: _elmOkResponses()),
        directChannel: _FakeChannel(
          openError: StateError('connect timed out'),
        ),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacDirect('aa:bb');

      expect(ready, isNotNull,
          reason: 'scan fallback must still produce a session');
      expect(fake.scanInvoked, isTrue,
          reason: 'failed direct connect must fall back to scan');
      await ready!.disconnect();
    });

    test('returns null when both direct AND scan fallback fail', () async {
      final fake = _FakeFacade(
        // Empty scan ⇒ connectByMac returns null on Obd2ScanTimeout.
        batches: const [[]],
        directChannel: _FakeChannel(
          openError: StateError('connect timed out'),
        ),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacDirect('aa:bb');
      expect(ready, isNull);
      expect(fake.scanInvoked, isTrue);
    });

    test(
        'with fallbackToScan:false a failed direct attempt returns null '
        'WITHOUT scanning (#2245)', () async {
      // The in-trip reconnect path owns its own RSSI-gated scan fallback,
      // so it opts out of the service's internal scan to avoid double
      // scanning. A failed direct connect must surface as a plain null.
      final fake = _FakeFacade(
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        directChannel: _FakeChannel(
          openError: StateError('connect timed out'),
        ),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready =
          await svc.connectByMacDirect('aa:bb', fallbackToScan: false);
      expect(ready, isNull);
      expect(fake.scanInvoked, isFalse,
          reason: 'fallbackToScan:false must skip the internal scan');
    });
  });

  // ── #2379 — recovered-attempt connect logs must not flood ───────────
  group('Obd2ConnectionService — connect-retry error-logging (#2379)', () {
    late _CaptureRecorder recorder;

    setUp(() {
      errorLogger.resetForTest();
      recorder = _CaptureRecorder();
      errorLogger.testRecorderOverride = recorder;
      BreadcrumbCollector.clear();
    });

    tearDown(() {
      // Restore the file-wide spool silencer that setUpAll installed.
      errorLogger.resetForTest();
      errorLogger.spoolEnqueueOverride = ({
        required String isolateTaskName,
        required Object error,
        StackTrace? stack,
        Map<String, dynamic>? contextMap,
        DateTime? timestamp,
      }) async {};
    });

    test(
        'a direct attempt RECOVERED by the scan fallback emits NO '
        '"falling back to scan" error trace (#2379)', () async {
      // Direct channel.open() throws (connect timeout / GATT 133); the
      // scan batch carries the same MAC so the fallback connectByMac
      // succeeds. The direct attempt's own channel never reaches the
      // ELM init, so the only thing this path used to log was the
      // (now-suppressed) "falling back to scan" trace.
      final fake = _FakeFacade(
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        channel: _FakeChannel(respondTo: _elmOkResponses()),
        directChannel: _FakeChannel(
          openError: StateError('connect timed out'),
        ),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacDirect('aa:bb');

      expect(ready, isNotNull, reason: 'scan fallback recovered the connect');
      expect(fake.scanInvoked, isTrue);
      // THE fix: the recovered first attempt is no longer an error trace.
      // (The channel.open() throw is swallowed by Obd2Service.connect's
      // transport.connect(), which on this code path logs nothing because
      // open() — not init — failed, then connectByMacDirect's catch is now
      // debug-only.) Net: a clean recovery with zero error traces.
      expect(recorder.calls, isEmpty,
          reason: 'a connect attempt recovered by the fallback flooded the '
              'user error log — it must now be silent');
      // Specifically: no "falling back to scan" trace survives.
      expect(
        recorder.calls
            .whereType<ContextualError>()
            .where((e) => e.toString().contains('falling back to scan')),
        isEmpty,
      );
      await ready!.disconnect();
    });

    test(
        'when BOTH direct AND scan fallback fail, connectByMacDirect emits '
        'no "falling back to scan" trace (#2379)', () async {
      // The recovered-attempt log is gone; the ultimate failure is owned
      // upstream (RecordingStartCoordinator + AutoRecord breadcrumbs).
      final fake = _FakeFacade(
        batches: const [[]], // empty scan ⇒ connectByMac returns null
        directChannel: _FakeChannel(
          openError: StateError('connect timed out'),
        ),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacDirect('aa:bb');
      expect(ready, isNull);
      expect(
        recorder.calls
            .whereType<ContextualError>()
            .where((e) => e.toString().contains('falling back to scan')),
        isEmpty,
        reason: 'connectByMacDirect no longer logs its recovered/retried '
            'attempt — the caller owns the final-failure trace',
      );
      // And nothing that does survive carries the storage layer.
      expect(
        recorder.calls
            .whereType<ContextualError>()
            .where((e) => e.layer == ErrorLayer.storage),
        isEmpty,
        reason: 'no OBD2/BLE error may carry the storage layer',
      );
    });

    // ── #2943 (error-log #28/29) — complete the #2935 connect de-noise ──
    //
    // connectBest's catch used to spool EVERY rethrown Obd2ConnectionError as
    // a full ERROR (5× expected Obd2AdapterUnresponsive in errorlog_28/29
    // from probing a parked, engine-off car). It now routes through the
    // #2745/#2763/#2892 de-noiser: the expected engine-off family + a bare
    // ELM327 connect TimeoutException record a breadcrumb, while GENUINE
    // faults still ERROR-log on `other`. The error is rethrown either way.

    test(
        'an EXPECTED engine-off Obd2AdapterUnresponsive at connectBest is a '
        'breadcrumb, NOT an ERROR (#2943) — and is still rethrown', () async {
      final fake = _FakeFacade(
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        // Silent channel ⇒ init never completes ⇒ Obd2AdapterUnresponsive,
        // i.e. the engine is simply off (isExpectedUserCondition == true).
        channel: _FakeChannel(silent: true),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      // Populate _lastRanked so connectBest has a candidate to try.
      await svc.scan(timeout: const Duration(milliseconds: 50)).toList();

      await expectLater(
          svc.connectBest(), throwsA(isA<Obd2AdapterUnresponsive>()),
          reason: 'the caller still sees the typed error — only the log level '
              'changed');
      await Future<void>.delayed(Duration.zero);

      expect(
        recorder.calls
            .whereType<ContextualError>()
            .where((e) => e.toString().contains('connectBest failed')),
        isEmpty,
        reason: 'an expected engine-off condition must NOT spool an ERROR '
            'trace at connectBest (the errorlog_28/29 ×5 flood)',
      );
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('OBD2 connect failed — expected transient'),
      );
    });

    test(
        'a bare ELM327 connect TimeoutException at connectBest is a breadcrumb, '
        'NOT an ERROR (#2943)', () async {
      final svc = _ThrowingConnectBest(
        directError: TimeoutException(
          'ELM327 did not respond',
          const Duration(milliseconds: 2500),
        ),
      );

      await svc.primeLastRanked();
      await expectLater(svc.connectBest(), throwsA(isA<TimeoutException>()));
      await Future<void>.delayed(Duration.zero);

      expect(
        recorder.calls
            .whereType<ContextualError>()
            .where((e) => e.toString().contains('connectBest failed')),
        isEmpty,
        reason: 'a bounded ELM327 connect timeout is an expected transient — '
            'no ERROR spool (the errorlog_28/29 timeouts)',
      );
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('OBD2 connect failed — expected transient'),
      );
    });

    test(
        'a GENUINE Obd2PermissionDenied at connectBest IS still logged — '
        'ErrorLayer.other, never storage (#2943)', () async {
      final svc = _ThrowingConnectBest(directError: const Obd2PermissionDenied());

      await svc.primeLastRanked();
      await expectLater(
          svc.connectBest(), throwsA(isA<Obd2PermissionDenied>()));
      await Future<void>.delayed(Duration.zero);

      final logged = recorder.calls.whereType<ContextualError>().toList();
      expect(logged, isNotEmpty,
          reason: 'a real, actionable fault must stay a visible ERROR trace');
      expect(logged.every((e) => e.layer == ErrorLayer.other), isTrue,
          reason: 'OBD2/BLE failures must not carry the storage layer');
      expect(logged.any((e) => e.toString().contains('connectBest failed')),
          isTrue);
      expect(logged.any((e) => e.toString().contains('Obd2PermissionDenied')),
          isTrue);
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });

    test(
        'a GENUINE Obd2ProtocolInitFailed at connectBest IS still logged '
        '(#2943)', () async {
      final svc =
          _ThrowingConnectBest(directError: const Obd2ProtocolInitFailed('?'));

      await svc.primeLastRanked();
      await expectLater(
          svc.connectBest(), throwsA(isA<Obd2ProtocolInitFailed>()));
      await Future<void>.delayed(Duration.zero);

      final logged = recorder.calls.whereType<ContextualError>().toList();
      expect(logged.any((e) => e.toString().contains('connectBest failed')),
          isTrue,
          reason: 'a counterfeit-clone init failure is a genuine fault worth '
              'keeping as an ERROR');
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });
  });

  group('Obd2ConnectionService.connectByMacClassicDirect (#2565)', () {
    test(
        'builds a ClassicElmChannel via the classic facade + runs init with '
        "linkKind=='classic'; NEVER touches the BLE facade", () async {
      // The transport-correct in-trip reconnect for a Classic adapter
      // (vLinker FS): RFCOMM via the classic facade, no BLE GATT 4 s timeout.
      final classicChannel = _FakeChannel(respondTo: _elmOkResponses());
      final classicFake = _FakeClassicFacade(
        batches: const [[]],
        channel: classicChannel,
      );
      final ble = _FakeFacade(
        // Non-empty batch + a direct channel: if the classic path ever fell
        // through to BLE scan / direct, it would be observable here.
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'cc:dd',
              deviceName: 'vLinker FS 14884',
              advertisedServiceUuids: const [],
              rssi: 0,
            ),
          ],
        ],
        directChannel: _FakeChannel(respondTo: _elmOkResponses()),
      );
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.granted),
        bluetooth: ble,
        classicBluetooth: classicFake,
      );

      final ready = await svc.connectByMacClassicDirect('cc:dd');

      expect(ready, isNotNull);
      expect(ready!.isConnected, isTrue);
      expect(ready.linkKind, 'classic',
          reason: 'a classic-direct reconnect stamps the classic link kind');
      expect(classicFake.channelForCalls, ['cc:dd'],
          reason: 'the channel must be built via the CLASSIC facade (RFCOMM)');
      expect(classicChannel.openCalls, 1);
      // The defect this fixes: a Classic reconnect must NEVER take the BLE
      // direct path (the 4 s `Timed out after 4s` storm signature).
      expect(ble.directCalls, 0,
          reason: 'classic-direct must NOT call the BLE channelForDirect');
      expect(ble.scanInvoked, isFalse,
          reason: 'classic-direct does not scan — the caller owns the scan');
      await ready.disconnect();
    });

    test('returns null (no throw) when no classic facade is wired', () async {
      // BLE-only configs / unit harnesses: the caller falls through to its
      // own transport-aware scan fallback.
      final ble = _FakeFacade(
        batches: const [[]],
        directChannel: _FakeChannel(respondTo: _elmOkResponses()),
      );
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.granted),
        bluetooth: ble,
        // classicBluetooth: null
      );

      final ready = await svc.connectByMacClassicDirect('cc:dd');
      expect(ready, isNull);
      expect(ble.directCalls, 0,
          reason: 'a missing classic facade must NOT fall back to BLE direct');
      expect(ble.scanInvoked, isFalse);
    });

    test('returns null when the classic init fails — never touches BLE',
        () async {
      // Silent channel ⇒ the transport init times out ⇒ the recoverable
      // attempt returns null (the scanner re-arms), never a BLE fallback.
      final ble = _FakeFacade(
        batches: const [[]],
        directChannel: _FakeChannel(respondTo: _elmOkResponses()),
      );
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.granted),
        bluetooth: ble,
        classicBluetooth: _FakeClassicFacade(
          batches: const [[]],
          channel: _FakeChannel(silent: true),
        ),
      );

      final ready = await svc.connectByMacClassicDirect('cc:dd');
      expect(ready, isNull);
      expect(ble.directCalls, 0);
      expect(ble.scanInvoked, isFalse);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('Obd2ConnectionService.connectByMacPassive (#2261 concern 2)', () {
    test(
        'opens an autoConnect channel, NO scan, NO bounded timeout, '
        'runs init', () async {
      final passiveChannel = _FakeChannel(respondTo: _elmOkResponses());
      final fake = _FakeFacade(
        // A non-empty batch would be observable via scanInvoked if the
        // passive path ever scanned — it must not.
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        directChannel: passiveChannel,
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacPassive('aa:bb');

      expect(ready, isNotNull);
      expect(ready!.isConnected, isTrue);
      expect(fake.directAutoConnect, isTrue,
          reason: 'passive reconnect must request an autoConnect channel');
      expect(fake.scanInvoked, isFalse,
          reason: 'the passive wait must never scan — a passive GATT wait '
              'IS the fallback');
      await ready.disconnect();
    });

    test('returns null on failure WITHOUT a scan fallback', () async {
      final fake = _FakeFacade(
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        directChannel: _FakeChannel(openError: StateError('passive wait off')),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacPassive('aa:bb');
      expect(ready, isNull);
      expect(fake.scanInvoked, isFalse,
          reason: 'a failed passive wait does not scan — the scanner will '
              're-arm another passive wait itself');
    });
  });

  group('Obd2ConnectionService supported-PID cache wiring — #2253', () {
    late Directory tmpDir;
    late Box<String> box;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('conn_svc_pidcache_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>(
        'test_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    // The resolved candidate's MAC is 'aa:bb' + a Peugeot 107 active
    // vehicle ⇒ this is the production key the service should key on.
    final prodKey = SupportedPidsCache.productionKey(
      adapterMac: 'aa:bb',
      make: 'Peugeot',
      model: '107',
      year: 2008,
    )!;

    test(
        'cold connect scans + persists the bitmap under the adapterMac+'
        'make:model:year production key', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          channel: _FakeChannel(respondTo: {
            ..._elmOkResponses(),
            // PIDs 1, 0x0B, 0x0C, 0x0F; continuation bit (PID 32) clear.
            '0100': '41 00 80 32 00 00>',
          }),
        ),
        supportedPidsCache: SupportedPidsCache(box),
        activeVehicleKeyFields: () =>
            (make: 'Peugeot', model: '107', year: 2008, vin: null),
      );

      final ready = await svc.connect(_resolvedVlinker(registry));
      // The scan populated the strict bitmap (#3532: isPidKnownSupported
      // is the bitmap view; isPidSupported is optimistic and no longer
      // rejects bitmap-absent PIDs up-front).
      expect(ready.isPidKnownSupported(0x0B), isTrue);
      expect(ready.isPidKnownSupported(0x5E), isFalse);
      expect(ready.isPidSupported(0x0B), isTrue);
      expect(ready.isPidSupported(0x5E), isTrue,
          reason: '#3532 optimistic — only runtime probation parks a PID');
      // Persisted under the production key for the next session.
      expect(SupportedPidsCache(box).get(prodKey),
          containsAll([0x01, 0x0B, 0x0C, 0x0F]));
      await ready.disconnect();
    });

    test(
        'warm connect with a pre-seeded production key skips the support '
        'scan AND the 0902 VIN read', () async {
      await SupportedPidsCache(box).put(prodKey, {0x0B, 0x0C, 0x0F});

      // Channel answers ONLY the AT init — neither 0100 nor 0902 wired,
      // so any attempt would surface as the channel's default 'OK>'
      // (a non-bitmap, non-VIN response). We assert the resolver loads
      // the cached set without needing either.
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          channel: _FakeChannel(respondTo: _elmOkResponses()),
        ),
        supportedPidsCache: SupportedPidsCache(box),
        activeVehicleKeyFields: () =>
            (make: 'Peugeot', model: '107', year: 2008, vin: null),
      );

      final ready = await svc.connect(_resolvedVlinker(registry));
      // Cached bitmap populated the in-memory set without a scan/VIN read
      // — visible through the strict bitmap accessor (#3532); the
      // optimistic isPidSupported never rejects on bitmap absence.
      expect(ready.isPidKnownSupported(0x0B), isTrue,
          reason: 'the cached set must resolve the bitmap without a scan');
      expect(ready.isPidKnownSupported(0x5E), isFalse);
      expect(ready.isPidSupported(0x5E), isTrue,
          reason: '#3532 optimistic — only runtime probation parks a PID');
      await ready.disconnect();
    });

    test(
        'no cache wired → behaves exactly as before (transport-only), never '
        'rejects a PID', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          channel: _FakeChannel(respondTo: _elmOkResponses()),
        ),
        // supportedPidsCache / activeVehicleKeyFields intentionally null.
      );

      final ready = await svc.connect(_resolvedVlinker(registry));
      expect(ready.isPidSupported(0x5E), isTrue);
      expect(box.length, 0);
      await ready.disconnect();
    });
  });

  // #3009 — engine-off / ECU-silent classification. The channel + ELM init
  // SUCCEED (every AT answers), but the vehicle bus is silent: `0100` returns
  // the ECU-silent signature so PID discovery finds zero PIDs and the protocol
  // cache stays empty. The connect-trace outcome must be `ignitionOff` — NOT a
  // misleading green `success` — even though the adapter itself is fine.
  group('engine-off connect-trace classification (#3009)', () {
    late Directory tmpDir;
    late Box<String> box;

    setUp(() async {
      Obd2ConnectTraceLog.clear();
      Obd2CommDiagnostics.instance.reset();
      tmpDir = Directory.systemTemp.createTempSync('conn_svc_engineoff_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>(
        'engineoff_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      Obd2ConnectTraceLog.clear();
      Obd2CommDiagnostics.instance.reset();
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    Future<Obd2ConnectOutcome?> connectWith0100Reply(String reply) async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          directChannel: _FakeChannel(respondTo: {
            ..._elmOkResponses(),
            // The ECU never answers the protocol probe — the engine is off.
            '0100': reply,
          }),
        ),
        supportedPidsCache: SupportedPidsCache(box),
        activeVehicleKeyFields: () =>
            (make: 'Peugeot', model: '107', year: 2008, vin: null),
      );

      final ready = await svc.connectByMacDirect('aa:bb');
      // The adapter+init succeeded → a live service still comes back.
      expect(ready, isNotNull);
      expect(ready!.isConnected, isTrue);
      // But the bus never answered → this is engine-off, not a real connect.
      expect(ready.busAnswered, isFalse);
      await ready.disconnect();
      return Obd2ConnectTraceLog.snapshot().first.outcome;
    }

    test('init OK + 0100 → SEARCHING...STOPPED classifies as ignitionOff, '
        'NOT success', () async {
      final outcome = await connectWith0100Reply('SEARCHING...STOPPED>');
      // RED on master: the trace is stamped `success` because init succeeded.
      expect(outcome, Obd2ConnectOutcome.ignitionOff);
      expect(outcome, isNot(Obd2ConnectOutcome.success));
    });

    test('init OK + 0100 → NO DATA classifies as ignitionOff, NOT success',
        () async {
      final outcome = await connectWith0100Reply('NO DATA>');
      expect(outcome, Obd2ConnectOutcome.ignitionOff);
      expect(outcome, isNot(Obd2ConnectOutcome.success));
    });
  });
}

// --- helpers ---------------------------------------------------------

/// Captures every `errorLogger.log` routed through the foreground
/// recorder seam without a Hive / Riverpod stack (#2379).
class _CaptureRecorder implements TraceRecorder {
  final calls = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// #2943 — drives the `connectBest` catch in isolation. A real `scan()` seeds
/// the private `_lastRanked` with one vLinker candidate (so `connectBest` has
/// something to try), then the overridden `connect()` throws the injected
/// error — exercising precisely the `connectBest failed` catch's routing
/// without depending on the channel/init internals. Mirrors the
/// `_ThrowingConnection` seam in `obd2_connect_transient_denoise_test.dart`.
class _ThrowingConnectBest extends Obd2ConnectionService {
  _ThrowingConnectBest({required this.directError})
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _FakePermissions(Obd2PermissionState.granted),
          bluetooth: _FakeFacade(
            batches: [
              [
                Obd2AdapterCandidate(
                  deviceId: 'aa:bb',
                  deviceName: 'vLinker FD',
                  advertisedServiceUuids: const [],
                  rssi: -55,
                ),
              ],
            ],
          ),
        );

  final Object directError;

  /// Runs the real scan once so `_lastRanked` is non-empty.
  Future<void> primeLastRanked() async {
    await scan(timeout: const Duration(milliseconds: 50)).toList();
  }

  @override
  Future<Obd2Service> connect(ResolvedObd2Candidate candidate) async {
    throw directError;
  }
}

Obd2ConnectionService _build({
  required Obd2PermissionState permState,
  required BluetoothFacade bt,
  SupportedPidsCache? supportedPidsCache,
  NegotiatedProtocolCache? negotiatedProtocolCache,
  Obd2VehicleKeyFields Function()? activeVehicleKeyFields,
}) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _FakePermissions(permState),
      bluetooth: bt,
      supportedPidsCache: supportedPidsCache,
      negotiatedProtocolCache: negotiatedProtocolCache,
      activeVehicleKeyFields: activeVehicleKeyFields,
    );

ResolvedObd2Candidate _resolvedVlinker(Obd2AdapterRegistry r) {
  // Use the FD (BLE) variant — FS is Classic (#761), and the BLE
  // dispatch is what the unit tests below are validating.
  final candidate = Obd2AdapterCandidate(
    deviceId: 'aa:bb',
    deviceName: 'vLinker FD',
    advertisedServiceUuids: const [],
    rssi: -55,
  );
  return ResolvedObd2Candidate(
    candidate: candidate,
    profile: r.profiles.firstWhere((p) => p.id == 'vlinker-ble'),
  );
}

class _FakePermissions implements Obd2Permissions {
  final Obd2PermissionState state;
  _FakePermissions(this.state);
  @override
  Future<Obd2PermissionState> current() async => state;
  @override
  Future<Obd2PermissionState> request() async => state;
  @override
  Future<bool> requestNotifications() async => true;
}

class _FakeClassicFacade implements ClassicBluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  final ElmByteChannel? channel;
  final List<String> channelForCalls = [];
  _FakeClassicFacade({required this.batches, this.channel});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    for (final batch in batches) {
      yield batch;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool?> isBonded(String mac) async => null; // #3423 — unknown

  @override
  ElmByteChannel channelFor(String deviceId) {
    channelForCalls.add(deviceId);
    return channel ?? _FakeChannel(silent: true);
  }
}

class _FakeFacade implements BluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  final ElmByteChannel? channel;
  final Object? error;

  /// Channel handed back by [channelForDirect] (#2242). When null the
  /// direct path reuses [channel] / a silent fallback.
  final ElmByteChannel? directChannel;

  /// Set true the first time [scan] is iterated — lets the direct-connect
  /// happy-path test assert NO scan occurred.
  bool scanInvoked = false;

  /// #3097 — captures the `serviceUuids` the connection service requested on
  /// the most recent [scan] call, so a test can assert the scan is UNFILTERED
  /// (empty set). A non-empty filter starved iOS of name-only ELM327 adapters.
  Set<String>? lastScanServiceUuids;

  /// Args captured from the most recent [channelForDirect] call.
  String? directMac;
  Duration? directTimeout;
  bool directAutoConnect = false;
  int directCalls = 0;

  _FakeFacade({
    required this.batches,
    this.channel,
    this.error,
    this.directChannel,
  });

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    scanInvoked = true;
    lastScanServiceUuids = serviceUuids;
    for (final batch in batches) {
      yield batch;
    }
    final err = error;
    if (err != null) {
      throw err;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(
    String deviceId,
    Obd2AdapterProfile profile,
  ) =>
      channel ?? _FakeChannel(silent: true);

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    directCalls++;
    directMac = mac;
    directTimeout = connectTimeout;
    directAutoConnect = autoConnect;
    return directChannel ?? channel ?? _FakeChannel(silent: true);
  }
}

/// Hands back a different direct channel per call so the teardown test
/// can assert the FIRST channel is closed before the SECOND opens.
class _SequencedDirectFacade implements BluetoothFacade {
  final List<ElmByteChannel> sequence;
  final void Function() onDirect;
  int _i = 0;
  _SequencedDirectFacade({required this.sequence, required this.onDirect});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(
    String deviceId,
    Obd2AdapterProfile profile,
  ) =>
      _FakeChannel(silent: true);

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    onDirect();
    return sequence[_i++];
  }
}

/// Minimal channel that answers every write with the canonical ELM327
/// OK prompt so the transport's init sequence completes. Silent mode
/// never emits — useful for the unresponsive-adapter test.
class _FakeChannel implements ElmByteChannel {
  final bool silent;
  final Map<String, String>? respondTo;

  /// When set, [open] throws this — simulates a direct-connect timeout /
  /// GATT_ERROR 133 so the service falls back to the scan path (#2242).
  final Object? openError;
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;
  int openCalls = 0;
  int closeCalls = 0;

  _FakeChannel({this.silent = false, this.respondTo, this.openError});

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _ctrl.stream;

  @override
  Future<void> open() async {
    openCalls++;
    final err = openError;
    if (err != null) throw err;
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (silent) return;
    final cmd = String.fromCharCodes(bytes).trim();
    final reply = respondTo?[cmd] ?? 'OK>';
    _ctrl.add(reply.codeUnits);
  }

  @override
  Future<void> close() async {
    closeCalls++;
    _open = false;
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}

/// Canned init-sequence responses covering what `Elm327Protocol.initCommands`
/// sends: ATZ, ATE0, ATL0, ATH0, ATSP0.
Map<String, String> _elmOkResponses() => {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
    };
