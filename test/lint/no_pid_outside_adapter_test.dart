// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4159 — a PID number is meaningless above the adapter.
///
/// The target layering:
///
/// ```
/// Raw OBD2 frames
///       ↓  adapter — the ONLY place a PID number appears
/// Normalized VehicleTelemetry
///       ↓  units, provenance, freshness
/// Validated telemetry
///       ↓  plausibility, staleness
/// Derived metrics
///       ↓  load, efficiency, fuel rate
/// Driving analysis
/// ```
///
/// `PID 0C`, `PID 04`, `PID 10` should be meaningless outside
/// `data/protocol/`. Above it, code names a `VehicleSignal`
/// (`domain/vehicle_signal.dart`) and the adapter's table
/// (`data/protocol/obd2_signal_pids.dart`) turns the name into a PID, a
/// request and a support gate.
///
/// Since #4159 this is a **ban**: the baseline is empty. The migration
/// moved one consumer at a time, and what made each move safe was not a
/// device drive but the pins that landed before it — the exact
/// resolved schedule and gate calls
/// (`live_sample_snapshot_schedule_pin_test`), the measured-φ priority
/// rule (`precision_pid_latches_test`), the fuel-rate reader's gate/read
/// call log and the snapshot's read facade. A move that changes what a
/// session subscribes, asks or derives turns one of those red.
///
/// ## What is deliberately NOT counted
///
/// * `data/protocol/` — the adapter. PID constants belong there.
/// * `data/transport/` — byte-level ELM framing. `0x3E` is the `>`
///   prompt and `0x0D` is a carriage return; counting those would make
///   the number meaningless and teach everyone to ignore it.
/// * comment lines — a doc comment explaining which PID a value came
///   from is documentation, and removing those would make the code
///   worse, not better.
///
/// ## The second spelling: Mode 01 request strings
///
/// `0x0B` is not the only way to write a PID. `'010B\r'` is the same PID
/// as a request, and the hex-literal scan never saw it: when this check
/// was added (#4159) there were 13 such literals across
/// `domain/broken_map_detector.dart` and the self-test steps. They now
/// use the adapter's request constants, and the per-file baseline for
/// request strings is empty too (exact both ways, via `expectRatchet`).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'ratchet_baseline.dart';

/// Raw PID hex literals outside the adapter layer, per file.
///
/// Frozen 2026-09-14 at 38 across three files; empty since #4159. Never
/// add an entry — name the signal instead.
const Map<String, int> _baseline = {};

const _skipPrefixes = [
  'lib/features/obd2/data/protocol/',
  'lib/features/obd2/data/transport/',
];

final _pid = RegExp(r'0x[0-9A-Fa-f]{2}\b');

/// A quoted Mode 01 request: `'010C'`, `'010C\r'`, `"0133\r"`.
final _mode01Request = RegExp(r'''['"]01[0-9A-Fa-f]{2}(?:\\r)?['"]''');

/// Mode 01 request-string literals outside the adapter layer, per file.
/// Empty since #4159 (13 when first counted).
const Map<String, int> _requestBaseline = {};

Map<String, int> _scan([RegExp? pattern]) {
  final re = pattern ?? _pid;
  final counts = <String, int>{};
  for (final entity
      in Directory('lib/features/obd2').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    if (_skipPrefixes.any(path.startsWith)) continue;

    var n = 0;
    for (final line in entity.readAsLinesSync()) {
      final t = line.trim();
      if (t.startsWith('///') || t.startsWith('//')) continue;
      n += re.allMatches(line).length;
    }
    if (n > 0) counts[path] = n;
  }
  return counts;
}

void main() {
  test('no file gains raw PID literals outside the adapter layer (#4159)',
      () {
    final actual = _scan();
    final problems = <String>[];

    for (final entry in actual.entries) {
      final allowed = _baseline[entry.key] ?? 0;
      if (entry.value > allowed) {
        problems.add('  - ${entry.key}: ${entry.value} > baseline $allowed');
      }
    }

    expect(problems, isEmpty,
        reason: 'Raw PID hex above the adapter layer went UP:\n'
            '${problems.join('\n')}\n\n'
            'A PID number is an adapter detail. Add the signal to the '
            'normalized telemetry layer and consume it by name, so the '
            'next signal costs nothing to add (#4159, #3402).');
  });

  test('the baseline lists no file that is already clean', () {
    // A stale entry makes the debt look bigger than it is and hides a
    // real regression underneath the slack.
    final actual = _scan();
    final stale = _baseline.keys
        .where((p) => (actual[p] ?? 0) < (_baseline[p] ?? 0))
        .toList();
    expect(stale, isEmpty,
        reason: 'These files now carry FEWER raw PIDs than the baseline '
            'claims — lower it in the same commit, or the ratchet stops '
            'protecting the ground you just took: $stale');
  });

  test('request-string matcher finds quoted Mode 01 requests only', () {
    const sample = '''
      const a = '010B\\r';        // 1
      send("0133\\r");            // 2
      key('010C');                // 3
      const b = 'ATRV\\r';        // AT command, not a PID
      const c = '0100AB';         // longer token
      final d = '\$pid\\r';       // interpolated, not a literal
    ''';
    expect(_mode01Request.allMatches(sample), hasLength(3));
  });

  test('no file gains Mode 01 request strings outside the adapter (#4159)',
      () {
    expectRatchet(
      measured: _scan(_mode01Request),
      baseline: _requestBaseline,
      what: 'Mode 01 request-string literals above the adapter layer',
      hint: 'A request string is a PID in another spelling. Use '
          'Obd2SignalPids.commandOf(VehicleSignal.x) or the '
          'Elm327Commands constant (#4159).',
    );
  });

  test('the adapter layer is where PIDs live, and it is not empty', () {
    // The other direction: if `data/protocol/` ever stops containing PID
    // constants, they did not disappear — they moved somewhere worse.
    final protocol = Directory('lib/features/obd2/data/protocol')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final total = protocol.fold<int>(
      0,
      (sum, f) => sum + _pid.allMatches(f.readAsStringSync()).length,
    );
    expect(total, greaterThan(20),
        reason: 'the adapter layer has almost no PID constants left — '
            'they moved up rather than being normalized away');
  });
}
