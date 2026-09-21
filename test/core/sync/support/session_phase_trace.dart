// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/tanksync_session_gate.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

/// One observed phase change.
typedef SessionEdge = (TankSyncSessionPhase from, TankSyncSessionPhase to);

/// Session anomalies the app is KNOWN to produce although the table and
/// the invariants forbid them (#4162). Each element is either a
/// [SessionEdge] or a [SessionInvariant], and each is a filed defect the
/// fix removes. The three this started with — #4336 (a disconnect kept
/// the old backend's client), #4337 (setup and uploads without consent, a
/// withdrawal leaving the client live) and #4338 (a lost session nobody
/// flagged) — are fixed, so it is empty.
///
/// This set may only SHRINK — [kKnownSessionAnomaliesCeiling] pins its
/// size. Adding an entry to make a trace pass is exactly what the ceiling
/// exists to refuse: fix the writer.
const Set<Object> kKnownSessionAnomalies = {};

/// The size [kKnownSessionAnomalies] may never exceed. Lower it with every
/// fix.
const int kKnownSessionAnomaliesCeiling = 0;

/// Records every observation [TankSyncSessionGate.instance] makes.
class SessionPhaseTrace {
  SessionPhaseTrace([TankSyncSessionGate? gate])
      : _gate = gate ?? TankSyncSessionGate.instance {
    _gate.debugTap = observations.add;
  }

  final TankSyncSessionGate _gate;

  final List<SessionObservation> observations = [];

  /// The lawful phase changes, in order.
  List<SessionEdge> get edges => [
        for (final o in observations)
          if (o.broken.isEmpty && o.from != null && o.from != o.phase)
            (o.from!, o.phase),
      ];

  /// The phases the lawful observations went through, repeats collapsed.
  List<TankSyncSessionPhase> get phases {
    final out = <TankSyncSessionPhase>[];
    for (final o in observations) {
      if (o.broken.isNotEmpty) continue;
      if (out.isEmpty || out.last != o.phase) out.add(o.phase);
    }
    return out;
  }

  TankSyncSessionPhase? get last =>
      observations.isEmpty ? null : observations.last.phase;

  /// Every anomaly: illegal edges and broken invariants.
  List<Object> get anomalies => [
        for (final o in observations) ...[
          ...o.broken,
          if (o.broken.isEmpty &&
              o.from != null &&
              !isTankSyncSessionTransition(o.from!, o.phase))
            (o.from!, o.phase),
        ],
      ];

  bool saw(Object anomaly) => anomalies.contains(anomaly);

  /// Fails on any anomaly that is not a known, filed defect.
  void expectLawful() {
    final unexplained = [
      for (final a in anomalies)
        if (!kKnownSessionAnomalies.contains(a)) a,
    ];
    expect(unexplained, isEmpty,
        reason: 'session anomalies outside kKnownSessionAnomalies: '
            '${unexplained.map(describe).join(', ')}\n$transcript');
  }

  /// Fails unless no anomaly at all was observed.
  void expectClean() {
    expect(anomalies, isEmpty,
        reason: 'anomalies: ${anomalies.map(describe).join(', ')}\n'
            '$transcript');
  }

  String get transcript => [
        for (final o in observations) _line(o),
      ].join('\n');

  static String _line(SessionObservation o) {
    final broke = o.broken.isEmpty
        ? ''
        : ' BROKE ${o.broken.map((i) => i.name).join('+')}';
    return '  ${o.cause}: ${o.phase.name}$broke';
  }

  static String describe(Object anomaly) => switch (anomaly) {
        (final TankSyncSessionPhase from, final TankSyncSessionPhase to) =>
          '${from.name}→${to.name}',
        final SessionInvariant i => i.name,
        _ => '$anomaly',
      };

  void close() => _gate.debugTap = null;
}
