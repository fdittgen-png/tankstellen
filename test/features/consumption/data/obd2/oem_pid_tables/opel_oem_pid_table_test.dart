// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_capability.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_table.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_tables/opel_oem_pid_table.dart';

/// Tests for the Opel `W0L` OEM fuel-level table (#1617).

/// In-memory [Obd2RawCommandPort] — records sent commands, returns a
/// canned response per command (empty string = NO DATA, same shape a
/// real adapter delivers). Mirrors the fake in the PSA table suite.
class _FakePort implements Obd2RawCommandPort {
  final List<String> sent = [];
  final Map<String, String> responses;

  _FakePort([this.responses = const {}]);

  @override
  Future<String> sendRaw(String command) async {
    sent.add(command);
    return responses[command] ?? '';
  }
}

void main() {
  group('OpelOemPidTable (#1617)', () {
    const table = OpelOemPidTable();

    test('claims the Opel W0L / W0V WMI prefixes and reports oemKey OPEL',
        () {
      expect(table.supportedWmiPrefixes, contains('W0L'));
      expect(table.supportedWmiPrefixes, contains('W0V'));
      expect(table.oemKey, 'OPEL');
    });

    test('reads fuel litres via the shared PSA EMP2 BSI command', () async {
      // A post-2017 (PSA-platform) Opel BSI answers `67A 03 61 51 XX`;
      // 0x5A = 90 decimal → 90 × 0.5 = 45.0 L.
      final port = _FakePort(const {
        'AT SH 6FA\r': 'OK',
        '2151\r': '67A 03 61 51 5A',
      });
      expect(await table.readFuelLevelLitres(port), 45.0);
      expect(port.sent, contains('2151\r'));
    });

    test('a pre-2017 GM-BSI negative response falls back to null',
        () async {
      final port = _FakePort(const {
        'AT SH 6FA\r': 'OK',
        '2151\r': '7F 21 31', // subFunctionNotSupported
      });
      expect(await table.readFuelLevelLitres(port), isNull);
    });
  });

  group('OemPidRegistry — Opel registration (#1617)', () {
    final registry = OemPidRegistry.withDefaults();

    test('a W0L VIN resolves to the Opel table', () {
      final t = registry.lookupByVin('W0LPD6EA9R8000001');
      expect(t, isA<OpelOemPidTable>());
      expect(t!.oemKey, 'OPEL');
    });

    test('a W0L VIN resolves through the capability gate', () {
      final t = registry.resolveForCapability(
          'W0LPD6EA9R8000001', Obd2AdapterCapability.oemPidsCapable);
      expect(t, isA<OpelOemPidTable>());
    });

    test('the PSA prefixes still resolve to the PSA table — no overlap',
        () {
      expect(registry.lookupByVin('VF37H9HRACL000001')?.oemKey, 'PSA');
    });
  });
}
