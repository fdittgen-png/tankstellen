import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_table.dart';

/// Minimal in-memory [Obd2RawCommandPort] for exercising the
/// [OemPidTable] contract (#1401 phase 3).
///
/// Records every command sent and replies with the canned response
/// stored at the matching key. Unknown commands resolve to an empty
/// string — the same shape a real adapter returns on NO DATA, so
/// concrete tables can branch on it uniformly.
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

/// Toy [OemPidTable] for testing the abstract contract — uses a
/// header-switch + Mode 22 PID 51 pattern that mirrors the real PSA
/// table planned for phase 4, but with a hardcoded scaling so the
/// test owns the parsing fixture.
class _ToyOemTable extends OemPidTable {
  const _ToyOemTable({
    this.key = 'TOY',
    this.prefixes = const {'ABC', 'DEF'},
  });

  final String key;
  final Set<String> prefixes;

  @override
  String get oemKey => key;

  @override
  Set<String> get supportedWmiPrefixes => prefixes;

  /// Toy parser: send `2151\r`, expect `'61 51 XX'` back, scale
  /// `XX * 0.5` litres. Empty / NO DATA / malformed → null.
  @override
  Future<double?> readFuelLevelLitres(Obd2RawCommandPort port) async {
    final raw = await port.sendRaw('2151\r');
    final cleaned = raw.replaceAll('>', '').trim();
    if (cleaned.isEmpty) return null;
    if (cleaned.toUpperCase().contains('NO DATA')) return null;
    // Expect "61 51 XX" — service mode 0x21 + 0x40 = 0x61 echo.
    final parts =
        cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length < 3) return null;
    if (parts[0].toUpperCase() != '61' || parts[1].toUpperCase() != '51') {
      return null;
    }
    final byte = int.tryParse(parts[2], radix: 16);
    if (byte == null) return null;
    return byte * 0.5;
  }
}

void main() {
  group('OemPidTable contract (#1401 phase 3)', () {
    test('exposes oemKey and supportedWmiPrefixes for logging + lookup', () {
      const table = _ToyOemTable(key: 'PSA', prefixes: {'VF3', 'VF7'});

      expect(table.oemKey, 'PSA');
      expect(table.supportedWmiPrefixes, {'VF3', 'VF7'});
    });

    test('readFuelLevelLitres parses canned 61 51 byte response', () async {
      const table = _ToyOemTable();
      // 0x40 == 64 → 64 * 0.5 = 32.0 L.
      final port = _FakePort({'2151\r': '61 51 40\r>'});

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, 32.0);
      expect(port.sent, ['2151\r']);
    });

    test('returns null on NO DATA response', () async {
      const table = _ToyOemTable();
      final port = _FakePort({'2151\r': 'NO DATA\r>'});

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, isNull);
    });

    test('returns null on empty / prompt-only response', () async {
      const table = _ToyOemTable();
      final port = _FakePort({'2151\r': '>'});

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, isNull);
    });

    test('returns null on malformed (wrong service-mode echo)', () async {
      const table = _ToyOemTable();
      // 7F = negative response, not the expected 0x61 echo.
      final port = _FakePort({'2151\r': '7F 21 31\r>'});

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, isNull);
    });

    test('returns null on truncated frame', () async {
      const table = _ToyOemTable();
      final port = _FakePort({'2151\r': '61 51\r>'});

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, isNull);
    });

    test('default response is empty string — port treats unknowns as NO DATA',
        () async {
      const table = _ToyOemTable();
      final port = _FakePort(); // no canned responses

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, isNull);
      expect(port.sent, ['2151\r']);
    });

    test('Obd2RawCommandPort.sendRaw is the only port surface', () {
      // Compile-time check: a fake implementing exactly one method
      // satisfies the port. If we ever widen the interface, this
      // file fails to compile and the design intent is reasserted
      // before the change ships.
      const Obd2RawCommandPort port = _SingleMethodPort();
      expect(port, isA<Obd2RawCommandPort>());
    });
  });
}

class _SingleMethodPort implements Obd2RawCommandPort {
  const _SingleMethodPort();

  @override
  Future<String> sendRaw(String command) async => '';
}
