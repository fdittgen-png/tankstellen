// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_classifier.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';

void main() {
  setUp(Obd2ConnectTraceLog.clear);
  tearDown(Obd2ConnectTraceLog.clear);

  group('classifyObd2ConnectError (#2969 correction 2)', () {
    test('maps the full sealed connect-error set + TimeoutException', () {
      expect(classifyObd2ConnectError(const Obd2PermissionDenied()),
          Obd2ConnectOutcome.permissionDenied);
      expect(classifyObd2ConnectError(const Obd2BluetoothOff()),
          Obd2ConnectOutcome.bluetoothOff);
      expect(classifyObd2ConnectError(const Obd2ScanTimeout()),
          Obd2ConnectOutcome.scanEmpty);
      expect(classifyObd2ConnectError(const Obd2ProtocolInitFailed('garbage')),
          Obd2ConnectOutcome.protocolInitFailed);
      // A bare adapter-unresponsive (no Classic/RFCOMM marker) is the #1 real
      // field condition: a parked car / ignition off.
      expect(classifyObd2ConnectError(const Obd2AdapterUnresponsive()),
          Obd2ConnectOutcome.ignitionOff);
      // A Classic rfcomm-open failure carries the marker → rfcommOpenFail.
      expect(
        classifyObd2ConnectError(const Obd2AdapterUnresponsive(
            'Classic BT transport requested but no Classic facade is wired')),
        Obd2ConnectOutcome.rfcommOpenFail,
      );
      expect(classifyObd2ConnectError(TimeoutException('init')),
          Obd2ConnectOutcome.initTimeout);
      expect(classifyObd2ConnectError(StateError('weird')),
          Obd2ConnectOutcome.unknown);
    });
  });

  group('classifyBleOpenOutcome (#2969 correction 3)', () {
    test('separates 133 / timeout / service-not-found', () {
      expect(classifyBleOpenOutcome(StateError('GATT_ERROR 133')),
          Obd2ConnectOutcome.gatt133);
      expect(
        classifyBleOpenOutcome(TimeoutException('Timed out after 4s')),
        Obd2ConnectOutcome.gattTimeout,
      );
      expect(
        classifyBleOpenOutcome(
            StateError('BLE device has no ELM327 service 0000fff0')),
        Obd2ConnectOutcome.serviceNotFound,
      );
    });
  });

  group('Obd2ConnectTraceHandle.setOutcome (FIRST-TERMINAL-WINS #2969 c.3)',
      () {
    test('a second setOutcome does NOT overwrite the primary outcome', () {
      final h = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:FF',
        requestedTransport: Obd2ConnectTransport.ble,
      );
      // The real wrong-transport timeout lands first.
      h.setOutcome(Obd2ConnectOutcome.gattTimeout, failureDetail: 'timed out');
      // The swallowed-fallback's scanEmpty would overwrite it without
      // first-wins — it must NOT.
      h.setOutcome(Obd2ConnectOutcome.scanEmpty);
      Obd2ConnectTraceLog.endTrace(h);

      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.outcome, Obd2ConnectOutcome.gattTimeout);
      expect(trace.failureDetail, 'timed out');
    });

    test('#3243 a later SUCCESS upgrades a prior retried transient '
        '(fail-once-then-succeed exports success)', () {
      final h = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:FF',
        requestedTransport: Obd2ConnectTransport.ble,
      );
      // Attempt 1 hits a channel-open transient the #3179 loop retries.
      h.setOutcome(Obd2ConnectOutcome.gattTimeout, failureDetail: 'timed out');
      // Attempt 2 connects — the trace must export success, not the transient.
      h.setOutcome(Obd2ConnectOutcome.success);
      Obd2ConnectTraceLog.endTrace(h);

      expect(Obd2ConnectTraceLog.snapshot().single.outcome,
          Obd2ConnectOutcome.success);
    });

    test('#3243 a later pairingRequired upgrades a prior retried transient '
        '(the bond-window signal is not masked)', () {
      final h = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:FF',
        requestedTransport: Obd2ConnectTransport.ble,
      );
      h.setOutcome(Obd2ConnectOutcome.gatt133, failureDetail: '133');
      h.setOutcome(Obd2ConnectOutcome.pairingRequired);
      Obd2ConnectTraceLog.endTrace(h);

      expect(Obd2ConnectTraceLog.snapshot().single.outcome,
          Obd2ConnectOutcome.pairingRequired);
    });

    test('#3243 pairingRequired does NOT supersede a non-retried terminal '
        '(scanEmpty first-wins preserved)', () {
      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect);
      h.setOutcome(Obd2ConnectOutcome.scanEmpty);
      h.setOutcome(Obd2ConnectOutcome.pairingRequired);
      Obd2ConnectTraceLog.endTrace(h);

      expect(Obd2ConnectTraceLog.snapshot().single.outcome,
          Obd2ConnectOutcome.scanEmpty);
    });

    test('#3243 a real success is never overwritten by a later failure', () {
      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect);
      h.setOutcome(Obd2ConnectOutcome.success);
      h.setOutcome(Obd2ConnectOutcome.gattTimeout);
      Obd2ConnectTraceLog.endTrace(h);

      expect(Obd2ConnectTraceLog.snapshot().single.outcome,
          Obd2ConnectOutcome.success);
    });

    test('setOutcomeFromError classifies + keeps the raw toString detail', () {
      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.liveReconnect);
      h.setOutcomeFromError(const Obd2BluetoothOff());
      Obd2ConnectTraceLog.endTrace(h);

      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.outcome, Obd2ConnectOutcome.bluetoothOff);
      expect(trace.failureDetail, contains('Obd2BluetoothOff'));
    });
  });

  group('Obd2ConnectTraceLog ring + redaction', () {
    test('redacts the requested MAC + records steps/scan, finalises to ring',
        () {
      final h = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.selfTest,
        mac: 'AA:BB:CC:DD:EE:FF',
        requestedTransport: Obd2ConnectTransport.classic,
      );
      h
        ..setResolvedTransport(Obd2ConnectTransport.classic)
        ..setTransportDecisionReason('name-matched-classic')
        ..recordScan(
          mac: 'AA:BB:CC:DD:EE:FF',
          name: 'vLinker FS',
          rssi: -60,
          transport: Obd2ConnectTransport.classic,
          matchedProfileId: 'vlinker-fs-classic',
        )
        ..addStep(label: 'ATZ', status: Obd2ConnectStepStatus.ok, latencyMs: 90)
        ..setOutcome(Obd2ConnectOutcome.success);
      Obd2ConnectTraceLog.endTrace(h);

      final trace = Obd2ConnectTraceLog.snapshot().single;
      // MAC is redacted (last 4 visible).
      expect(trace.requestedMac, endsWith('E:FF'));
      expect(trace.requestedMac, isNot(contains('AA:BB')));
      expect(trace.scanned.single.redactedMac, endsWith('E:FF'));
      expect(trace.scanned.single.matchedProfileId, 'vlinker-fs-classic');
      expect(trace.resolvedTransport, Obd2ConnectTransport.classic);
      expect(trace.transportDecisionReason, 'name-matched-classic');
      expect(trace.steps.single.label, 'ATZ');
      expect(trace.outcome, Obd2ConnectOutcome.success);
      // toJson round-trips (it is the download payload).
      final json = trace.toJson();
      expect(Obd2ConnectTrace.fromJson(json), trace);
    });

    test('ring is capped at maxTraces, newest-first', () {
      for (var i = 0; i < Obd2ConnectTraceLog.maxTraces + 3; i++) {
        final h = Obd2ConnectTraceLog.beginTrace(
            origin: Obd2ConnectOrigin.firstConnect, mac: 'm$i');
        h.setOutcome(Obd2ConnectOutcome.scanEmpty);
        Obd2ConnectTraceLog.endTrace(h);
      }
      final snap = Obd2ConnectTraceLog.snapshot();
      expect(snap, hasLength(Obd2ConnectTraceLog.maxTraces));
      // Newest-first: the last-begun trace is at the front.
      expect(snap.first.requestedMac, 'm12'); // maxTraces(10)+3-1 = 12
    });

    test('a nested beginTrace records into ONE trace (child handle)', () {
      final parent = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      // A fallback re-enters a public connect method → child handle.
      final child = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      child.addStep(label: 'scan', status: Obd2ConnectStepStatus.ok);
      // Ending the child is a no-op; the parent owns the lifecycle.
      Obd2ConnectTraceLog.endTrace(child);
      expect(Obd2ConnectTraceLog.snapshot(), isEmpty);
      parent.setOutcome(Obd2ConnectOutcome.scanEmpty);
      Obd2ConnectTraceLog.endTrace(parent);

      final trace = Obd2ConnectTraceLog.snapshot().single;
      // The child's step landed in the ONE parent trace.
      expect(trace.steps.map((s) => s.label), contains('scan'));
    });
  });

  group('teeHandshakeLine (#2969 correction 4)', () {
    test('AT lines tee into the active trace as steps, even with no collector',
        () {
      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.selfTest, mac: 'AA:BB');
      // A NO DATA reply tees as a fail step (the ECU said nothing).
      Obd2ConnectTraceLog.teeHandshakeLine('0100', 'NO DATA', 120);
      Obd2ConnectTraceLog.teeHandshakeLine('ATZ', 'ELM327 v1.5', 95);
      h.setOutcome(Obd2ConnectOutcome.ignitionOff);
      Obd2ConnectTraceLog.endTrace(h);

      final trace = Obd2ConnectTraceLog.snapshot().single;
      final byLabel = {for (final s in trace.steps) s.label: s};
      expect(byLabel['0100']?.status, Obd2ConnectStepStatus.fail);
      expect(byLabel['ATZ']?.status, Obd2ConnectStepStatus.ok);
    });

    test('teeHandshakeLine is a no-op when no trace is active', () {
      Obd2ConnectTraceLog.teeHandshakeLine('ATZ', 'ELM327 v1.5', 95);
      expect(Obd2ConnectTraceLog.snapshot(), isEmpty);
    });
  });

  group('endTrace never-throws contract (#2349 / #2969)', () {
    tearDown(() => Obd2ConnectTraceLog.onTraceAdded = null);

    test('endTrace returns normally even when the onTraceAdded listener throws',
        () {
      // Fault injection: a throwing notify listener (the dev health screen's
      // revision provider). endTrace is called from connect `finally` blocks on
      // the critical path, so it MUST swallow this and return normally.
      Obd2ConnectTraceLog.onTraceAdded = () => throw StateError('boom');
      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      h.setOutcome(Obd2ConnectOutcome.scanEmpty);

      expect(() => Obd2ConnectTraceLog.endTrace(h), returnsNormally);
      // The trace still landed in the ring despite the throwing listener.
      expect(Obd2ConnectTraceLog.snapshot(), hasLength(1));
    });
  });

  group('classifyInitFailureOutcome (#2969 correction 4)', () {
    test('an AT TIMEOUT in the transcript → initTimeout, partial steps kept',
        () {
      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.selfTest, mac: 'AA:BB');
      // The init got partway then a later AT timed out (the partial transcript).
      Obd2ConnectTraceLog.teeHandshakeLine('ATZ', 'ELM327 v1.5', 95);
      Obd2ConnectTraceLog.teeHandshakeLine('ATE0', 'OK', 30);
      Obd2ConnectTraceLog.teeHandshakeLine('ATSP0', 'TIMEOUT', 6000);
      expect(h.classifyInitFailureOutcome(), Obd2ConnectOutcome.initTimeout);
      h.setOutcome(h.classifyInitFailureOutcome());
      Obd2ConnectTraceLog.endTrace(h);

      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.outcome, Obd2ConnectOutcome.initTimeout);
      // The PARTIAL AT transcript is preserved in the steps.
      expect(trace.steps.map((s) => s.label),
          containsAll(<String>['ATZ', 'ATE0', 'ATSP0']));
    });

    test('ATZ garbage (a lying clone) → protocolInitFailed', () {
      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      // ATZ returned an unrecognised string (a counterfeit clone) → fail step.
      Obd2ConnectTraceLog.teeHandshakeLine('ATZ', '?garbage?', 120);
      expect(
          h.classifyInitFailureOutcome(), Obd2ConnectOutcome.protocolInitFailed);
      Obd2ConnectTraceLog.endTrace(h);
    });

    test('a clean init that ran but no PID answered → ignitionOff (parked car)',
        () {
      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      Obd2ConnectTraceLog.teeHandshakeLine('ATZ', 'ELM327 v1.5', 95);
      Obd2ConnectTraceLog.teeHandshakeLine('ATE0', 'OK', 30);
      // No timeout, no ATZ garbage → the bus was simply silent.
      expect(h.classifyInitFailureOutcome(), Obd2ConnectOutcome.ignitionOff);
      Obd2ConnectTraceLog.endTrace(h);
    });
  });

  group('adapterStateProbe — step 0 of every root trace (#3184)', () {
    test('a registered probe stamps adapter-state as the FIRST step', () {
      Obd2ConnectTraceLog.adapterStateProbe = () => 'off';

      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      Obd2ConnectTraceLog.endTrace(h);

      final step = Obd2ConnectTraceLog.snapshot().single.steps.first;
      expect(step.label, 'adapter-state');
      expect(step.detail, 'off',
          reason: 'the radio state at connect-begin is the single most '
              'common "why did nothing happen" answer');
    });

    test('a THROWING probe never derails the connect (#1103 fault seam)',
        () {
      Obd2ConnectTraceLog.adapterStateProbe =
          () => throw StateError('platform channel dead');

      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      h.setOutcome(Obd2ConnectOutcome.success);
      Obd2ConnectTraceLog.endTrace(h);

      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.outcome, Obd2ConnectOutcome.success);
      expect(trace.steps.map((s) => s.label),
          isNot(contains('adapter-state')));
    });

    test('no probe registered → no synthetic step (pre-#3184 shape)', () {
      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      Obd2ConnectTraceLog.endTrace(h);
      expect(Obd2ConnectTraceLog.snapshot().single.steps, isEmpty);
    });
  });

  group('onTracePersist hook (#3184)', () {
    test('endTrace hands the FINALISED trace to the persist hook', () {
      Obd2ConnectTrace? persisted;
      Obd2ConnectTraceLog.onTracePersist = (t) => persisted = t;

      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB:CC:DD:EE:F1');
      h.setOutcome(Obd2ConnectOutcome.gattTimeout);
      Obd2ConnectTraceLog.endTrace(h);

      expect(persisted, isNotNull);
      expect(persisted!.outcome, Obd2ConnectOutcome.gattTimeout);
      expect(persisted!.endedAtMs, isNotNull,
          reason: 'the hook must see the finalised snapshot');
    });

    test('a THROWING persist hook never derails endTrace (#1103 fault seam)',
        () {
      Obd2ConnectTraceLog.onTracePersist =
          (_) => throw StateError('hive is sick');

      final h = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      h.setOutcome(Obd2ConnectOutcome.success);
      expect(() => Obd2ConnectTraceLog.endTrace(h), returnsNormally);
      // The ring still received the trace.
      expect(Obd2ConnectTraceLog.snapshot(), hasLength(1));
    });

    test('a CHILD endTrace does not fire the hook (parent owns lifecycle)',
        () {
      var calls = 0;
      Obd2ConnectTraceLog.onTracePersist = (_) => calls++;

      final root = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:BB');
      final child = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.pickerScan);
      Obd2ConnectTraceLog.endTrace(child);
      expect(calls, 0, reason: 'child end is a lifecycle no-op');
      Obd2ConnectTraceLog.endTrace(root);
      expect(calls, 1);
    });
  });
}
