// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'supported_pids_probe.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'supported_pids_resolver.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #3035 — the CORE OBD2 bug: the adapter connects (AT handshake OK) but the
/// app never reads live PIDs even with the ignition ON, and instead falsely
/// classifies engine-off + loops reconnects.
///
/// ROOT CAUSE (ELM327 datasheet + python-OBD): the AT commands are answered
/// by the adapter's own MCU and NEVER touch the car. The ECU is only
/// contacted by the FIRST OBD request, `0100`, which triggers the ELM327
/// protocol search — the adapter replies `SEARCHING...` and the real
/// `41 00 <bitmap>` (or `UNABLE TO CONNECT`) can take several seconds / arrive
/// on a LATER read. On master `discoverSupportedPids` does NO retry: the first
/// `0100` exception/empty → empty set → `busAnswered=false` → false engine-off.
///
/// These tests drive the REAL [SupportedPidsResolver] / [probeFirstSupportedPids]
/// against a fake `send` closure that reproduces real ELM327 behaviour (a
/// SEARCHING reply, a one-shot timeout, a genuinely-silent ECU) — NOT a fake
/// that just returns the expected supported set. They are RED on master and
/// GREEN with the resilient retry/SEARCHING-aware probe.
void main() {
  silenceErrorLoggerSpool();

  setUp(() {
    // Collapse the 0/300/600 ms probe backoff so the retry path runs in
    // microseconds under the default (real-timer) test zone.
    obd2ProbeBackoffScale = 0.0;
  });
  tearDown(() {
    obd2ProbeBackoffScale = 1.0;
  });

  /// A `send` closure whose reply for a given command advances through a
  /// scripted SEQUENCE on each successive call — the missing capability on
  /// master's single-shot probe. A `String` entry is returned; a
  /// `TimeoutException` entry is thrown (a real read-budget elapse).
  Future<String> Function(String) sequencedSend(
    Map<String, List<Object>> script, {
    List<String>? log,
  }) {
    final cursor = <String, int>{};
    return (cmd) async {
      log?.add(cmd);
      final steps = script[cmd];
      if (steps == null || steps.isEmpty) return 'NO DATA\r>';
      final i = cursor[cmd] ?? 0;
      final step = steps[i < steps.length ? i : steps.length - 1];
      cursor[cmd] = i + 1;
      if (step is TimeoutException) throw step;
      return step as String;
    };
  }

  group('first 0100 probe is resilient to the protocol search (#3035)', () {
    test(
        'SEARCHING-then-data: first 0100 returns SEARCHING…, the RETRY returns '
        'a real 41 00 bitmap → PIDs discovered, probe ANSWERED, not engine-off',
        () async {
      final log = <String>[];
      // The classic ELM327 protocol-search transcript: the first 0100 read
      // returns the bare "SEARCHING..." chatter (no data yet), the second
      // delivers the real supported-PIDs bitmap (PID 0C/0D/05 present).
      final send = sequencedSend({
        '0100\r': ['SEARCHING...\r>', '41 00 BE 3F A8 13\r>'],
      }, log: log);
      final resolver = SupportedPidsResolver(
        send: send,
        isConnected: () => true,
      );

      final discovered = await resolver.discoverSupportedPids();

      expect(discovered, isNotEmpty,
          reason: 'the retry must discover the PIDs the first SEARCHING hid');
      expect(discovered.contains(0x0C), isTrue,
          reason: '41 00 BE… sets PID 0C (RPM)');
      expect(resolver.lastProbeResult, Obd2BusProbeResult.answered,
          reason: 'a real 41 00 bitmap means the bus ANSWERED');
      expect(log.where((c) => c == '0100\r').length, greaterThanOrEqualTo(2),
          reason: 'the resolver must RE-READ 0100 after SEARCHING, not bail');
    });

    test(
        'transient-timeout-then-data: first 0100 throws TimeoutException, the '
        'retry succeeds → PIDs discovered, probe ANSWERED, not engine-off',
        () async {
      final send = sequencedSend({
        '0100\r': [
          TimeoutException('ELM327 did not respond'),
          '41 00 80 00 00 00\r>', // PID 01 supported, no next-range flag
        ],
      });
      final resolver = SupportedPidsResolver(
        send: send,
        isConnected: () => true,
      );

      final discovered = await resolver.discoverSupportedPids();

      expect(discovered, isNotEmpty,
          reason: 'a single first-shot timeout must NOT be terminal');
      expect(resolver.lastProbeResult, Obd2BusProbeResult.answered);
    });

    test(
        'genuine engine-off: every 0100 retry returns UNABLE TO CONNECT → '
        'zero PIDs, probe PROBED-SILENT (real engine-off still detected)',
        () async {
      final send = sequencedSend({
        '0100\r': ['UNABLE TO CONNECT\r>'], // sticky last → every retry silent
      });
      final resolver = SupportedPidsResolver(
        send: send,
        isConnected: () => true,
      );

      final discovered = await resolver.discoverSupportedPids();

      expect(discovered, isEmpty,
          reason: 'a truly silent ECU yields zero PIDs');
      expect(resolver.lastProbeResult, Obd2BusProbeResult.probedSilent,
          reason: 'UNABLE TO CONNECT through every retry IS engine-off');
    });

    test(
        'genuine engine-off via NO DATA: every 0100 retry returns NO DATA → '
        'probe PROBED-SILENT', () async {
      final send = sequencedSend({
        '0100\r': ['NO DATA\r>'],
      });
      final resolver = SupportedPidsResolver(
        send: send,
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();

      expect(resolver.lastProbeResult, Obd2BusProbeResult.probedSilent);
    });

    test(
        'every retry merely times out (no definitive-silent reply) → probe is '
        'TRANSIENT, NOT a confirmed engine-off', () async {
      final send = sequencedSend({
        '0100\r': [TimeoutException('t')], // sticky → every attempt times out
      });
      final resolver = SupportedPidsResolver(
        send: send,
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();

      expect(resolver.lastProbeResult, Obd2BusProbeResult.transient,
          reason: 'pure timeouts are indeterminate — never told engine-off');
    });

    test('probe bounds its retries (does not loop forever)', () async {
      final log = <String>[];
      final send = sequencedSend({
        '0100\r': ['SEARCHING...\r>'], // sticky → never resolves
      }, log: log);
      final resolver = SupportedPidsResolver(
        send: send,
        isConnected: () => true,
      );

      await resolver.discoverSupportedPids();

      expect(log.where((c) => c == '0100\r').length, kObd2ProbeAttempts,
          reason: 'exactly $kObd2ProbeAttempts bounded attempts, then give up');
      expect(resolver.lastProbeResult, Obd2BusProbeResult.transient,
          reason: 'SEARCHING that never resolves is transient, not silent');
    });

    test(
        'SEARCHING then data on the SAME multi-line frame parses without a '
        'retry (probe ANSWERED)', () async {
      final log = <String>[];
      final send = sequencedSend({
        // Real adapters frequently inline the data after SEARCHING.
        '0100\r': ['SEARCHING...\r41 00 80 00 00 00\r>'],
      }, log: log);
      final resolver = SupportedPidsResolver(
        send: send,
        isConnected: () => true,
      );

      final discovered = await resolver.discoverSupportedPids();

      expect(discovered, isNotEmpty);
      expect(resolver.lastProbeResult, Obd2BusProbeResult.answered);
      expect(log.where((c) => c == '0100\r').length, 1,
          reason: 'the bitmap is already present → no second read needed');
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
}
