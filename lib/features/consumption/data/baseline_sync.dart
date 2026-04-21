/// Per-situation merge helpers for syncing OBD2 baselines (#780).
///
/// Baseline payloads shape (as produced by [BaselineStore.flush]):
/// ```json
/// {
///   "version": 1,
///   "perSituation": {
///     "highwayCruise": {"n": 123, "mean": 6.5, "m2": 2.3},
///     "urbanCruise":   {"n": 45,  "mean": 8.2, "m2": 4.1}
///   }
/// }
/// ```
///
/// Merge rule: for each situation, pick the accumulator with the
/// higher `n`. A device that drove more of that situation knows
/// more — merging the raw Welford moments across devices would be
/// numerically fine but requires shared samples, which we don't
/// have. "Prefer more experience" is a safe, intuitive fallback.
library;

import 'dart:convert';

/// Merge [local] and [server] baseline payloads per-situation. Both
/// inputs are JSON-decoded maps with the shape above. Missing
/// payloads (null) are treated as empty. Returns a brand-new map
/// ready to be persisted locally and uploaded back to the server.
Map<String, dynamic> mergeBaselinePayloads(
  Map<String, dynamic>? local,
  Map<String, dynamic>? server,
) {
  final localSit = _extractPerSituation(local);
  final serverSit = _extractPerSituation(server);
  final keys = {...localSit.keys, ...serverSit.keys};

  final mergedSituations = <String, dynamic>{};
  for (final key in keys) {
    final l = localSit[key];
    final s = serverSit[key];
    mergedSituations[key] = _pickHigherN(l, s);
  }

  return {
    'version': 1,
    'perSituation': mergedSituations,
  };
}

/// Total sample count summed across every situation. Exposed so the
/// sync client can populate the `total_samples` column without
/// re-summing in two places.
int totalSampleCount(Map<String, dynamic> payload) {
  final perSit = _extractPerSituation(payload);
  var total = 0;
  for (final acc in perSit.values) {
    final n = acc['n'];
    // `int` is a `num`, so check the specific type first and bail.
    if (n is int) {
      total += n;
    } else if (n is num) {
      total += n.toInt();
    }
  }
  return total;
}

/// Convenience for callers that already hold the JSON string form
/// that [BaselineStore] writes to Hive. Decodes, merges, re-encodes.
/// Returns null when both inputs are null/empty.
String? mergeBaselineJson(String? localJson, String? serverJson) {
  final local = _tryDecode(localJson);
  final server = _tryDecode(serverJson);
  if (local == null && server == null) return null;
  final merged = mergeBaselinePayloads(local, server);
  return jsonEncode(merged);
}

Map<String, dynamic>? _tryDecode(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    // Fall through — caller treats as null.
  }
  return null;
}

Map<String, Map<String, dynamic>> _extractPerSituation(
  Map<String, dynamic>? payload,
) {
  if (payload == null) return const {};
  final raw = payload['perSituation'];
  if (raw is! Map) return const {};
  final out = <String, Map<String, dynamic>>{};
  raw.forEach((k, v) {
    if (k is String && v is Map) {
      out[k] = Map<String, dynamic>.from(v);
    }
  });
  return out;
}

Map<String, dynamic> _pickHigherN(
  Map<String, dynamic>? a,
  Map<String, dynamic>? b,
) {
  if (a == null) return b!;
  if (b == null) return a;
  final an = _readN(a);
  final bn = _readN(b);
  // Ties go to local (a) so the caller's own state is the tiebreaker
  // — a device's latest in-memory values shouldn't be silently
  // overwritten by an equally-aged server copy.
  return an >= bn ? a : b;
}

int _readN(Map<String, dynamic> acc) {
  final n = acc['n'];
  if (n is int) return n;
  if (n is num) return n.toInt();
  return 0;
}
