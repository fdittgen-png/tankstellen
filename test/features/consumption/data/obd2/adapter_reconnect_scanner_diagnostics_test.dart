// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_reconnect_scanner.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import '../../../../helpers/silence_error_logger.dart';

const _kInitial = Duration(milliseconds: 10);
const _kMax = Duration(milliseconds: 80);

Future<void> _waitFor(
  bool Function() cond, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  silenceErrorLoggerSpool();

  setUp(Obd2CommDiagnostics.instance.reset);
  tearDown(() {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
  });

  group('AdapterReconnectScanner → Obd2CommDiagnostics reconnect tee (#2466)',
      () {
    test(
        'debugMode ON: a first-probe reconnect is SILENT with a '
        'time-to-reconnect sample', () async {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      var reconnects = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'AA:BB',
        probe: (mac) async => mac == 'AA:BB', // in range immediately
        connect: (_) async => true, // first attempt succeeds
        onReconnect: () => reconnects++,
        initialBackoff: _kInitial,
        firstProbeDelay: _kInitial,
        maxBackoff: _kMax,
      );
      await scanner.start();
      await _waitFor(() => reconnects > 0);
      expect(scanner.isScanning, isFalse);

      final conn = Obd2CommDiagnostics.instance.snapshot().connection;
      expect(conn.silentReconnects, 1,
          reason: 'recovered on the fast first probe → silent');
      expect(conn.visibleReconnects, 0);
      expect(conn.timeToReconnectP50Ms, isNotNull,
          reason: 'time-to-reconnect was sampled');
      expect(conn.timeToReconnectP50Ms, greaterThanOrEqualTo(0));
    });

    test(
        'debugMode ON: a reconnect that takes several missed probes is '
        'VISIBLE', () async {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      var connectCalls = 0;
      var reconnects = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async => true, // always in range
        connect: (_) async {
          connectCalls++;
          // First two attempts fail (backoff escalates), third succeeds.
          return connectCalls >= 3;
        },
        onReconnect: () => reconnects++,
        initialBackoff: _kInitial,
        firstProbeDelay: _kInitial,
        maxBackoff: _kMax,
      );
      await scanner.start();
      await _waitFor(() => reconnects > 0);

      final conn = Obd2CommDiagnostics.instance.snapshot().connection;
      expect(conn.visibleReconnects, 1,
          reason: 'recovered only after the backoff escalated → visible');
      expect(conn.silentReconnects, 0);
      expect(conn.timeToReconnectP50Ms, isNotNull);
    });

    test('debugMode OFF: a reconnect records nothing (pure no-op)', () async {
      expect(Obd2CommDiagnostics.instance.enabled, isFalse);
      Obd2CommDiagnostics.instance.beginSession();

      var reconnects = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'AA:BB',
        probe: (mac) async => mac == 'AA:BB',
        connect: (_) async => true,
        onReconnect: () => reconnects++,
        initialBackoff: _kInitial,
        firstProbeDelay: _kInitial,
        maxBackoff: _kMax,
      );
      await scanner.start();
      await _waitFor(() => reconnects > 0);

      // beginSession is itself a no-op when disabled ⇒ empty sentinel.
      final conn = Obd2CommDiagnostics.instance.snapshot().connection;
      expect(conn.silentReconnects, 0);
      expect(conn.visibleReconnects, 0);
      expect(conn.timeToReconnectP50Ms, isNull);
      // The reconnect itself still fired — behaviour is unchanged.
      expect(reconnects, 1);
    });
  });
}
