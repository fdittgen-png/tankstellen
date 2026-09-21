// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

/// One observed phase change.
typedef PhaseEdge = (TripRecordingPhase from, TripRecordingPhase to);

/// Phase changes the app is KNOWN to make although
/// [kTripRecordingTransitions] forbids them (#4162).
///
/// Each entry is a filed defect, and the fix removes it. This set may only
/// SHRINK — [kKnownIllegalEdgesCeiling] pins its size, and the transitions
/// test fails if the set outgrows it. Adding an edge here to make a trace
/// pass is exactly what the ceiling exists to refuse: fix the writer.
const Set<PhaseEdge> kKnownIllegalEdges = {
};

/// The size [kKnownIllegalEdges] may never exceed. Lower it with every fix.
const int kKnownIllegalEdgesCeiling = 0;

/// Records every phase change a [ProviderContainer]'s recording makes.
class PhaseTrace {
  PhaseTrace(ProviderContainer container) {
    _sub = container.listen<TripRecordingPhase>(
      tripRecordingProvider.select((s) => s.phase),
      (previous, next) {
        if (previous != null && previous != next) edges.add((previous, next));
      },
    );
  }

  late final ProviderSubscription<TripRecordingPhase> _sub;

  final List<PhaseEdge> edges = [];

  /// Every observed change the table does not allow.
  List<PhaseEdge> get illegal => [
        for (final e in edges)
          if (!isTripRecordingTransition(e.$1, e.$2)) e,
      ];

  bool saw(TripRecordingPhase from, TripRecordingPhase to) =>
      edges.contains((from, to));

  /// Fails on any illegal change that is not a known, filed defect.
  void expectLawful() {
    final unexplained = [
      for (final e in illegal)
        if (!kKnownIllegalEdges.contains(e)) e,
    ];
    expect(unexplained, isEmpty,
        reason: 'phase changes outside kTripRecordingTransitions: '
            '${unexplained.map((e) => '${e.$1.name}→${e.$2.name}').join(', ')}'
            ' (whole trace: ${edges.map((e) => '${e.$1.name}→${e.$2.name}').join(', ')})');
  }

  void close() => _sub.close();
}
