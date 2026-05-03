import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_table.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_tables/psa_oem_pid_table.dart';

/// Programmable in-memory [Obd2RawCommandPort]. Records every command
/// the table sends so the integration test can assert the wire-level
/// sequence (`AT SH 6FA` → `2151` → `AT SH 7DF`). Returns a canned
/// response per command; unknown commands resolve to an empty string —
/// the same shape a real adapter delivers on NO DATA. Mirrors the fake
/// in `oem_pid_table_test.dart` so the two suites read the same way.
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
  group('parsePsaFuelLevelLitres — pure parser (#1401 phase 4)', () {
    test('canonical headered response — 0x5A → 45.0 L', () {
      // 0x5A = 90 decimal; 90 * 0.5 = 45.0 L.
      expect(parsePsaFuelLevelLitres('67A 03 61 51 5A'), 45.0);
    });

    test('tolerates whitespace, lowercase and ELM327 prompt noise', () {
      // Real adapters sandwich the response between a leading prompt
      // and a trailing `\r>`. Lowercase hex shows up on a few clones
      // even with ATCAF1 set.
      expect(
        parsePsaFuelLevelLitres('>67a 03 61 51 5a\r\n>'),
        45.0,
      );
    });

    test('header-stripped response (ATH0) — `03 61 51 XX` still parses', () {
      // Some adapters (or our own ATH0 init) drop the `67A` header
      // entirely. The parser locates `61 51` anywhere in the token
      // stream so this shape works without a special branch.
      expect(parsePsaFuelLevelLitres('03 61 51 5A'), 45.0);
    });

    test('boundary: byte 0x00 → 0.0 L (empty tank reading)', () {
      expect(parsePsaFuelLevelLitres('67A 03 61 51 00'), 0.0);
    });

    test('boundary: byte 0xFF → 127.5 L (parser does not clamp)', () {
      // Range top of the single-byte scaling. A real PSA tank caps
      // around ~70 L so 127.5 would never appear in the wild, but
      // the parser intentionally does not clamp — clamping is the
      // caller's job (sanity-checking against tank capacity).
      expect(parsePsaFuelLevelLitres('67A 03 61 51 FF'), 127.5);
    });

    test('negative response `7F 21 XX` → null', () {
      // PSA BSI returns `7F 21 31` ("subFunctionNotSupported") on
      // older platform-1 cars or on non-PSA BSIs. Caller falls back
      // to PID 0x2F percentage path.
      expect(parsePsaFuelLevelLitres('7F 21 31'), isNull);
    });

    test('null / empty / whitespace-only → null', () {
      expect(parsePsaFuelLevelLitres(null), isNull);
      expect(parsePsaFuelLevelLitres(''), isNull);
      expect(parsePsaFuelLevelLitres('   \r\n\t'), isNull);
      // Prompt-only response (a real ELM327 emits this when nothing
      // follows the request — adapter is alive but the ECU didn't
      // answer in time).
      expect(parsePsaFuelLevelLitres('>'), isNull);
    });

    test('echoed request line is ignored, response on next line parses', () {
      // Some adapters echo the request back even with ATE0 if the
      // hardware UART buffered the bytes already. The parser walks
      // every line and stops at the one carrying `61 51`.
      expect(
        parsePsaFuelLevelLitres('2151\r67A 03 61 51 5A'),
        45.0,
      );
    });

    test('payload byte that is not valid hex → null', () {
      // Defensive: a corrupted byte (e.g. 'ZZ') must NOT throw —
      // the OEM read contract is "null on any parse failure".
      expect(parsePsaFuelLevelLitres('67A 03 61 51 ZZ'), isNull);
    });

    test('truncated frame missing the data byte → null', () {
      expect(parsePsaFuelLevelLitres('67A 03 61 51'), isNull);
    });

    test('garbage frame without the `61 51` echo → null', () {
      // Wrong service-mode echo, e.g. an unrelated PID response that
      // happened to land in the buffer.
      expect(parsePsaFuelLevelLitres('41 0D 64'), isNull);
    });
  });

  group('PsaOemPidTable identity (#1401 phase 4)', () {
    test('oemKey is "PSA"', () {
      expect(const PsaOemPidTable().oemKey, 'PSA');
    });

    test('claims VF3 / VF7 / VR1 / VR3 (post-2008 PSA passenger cars)', () {
      expect(
        const PsaOemPidTable().supportedWmiPrefixes,
        {'VF3', 'VF7', 'VR1', 'VR3'},
      );
    });
  });

  group('PsaOemPidTable.readFuelLevelLitres — wire sequence (#1401 phase 4)',
      () {
    test('sends AT SH 6FA → 2151 → AT SH 7DF and returns 45.0 L for 0x5A',
        () async {
      const table = PsaOemPidTable();
      final port = _FakePort({
        'AT SH 6FA\r': 'OK\r>',
        '2151\r': '67A 03 61 51 5A\r>',
        'AT SH 7DF\r': 'OK\r>',
      });

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, 45.0);
      // Order matters: header switch must happen BEFORE the data
      // request, restore must happen AFTER.
      expect(port.sent, [
        'AT SH 6FA\r',
        '2151\r',
        'AT SH 7DF\r',
      ]);
    });

    test('returns null on the BSI negative response and still restores header',
        () async {
      const table = PsaOemPidTable();
      final port = _FakePort({
        'AT SH 6FA\r': 'OK\r>',
        '2151\r': '7F 21 31\r>',
        'AT SH 7DF\r': 'OK\r>',
      });

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, isNull);
      // Restore is best-effort but happens regardless of the data
      // request's outcome — leaving the adapter pointed at the BSI
      // would poison subsequent standard-PID reads.
      expect(port.sent.last, 'AT SH 7DF\r');
    });

    test(
        'bails out of the data request when the adapter rejects AT SH (clones)',
        () async {
      const table = PsaOemPidTable();
      // A clone that doesn't support `AT SH` answers `?` to the
      // header-switch command. The table must NOT proceed to send
      // `2151` — that would hang the loop on a guaranteed timeout.
      final port = _FakePort({
        'AT SH 6FA\r': '?\r>',
      });

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, isNull);
      expect(port.sent, ['AT SH 6FA\r']);
    });

    test('returns null and restores header when ECU is silent (empty data)',
        () async {
      const table = PsaOemPidTable();
      final port = _FakePort({
        'AT SH 6FA\r': 'OK\r>',
        '2151\r': '',
        'AT SH 7DF\r': 'OK\r>',
      });

      final litres = await table.readFuelLevelLitres(port);

      expect(litres, isNull);
      // Header restore still runs — it's best-effort.
      expect(port.sent, [
        'AT SH 6FA\r',
        '2151\r',
        'AT SH 7DF\r',
      ]);
    });
  });
}
