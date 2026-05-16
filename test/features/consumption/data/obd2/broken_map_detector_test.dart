import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_detector.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_table.dart';

/// Programmable in-memory [Obd2RawCommandPort] for the detector tests.
/// Records every command and returns a canned response per-command;
/// unknown commands resolve to the empty string (the same shape a real
/// adapter delivers on NO DATA). A per-command call counter lets tests
/// assert the diesel rev path actually issues a second 010B read.
class _FakeObd2RawCommandPort implements Obd2RawCommandPort {
  _FakeObd2RawCommandPort([this.responses = const {}]);

  /// Map of command → ordered list of responses. The first call to a
  /// command consumes index 0; the second consumes index 1; if the
  /// list is shorter than the number of calls, subsequent calls reuse
  /// the last entry. Tests that need the same answer every call pass
  /// a single-element list (or the convenience [single] constructor).
  final Map<String, List<String>> responses;

  /// Per-command call counter — useful for asserting the diesel branch
  /// reads PID 0x0B exactly twice.
  final Map<String, int> callCount = <String, int>{};

  /// Verbatim sent commands in order — same shape as the OEM-table
  /// fakes elsewhere in the suite.
  final List<String> sent = <String>[];

  factory _FakeObd2RawCommandPort.single(Map<String, String> map) =>
      _FakeObd2RawCommandPort(
        map.map((k, v) => MapEntry(k, [v])),
      );

  @override
  Future<String> sendRaw(String command) async {
    sent.add(command);
    final n = (callCount[command] ?? 0);
    callCount[command] = n + 1;
    final list = responses[command];
    if (list == null || list.isEmpty) return '';
    return list[n < list.length ? n : list.length - 1];
  }
}

/// Port that throws on every call — tests exception handling.
class _ThrowingPort implements Obd2RawCommandPort {
  @override
  Future<String> sendRaw(String command) async {
    throw StateError('transport offline');
  }
}

/// Build a Mode 01 single-byte response. ELM-style: `41 PID XX>` with a
/// trailing prompt; the parser tolerates the prompt either way.
String _resp(int pid, int value) {
  final p = pid.toRadixString(16).padLeft(2, '0').toUpperCase();
  final v = value.toRadixString(16).padLeft(2, '0').toUpperCase();
  return '41 $p $v\r>';
}

class _NoOpRecorder implements TraceRecorder {
  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  // Deterministic time injected into every probe so the EMA / lastUpdate
  // assertions are reproducible. Mirrors the convention used by the
  // sibling phase 1 updater test.
  final fixedNow = DateTime(2026, 5, 4, 10, 30);

  // The detector logs through `errorLogger.log` on every probe-skip
  // (TPS not closed) and every transport throw. Without a recorder
  // the call routes to the Hive spool and crashes the test isolate.
  // Wire a no-op recorder for every test, mirroring the populator
  // suite.
  setUp(() {
    errorLogger.resetForTest();
    errorLogger.testRecorderOverride = _NoOpRecorder();
  });

  tearDown(() {
    errorLogger.resetForTest();
  });

  group('BrokenMapDetector — petrol path', () {
    test(
        'healthy MAP (mapIdle=30, baro=101, tps=1%) yields ~0 observation',
        () async {
      final port = _FakeObd2RawCommandPort.single({
        '0111\r': _resp(0x11, 3), // tps ≈ 1.18%
        '010B\r': _resp(0x0B, 30),
        '0133\r': _resp(0x33, 101),
      });

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: false,
        prior: const BrokenMapBelief(),
        now: fixedNow,
      );

      // delta = 71 → vacuumMissingScore clamps to 0.
      // Bayesian fold: α' = 0.5·1 + 8·0 = 0.5, β' = 0.5·9 + 1 = 5.5.
      // pointEstimate = 0.5/6 ≈ 0.083 — well under 0.4 (silent band).
      expect(updated.alpha, closeTo(0.5, 1e-9));
      expect(updated.beta, closeTo(5.5, 1e-9));
      expect(updated.pointEstimate, lessThan(0.4));
      expect(updated.observationCount, 1);
      expect(updated.lastUpdate, fixedNow);
      // Weak observation — lastTrigger should NOT be set.
      expect(updated.lastTrigger, BrokenMapReason.none);
    });

    test(
        'broken MAP (mapIdle=99, baro=101, tps=1%) yields ~1.0 observation '
        'and posterior lifts toward the verifying band on a single fold',
        () async {
      final port = _FakeObd2RawCommandPort.single({
        '0111\r': _resp(0x11, 3),
        '010B\r': _resp(0x0B, 99),
        '0133\r': _resp(0x33, 101),
      });

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: false,
        prior: const BrokenMapBelief(),
        now: fixedNow,
      );

      // delta = 2 → vacuumMissingScore clamps to 1.0.
      // α' = 0.5 + 8 = 8.5, β' = 4.5 + 0 = 4.5 → mean = 8.5/13 ≈ 0.654.
      expect(updated.alpha, closeTo(8.5, 1e-9));
      expect(updated.beta, closeTo(4.5, 1e-9));
      expect(updated.pointEstimate, closeTo(8.5 / 13.0, 1e-9));
      expect(updated.observationCount, 1);
      // Strong observation — reason tag MUST land.
      expect(updated.lastTrigger, BrokenMapReason.idleVacuumMissing);
    });

