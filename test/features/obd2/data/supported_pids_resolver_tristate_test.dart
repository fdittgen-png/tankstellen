// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/obd2/data/obd2_session_diagnostic.dart';
import 'package:tankstellen/features/obd2/data/supported_pids_resolver.dart';

/// #2469 — discovered-supported tri-state: supported / unsupported /
/// unknown, sourced from the resolver's discovered set, teed FREE into the
/// gated comm-diagnostics collector.
void main() {
  setUp(Obd2CommDiagnostics.instance.reset);
  tearDown(() {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
  });

  group('SupportedPidsResolver.supportedTriState', () {
    test('unknown for EVERY pid before discovery runs (blind session)', () {
      final resolver = SupportedPidsResolver(
        send: (cmd) async => 'NO DATA',
        isConnected: () => true,
      );
      expect(resolver.supportedTriState(0x0C), 'unknown');
      expect(resolver.supportedTriState(0x5E), 'unknown');
    });

    test('supported / unsupported once discovery resolved the set', () async {
      final supported = <int>{0x04, 0x0C, 0x0D, 0x11};
      final resolver = SupportedPidsResolver(
        send: (cmd) async {
          if (cmd.startsWith('0100')) return _bitmapResponse(0x00, supported);
          return 'NO DATA';
        },
        isConnected: () => true,
      );
      await resolver.discoverSupportedPids();
      expect(resolver.supportedTriState(0x0C), 'supported'); // in the set
      expect(resolver.supportedTriState(0x5E), 'unsupported'); // resolved, absent
    });
  });

  group('SupportedPidsResolver.recordSupportedTriStateInto (#2469)', () {
    test('debugMode ON: tees a tri-state per target command', () async {
      Obd2CommDiagnostics.instance.enabled = true;
      Obd2CommDiagnostics.instance.beginSession(linkKind: 'ble');

      final supported = <int>{0x0C};
      final resolver = SupportedPidsResolver(
        send: (cmd) async {
          if (cmd.startsWith('0100')) return _bitmapResponse(0x00, supported);
          return 'NO DATA';
        },
        isConnected: () => true,
      );
      await resolver.discoverSupportedPids();

      resolver.recordSupportedTriStateInto({'010C': 0x0C, '015E': 0x5E});
      final tri = Obd2CommDiagnostics.instance.snapshot().discoveredSupported;
      expect(tri['010C'], 'supported');
      expect(tri['015E'], 'unsupported');
    });

    test('debugMode OFF: tee is a pure no-op', () async {
      // Collector disabled (default) → nothing recorded, no live session.
      final resolver = SupportedPidsResolver(
        send: (cmd) async => 'NO DATA',
        isConnected: () => true,
      );
      resolver.recordSupportedTriStateInto({'010C': 0x0C});
      expect(
        Obd2CommDiagnostics.instance.snapshot(),
        const Obd2SessionDiagnostic(),
      );
    });
  });
}

/// Same SAE J1979 bitmap builder used by the resolver-target test.
String _bitmapResponse(int groupBase, Set<int> supported) {
  var bits = 0;
  for (final pid in supported) {
    final offset = pid - groupBase; // 1..32
    if (offset < 1 || offset > 32) continue;
    bits |= 1 << (32 - offset);
  }
  final hex = bits.toRadixString(16).padLeft(8, '0').toUpperCase();
  const mode = 0x41; // response to Mode 01
  final pid = groupBase.toRadixString(16).padLeft(2, '0').toUpperCase();
  final bytes = <String>[
    for (var i = 0; i < 8; i += 2) hex.substring(i, i + 2),
  ];
  return '${mode.toRadixString(16).toUpperCase()} $pid ${bytes.join(' ')}>';
}
