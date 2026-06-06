// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connect_trace.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';

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
}
