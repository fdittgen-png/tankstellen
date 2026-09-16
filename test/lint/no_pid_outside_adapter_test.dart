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
/// This is a **ratchet**: the count is frozen and may only fall. The
/// migration moves one consumer at a time, and what makes each move safe
/// is not a device drive but the pins that landed before it — the exact
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
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Raw PID hex literals outside the adapter layer, per file.
///
/// Frozen 2026-09-14. **Only ever decreases.** A consumer that moves to
/// the normalized layer takes its entries with it.
const Map<String, int> _baseline = {
  'lib/features/obd2/data/session/obd2_fuel_rate_reader.dart': 18,
};

const _skipPrefixes = [
  'lib/features/obd2/data/protocol/',
  'lib/features/obd2/data/transport/',
];

final _pid = RegExp(r'0x[0-9A-Fa-f]{2}\b');

Map<String, int> _scan() {
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
      n += _pid.allMatches(line).length;
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
