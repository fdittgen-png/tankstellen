// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connect_trace.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connect_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'supported_pids_probe.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'supported_pids_resolver.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #3035/#3037 — the CORE OBD2 bug: the adapter connects (AT handshake OK) but
/// the app never reads live PIDs even with the ignition ON, and instead
/// falsely classifies engine-off + loops reconnects.
///
/// ROOT CAUSE (ELM327 datasheet + python-OBD): the AT commands are answered
/// by the adapter's own MCU and NEVER touch the car. The ECU is only
/// contacted by the FIRST OBD request, `0100`, which triggers the ELM327
/// protocol search — the adapter replies `SEARCHING...` and the real
/// `41 00 <bitmap>` (or `UNABLE TO CONNECT`) can take several seconds / arrive
/// on a LATER read.
///
/// #3036 first made the probe retry — but it RE-SENT `0100` each retry with
/// the 5 s steady-state read budget, which on a slow link RESTARTS the
/// protocol search, so the late `41 00` was never caught (→ false engine-off).
/// #3037 sends `0100` ONCE inside a GENEROUS protocol-search window and
/// RE-READS the in-progress search; a re-send happens ONLY on a genuine
/// transport throw (the write failed, the search never started).
///
/// These tests drive the REAL [SupportedPidsResolver] / [probeFirstSupportedPids]
/// against a fake `searchSend` closure that reproduces real ELM327 behaviour
/// (a single long read that resolves to `41 00`, a genuinely-silent ECU, a
/// pure timeout, a transport throw). They assert `searchSend` is called the
/// RIGHT NUMBER of times — in particular ONCE on the slow-search path.
void main() {
  silenceErrorLoggerSpool();

  setUp(() {
    // Collapse the transport-throw retry backoff so the (rare) retry path runs
    // in microseconds under the default (real-timer) test zone.
    obd2ProbeBackoffScale = 0.0;
  });
  tearDown(() {
    obd2ProbeBackoffScale = 1.0;
  });

  group('first 0100 probe — generous single-shot window (#3037)', () {
    test(
        'SLOW-SEARCH: a single 0100 read returns SEARCHING…then the real 41 00 '
        'bitmap (the generous window caught it) → PIDs discovered, ANSWERED, '
        'and 0100 was sent EXACTLY ONCE (not re-sent mid-search)', () async {
      final log = <String>[];
      // The whole protocol search resolves within ONE long read: SEARCHING
      // chatter inline, then the real supported-PIDs bitmap, one frame.
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (cmd) async {
          log.add(cmd);
          return 'SEARCHING...\r41 00 BE 3F A8 13\r>';
        },
        isConnected: () => true,
      );

      final discovered = await resolver.discoverSupportedPids();

      expect(discovered, isNotEmpty,
          reason: 'the generous window caught the 41 00 SEARCHING hid');
      expect(discovered.contains(0x0C), isTrue,
          reason: '41 00 BE… sets PID 0C (RPM)');
      expect(resolver.lastProbeResult, Obd2BusProbeResult.answered,
          reason: 'a real 41 00 bitmap means the bus ANSWERED');
      expect(log.length, 1,
          reason: 'the search is RE-READ within one window, never RE-SENT '
              '(a re-send restarts the protocol search)');
    });

    test(
        'genuine engine-off: 0100 returns UNABLE TO CONNECT within the window '
        '→ zero PIDs, PROBED-SILENT, sent ONCE (no hang, no re-send)',
        () async {
      final log = <String>[];
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (cmd) async {
          log.add(cmd);
          return 'UNABLE TO CONNECT\r>';
        },
        isConnected: () => true,
      );

      final discovered = await resolver.discoverSupportedPids();

      expect(discovered, isEmpty,
          reason: 'a truly silent ECU yields zero PIDs');
      expect(resolver.lastProbeResult, Obd2BusProbeResult.probedSilent,
          reason: 'UNABLE TO CONNECT within the window IS engine-off');
      expect(log.length, 1,
          reason: 'a definitive silent reply settles in one send');
    });

    test('genuine engine-off via NO DATA → PROBED-SILENT, sent once', () async {
      final log = <String>[];
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (cmd) async {
          log.add(cmd);
          return 'NO DATA\r>';
        },
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();

      expect(resolver.lastProbeResult, Obd2BusProbeResult.probedSilent);
      expect(log.length, 1);
    });

    test(
        'pure read timeout: 0100 times out within the generous window → '
        'TRANSIENT (not engine-off), and 0100 is NOT re-sent (a re-send would '
        'restart the search)', () async {
      final log = <String>[];
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (cmd) async {
          log.add(cmd);
          throw TimeoutException('ELM327 did not respond');
        },
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();

      expect(resolver.lastProbeResult, Obd2BusProbeResult.transient,
          reason: 'a timed-out search is indeterminate, never engine-off');
      expect(log.length, 1,
          reason: 'a timeout means the search MAY still be running → no '
              're-send (it would restart the protocol search)');
    });

    test(
        'a SEARCHING… that never resolves within the window → TRANSIENT, '
        'sent once', () async {
      final log = <String>[];
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (cmd) async {
          log.add(cmd);
          return 'SEARCHING...\r>'; // window elapsed mid-search, no data
        },
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();

      expect(resolver.lastProbeResult, Obd2BusProbeResult.transient);
      expect(log.length, 1,
          reason: 'an unresolved search is never re-sent');
    });

    test(
        'a genuine TRANSPORT THROW (the write failed, search never started) is '
        're-sent ONCE; if it succeeds → ANSWERED', () async {
      var calls = 0;
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (cmd) async {
          calls++;
          if (calls == 1) {
            throw StateError('concurrent sendCommand — link is recovering');
          }
          return '41 00 80 00 00 00\r>';
        },
        isConnected: () => true,
      );

      final discovered = await resolver.discoverSupportedPids();

      expect(discovered, isNotEmpty,
          reason: 'the bounded transport-throw re-send recovered the write');
      expect(resolver.lastProbeResult, Obd2BusProbeResult.answered);
      expect(calls, 2,
          reason: 'exactly one bounded re-send on a genuine transport throw');
    });

    test(
        'a transport THAT KEEPS THROWING is bounded → TRANSIENT (does not loop '
        'forever)', () async {
      var calls = 0;
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (cmd) async {
          calls++;
          throw StateError('link is recovering');
        },
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();

      expect(resolver.lastProbeResult, Obd2BusProbeResult.transient);
      expect(calls, kObd2ProbeMaxTransportRetries + 1,
          reason: 'one initial send + at most '
              '$kObd2ProbeMaxTransportRetries bounded transport-throw retries');
    });

    test('SEARCHING then data on the SAME single-line frame → ANSWERED, once',
        () async {
      final log = <String>[];
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (cmd) async {
          log.add(cmd);
          return 'SEARCHING...\r41 00 80 00 00 00\r>';
        },
        isConnected: () => true,
      );

      final discovered = await resolver.discoverSupportedPids();

      expect(discovered, isNotEmpty);
      expect(resolver.lastProbeResult, Obd2BusProbeResult.answered);
      expect(log.length, 1);
    });

    test('a fresh connection resets the probe result to notProbed', () async {
      final resolver = SupportedPidsResolver(
        send: (_) async => '41 00 80 00 00 00\r>',
        isConnected: () => true,
      );
      await resolver.discoverSupportedPids();
      expect(resolver.lastProbeResult, Obd2BusProbeResult.answered);

      resolver.resetForNewConnection();
      expect(resolver.lastProbeResult, Obd2BusProbeResult.notProbed);
    });
  });

  /// #3037 root cause 3 — the `0100` probe was INVISIBLE in the connect trace
  /// (steps stopped at ATI), so a failing trace was half-blind. The probe now
  /// tees its raw `0100` read into the active connect trace, so a future trace
  /// shows EXACTLY what the ECU returned. Ends the blind-fix cycle.
  group('0100 probe is RECORDED in the connect trace (#3037)', () {
    setUp(Obd2ConnectTraceLog.clear);
    tearDown(Obd2ConnectTraceLog.clear);

    Obd2ConnectStep firstStepLabelled(String label) {
      final trace = Obd2ConnectTraceLog.snapshot().first;
      return trace.steps.firstWhere((s) => s.label == label,
          orElse: () => throw StateError(
              'no "$label" step in the trace; steps were '
              '${trace.steps.map((s) => s.label).toList()}'));
    }

    test('a SEARCHING-then-41 00 probe records a 0100 step with the raw reply',
        () async {
      final handle = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect);
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (_) async => 'SEARCHING...\r41 00 BE 3F A8 13\r>',
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();
      Obd2ConnectTraceLog.endTrace(handle);

      final step = firstStepLabelled('0100');
      expect(step.detail, contains('41 00'),
          reason: 'the trace must show the raw 0100 reply (41 00 …)');
    });

    test(
        'a genuinely-silent ECU records the raw NO DATA / UNABLE reply in the '
        'trace so a future trace shows the engine-off signature', () async {
      final handle = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect);
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (_) async => 'UNABLE TO CONNECT\r>',
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();
      Obd2ConnectTraceLog.endTrace(handle);

      final step = firstStepLabelled('0100');
      expect(step.detail, contains('UNABLE TO CONNECT'),
          reason: 'the trace must show the raw engine-off reply');
    });

    test('a probe TIMEOUT records a TIMEOUT 0100 step in the trace', () async {
      final handle = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect);
      final resolver = SupportedPidsResolver(
        send: (_) async => 'NO DATA\r>',
        searchSend: (_) async =>
            throw TimeoutException('ELM327 did not respond'),
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();
      Obd2ConnectTraceLog.endTrace(handle);

      final step = firstStepLabelled('0100');
      expect(step.detail?.toUpperCase(), contains('TIMEOUT'),
          reason: 'a timed-out search must be visible as a TIMEOUT 0100 step');
    });
  });
}