    test('half-vacuum (mapIdle=70, baro=101, tps=1%) yields interior score',
        () async {
      final port = _FakeObd2RawCommandPort.single({
        '0111\r': _resp(0x11, 3),
        '010B\r': _resp(0x0B, 70),
        '0133\r': _resp(0x33, 101),
      });

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: false,
        prior: const BrokenMapBelief(),
        now: fixedNow,
      );

      // delta = 31 → score = 1 - (31-15)/30 = 0.4666...
      // α' = 0.5 + 8·0.4666 ≈ 4.233; β' = 4.5 + 0.533 ≈ 5.033;
      // mean ≈ 0.457 — squarely in the verifying band.
      expect(updated.pointEstimate, greaterThan(0.4));
      expect(updated.pointEstimate, lessThan(0.55));
      expect(updated.observationCount, 1);
    });
  });

  group('BrokenMapDetector — diesel path', () {
    test('healthy rev delta (mapIdle=85, mapRevved=110) yields low score',
        () async {
      final port = _FakeObd2RawCommandPort(<String, List<String>>{
        '0111\r': [_resp(0x11, 3)],
        // First 010B = idle, second 010B (after _revDelay) = revved.
        '010B\r': [_resp(0x0B, 85), _resp(0x0B, 110)],
      });

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: true,
        prior: const BrokenMapBelief(),
        now: fixedNow,
      );

      // |110 - 85| = 25 → revDeltaMissingScore = 1 - (25-8)/22 ≈ 0.227.
      // α' = 0.5 + 8·0.227 ≈ 2.316; β' = 4.5 + 0.773 ≈ 5.273;
      // mean ≈ 0.305 — in the silent band.
      expect(updated.pointEstimate, lessThan(0.4));
      expect(updated.observationCount, 1);
      // Weak observation — lastTrigger stays at the default.
      expect(updated.lastTrigger, BrokenMapReason.none);
      // The diesel branch MUST have read PID 0x0B exactly twice.
      expect(port.callCount['010B\r'], 2);
    });

    test('broken diesel (mapIdle=98, mapRevved=99) yields ~1.0 observation',
        () async {
      final port = _FakeObd2RawCommandPort(<String, List<String>>{
        '0111\r': [_resp(0x11, 3)],
        '010B\r': [_resp(0x0B, 98), _resp(0x0B, 99)],
      });

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: true,
        prior: const BrokenMapBelief(),
        now: fixedNow,
      );

      // |99 - 98| = 1 → score clamps to 1.0 → α' = 8.5, β' = 4.5
      // → mean ≈ 0.654.
      expect(updated.alpha, closeTo(8.5, 1e-9));
      expect(updated.beta, closeTo(4.5, 1e-9));
      expect(updated.lastTrigger, BrokenMapReason.revDeltaMissing);
    });

    test('prompted rev (#1621) — a confirmed rev scores the rev-delta',
        () async {
      // With an `awaitUserRev` callback the probe keys off the
      // confirmed rev instead of the blind 1.5 s window. A confirmed
      // rev behaves exactly like the broken-diesel case above: idle +
      // rev MAP are both read and folded into the belief.
      final port = _FakeObd2RawCommandPort(<String, List<String>>{
        '0111\r': [_resp(0x11, 3)],
        '010B\r': [_resp(0x0B, 98), _resp(0x0B, 99)],
      });

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: true,
        prior: const BrokenMapBelief(),
        now: fixedNow,
        awaitUserRev: () async => true,
      );

      expect(updated.lastTrigger, BrokenMapReason.revDeltaMissing);
      expect(updated.observationCount, 1);
      // Both the idle and the rev MAP read happened.
      expect(port.callCount['010B\r'], 2);
    });

    test('prompted rev (#1621) — a declined rev records no observation',
        () async {
      // The user dismissed / timed out the prompt: `awaitUserRev`
      // resolves false. An un-revved reading is meaningless, so the
      // probe must leave the belief untouched and never take the rev
      // MAP read.
      final port = _FakeObd2RawCommandPort(<String, List<String>>{
        '0111\r': [_resp(0x11, 3)],
        '010B\r': [_resp(0x0B, 98), _resp(0x0B, 99)],
      });
      const prior = BrokenMapBelief();

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: true,
        prior: prior,
        now: fixedNow,
        awaitUserRev: () async => false,
      );

      // Belief untouched — no observation folded in.
      expect(updated.observationCount, 0);
      expect(updated.alpha, prior.alpha);
      expect(updated.beta, prior.beta);
      // Only the idle MAP read ran — the rev read was skipped.
      expect(port.callCount['010B\r'], 1);
    });
  });

  group('BrokenMapDetector — gating + failure modes', () {
    test('TPS not closed (tps=12%) returns prior unchanged', () async {
      final port = _FakeObd2RawCommandPort.single({
        // 0x1F = 31 → 31 * 100/255 ≈ 12.16% — clearly above the 5%
        // closed-throttle gate.
        '0111\r': _resp(0x11, 31),
        '010B\r': _resp(0x0B, 99),
        '0133\r': _resp(0x33, 101),
      });
      const prior = BrokenMapBelief(
        alpha: 3,
        beta: 9,
        observationCount: 3,
        lastTrigger: BrokenMapReason.idleVacuumMissing,
      );

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: false,
        prior: prior,
        now: fixedNow,
      );

      // The detector must short-circuit before folding any observation,
      // so the entity is byte-for-byte identical to the input.
      expect(updated, equals(prior));
      expect(updated.observationCount, 3);
      // The detector must NOT have wasted bytes on the MAP / baro
      // reads after the gate failed.
      expect(port.callCount['010B\r'], isNull);
      expect(port.callCount['0133\r'], isNull);
    });

    test('malformed PID 0x0B response returns prior unchanged', () async {
      final port = _FakeObd2RawCommandPort.single({
        '0111\r': _resp(0x11, 3),
        // Wrong PID echo (claims 0x0C) — parser returns null.
        '010B\r': '41 0C 30\r>',
        '0133\r': _resp(0x33, 101),
      });
      const prior = BrokenMapBelief(alpha: 3, beta: 7, observationCount: 2);

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: false,
        prior: prior,
        now: fixedNow,
      );

      expect(updated, equals(prior));
    });

    test('empty response on PID 0x0B returns prior unchanged', () async {
      final port = _FakeObd2RawCommandPort.single({
        '0111\r': _resp(0x11, 3),
        '010B\r': '',
        '0133\r': _resp(0x33, 101),
      });
      const prior = BrokenMapBelief(alpha: 5, beta: 5, observationCount: 1);

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: false,
        prior: prior,
        now: fixedNow,
      );

      expect(updated, equals(prior));
    });

    test('throwing port returns prior unchanged', () async {
      const prior = BrokenMapBelief(alpha: 6, beta: 4, observationCount: 5);

      final updated = await const BrokenMapDetector().probe(
        _ThrowingPort(),
        isDiesel: false,
        prior: prior,
        now: fixedNow,
      );

      expect(updated, equals(prior));
    });

    test('malformed baro response on petrol path returns prior unchanged',
        () async {
      final port = _FakeObd2RawCommandPort.single({
        '0111\r': _resp(0x11, 3),
        '010B\r': _resp(0x0B, 99),
        // NO DATA on PID 0x33 — baro read fails, observation aborted.
        '0133\r': 'NO DATA\r>',
      });
      const prior = BrokenMapBelief();

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: false,
        prior: prior,
        now: fixedNow,
      );

      expect(updated, equals(prior));
    });
  });

  group('BrokenMapDetector — Bayesian folding mechanics', () {
    test(
        'two consecutive broken-MAP observations push the posterior past 0.9',
        () async {
      // Same broken-MAP fixture twice → score 1.0 each time.
      // After 1: α=8.5, β=4.5, mean ≈ 0.654.
      // After 2: α=0.5·8.5 + 8 = 12.25; β=0.5·4.5 + 0 = 2.25;
      //          mean = 12.25/14.5 ≈ 0.845.
      final port = _FakeObd2RawCommandPort.single({
        '0111\r': _resp(0x11, 3),
        '010B\r': _resp(0x0B, 99),
        '0133\r': _resp(0x33, 101),
      });

      const detector = BrokenMapDetector();
      final after1 = await detector.probe(
        port,
        isDiesel: false,
        prior: const BrokenMapBelief(),
        now: fixedNow,
      );
      final after2 = await detector.probe(
        port,
        isDiesel: false,
        prior: after1,
        now: fixedNow,
      );

      expect(after1.pointEstimate, closeTo(8.5 / 13.0, 1e-9));
      expect(after2.alpha, closeTo(12.25, 1e-9));
      expect(after2.beta, closeTo(2.25, 1e-9));
      expect(after2.pointEstimate, closeTo(12.25 / 14.5, 1e-9));
      expect(after2.observationCount, 2);
      expect(after2.lastTrigger, BrokenMapReason.idleVacuumMissing);
    });
  });
}
