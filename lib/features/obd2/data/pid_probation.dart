// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'obd2_response_class.dart';

/// #3532 (Epic #3527) — per-connection runtime PID probation.
///
/// The one place that decides a PID is genuinely unanswered: a PID
/// enters probation only after [threshold] consecutive REAL `NO DATA`
/// replies; any parsed reply clears the streak and lifts an existing
/// probation (the regain path for flaky ECUs). Timeouts, garbage and
/// bus errors are link weather — they count for nothing. The
/// [SupportedPidsResolver] owns one instance per connection and clears
/// it in `resetForNewConnection`.
class PidProbation {
  PidProbation({this.threshold = 3});

  /// Consecutive REAL `NO DATA` replies a PID must return at runtime
  /// before it is parked. Three mirrors the scheduler's #2379 backoff
  /// threshold: one flaky reply never parks a PID.
  final int threshold;

  final Map<int, int> _consecutiveNoData = <int, int>{};
  final Set<int> _parked = <int>{};

  /// Whether [pid] is parked.
  bool contains(int pid) => _parked.contains(pid);

  /// Parked PIDs (diagnostics view). Unmodifiable.
  Set<int> get parked => Set.unmodifiable(_parked);

  /// Forget everything — a new session retries every parked PID.
  void reset() {
    _consecutiveNoData.clear();
    _parked.clear();
  }

  /// Feed one runtime mode-01 reply. [parsed] is whether the caller's
  /// parser extracted a value from [raw].
  void noteReply(String command, String raw, {required bool parsed}) {
    final pid = pidOfMode01Command(command);
    if (pid == null) return;
    if (parsed) {
      _consecutiveNoData.remove(pid);
      _parked.remove(pid);
      return;
    }
    if (classifyObd2Response(raw) != ResponseClass.noData) return;
    final streak = (_consecutiveNoData[pid] ?? 0) + 1;
    _consecutiveNoData[pid] = streak;
    if (streak >= threshold && _parked.add(pid)) {
      // Surfaced in the diagnostic export: a probation is the honest
      // "this car doesn't answer that PID" record the old hard intersect
      // used to fake from the (often under-reported) 0100 bitmap.
      BreadcrumbCollector.add(
        'OBD2 PID probation',
        detail:
            '0x${pid.toRadixString(16).padLeft(2, '0')} after $streak× NO DATA',
      );
    }
  }

  /// Parse the PID out of a single-PID mode-01 [command] (`010C`,
  /// `01 0C`, `010C\r` — the shared constants carry a trailing CR);
  /// null for anything else (multi-PID, other modes, AT).
  static int? pidOfMode01Command(String command) {
    final c = command.trim().replaceAll(' ', '').toUpperCase();
    if (c.length != 4 || !c.startsWith('01')) return null;
    return int.tryParse(c.substring(2), radix: 16);
  }
}
