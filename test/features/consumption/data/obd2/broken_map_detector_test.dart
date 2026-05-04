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

      // delta = 71 → vacuumMissingScore clamps to 0 → confidence stays
      // at 0 after one EMA fold (α × 0 + (1-α) × 0).
      expect(updated.confidence, closeTo(0.0, 1e-9));
      expect(updated.observationCount, 1);
      expect(updated.lastUpdate, fixedNow);
      // Weak observation — lastTrigger should NOT be set.
      expect(updated.lastTrigger, BrokenMapReason.none);
    });

    test(
        'broken MAP (mapIdle=99, baro=101, tps=1%) yields ~1.0 observation '
        'and confidence rises to ~0.4', () async {
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

      // delta = 2 → vacuumMissingScore clamps to 1.0 → confidence
      // jumps to α (0.4) on first observation.
      expect(updated.confidence, closeTo(0.4, 1e-9));
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
      // Confidence after one fold = α × 0.4666 ≈ 0.1866 — interior.
      expect(updated.confidence, greaterThan(0.4 * 0.4));
      expect(updated.confidence, lessThan(0.4 * 0.6));
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
      // After one fold from 0: α × 0.227 ≈ 0.091.
      expect(updated.confidence, lessThan(0.15));
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

      // |99 - 98| = 1 → score clamps to 1.0 → confidence jumps to α.
      expect(updated.confidence, closeTo(0.4, 1e-9));
      expect(updated.lastTrigger, BrokenMapReason.revDeltaMissing);
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
        confidence: 0.25,
        observationCount: 3,
        lastTrigger: BrokenMapReason.idleVacuumMissing,
      );

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: false,
        prior: prior,
        now: fixedNow,
      );

      // identical() is the strongest assertion the entity supports —
      // the detector must short-circuit before constructing a new
      // belief, so observationCount stays at 3 and confidence stays
      // at 0.25.
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
      const prior = BrokenMapBelief(confidence: 0.3, observationCount: 2);

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
      const prior = BrokenMapBelief(confidence: 0.5, observationCount: 1);

      final updated = await const BrokenMapDetector().probe(
        port,
        isDiesel: false,
        prior: prior,
        now: fixedNow,
      );

      expect(updated, equals(prior));
    });

    test('throwing port returns prior unchanged', () async {
      const prior = BrokenMapBelief(confidence: 0.6, observationCount: 5);

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

  group('BrokenMapDetector — EMA folding mechanics', () {
    test(
        'two consecutive broken-MAP observations fold per EMA recurrence',
        () async {
      // Same broken-MAP fixture twice → score 1.0 each time.
      // EMA: c0 = 0; c1 = 0.4 × 1 + 0.6 × 0 = 0.4;
      //                c2 = 0.4 × 1 + 0.6 × 0.4 = 0.64.
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

      expect(after1.confidence, closeTo(0.4, 1e-9));
      expect(after2.confidence, closeTo(0.64, 1e-9));
      expect(after2.observationCount, 2);
      expect(after2.lastTrigger, BrokenMapReason.idleVacuumMissing);
    });
  });
}
