// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';

/// How many fill-ups at one station before it is worth OFFERING as the
/// usual one (#4154). Two could be a holiday; three is a habit.
const int kUsualStationMinFills = 3;

/// A station the fill-up history suggests, with the evidence behind it.
@immutable
class UsualStationCandidate {
  const UsualStationCandidate({
    required this.stationId,
    required this.fills,
    this.stationName,
  });

  final String stationId;
  final String? stationName;

  /// Fill-ups recorded at this station — the evidence the user confirms.
  final int fills;
}

/// The station most fill-ups happened at, or null when the history is too
/// thin to suggest one (#4154). Pure: the caller passes the fill-ups it
/// already has, and NOTHING is applied without confirmation.
UsualStationCandidate? usualStationCandidate(
  Iterable<({String? stationId, String? stationName})> fills, {
  int minFills = kUsualStationMinFills,
}) {
  final counts = <String, int>{};
  final names = <String, String>{};
  for (final f in fills) {
    final id = f.stationId;
    if (id == null || id.isEmpty) continue;
    counts[id] = (counts[id] ?? 0) + 1;
    final name = f.stationName;
    if (name != null && name.isNotEmpty) names[id] = name;
  }
  if (counts.isEmpty) return null;
  final best = counts.entries.reduce((a, b) {
    if (b.value != a.value) return b.value > a.value ? b : a;
    // Deterministic tie-break so the same history always suggests the
    // same station (a suggestion that moves on every rebuild is noise).
    return a.key.compareTo(b.key) <= 0 ? a : b;
  });
  if (best.value < minFills) return null;
  return UsualStationCandidate(
    stationId: best.key,
    stationName: names[best.key],
    fills: best.value,
  );
}
