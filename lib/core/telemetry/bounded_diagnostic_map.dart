// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Bounded traversal for PiiScrubber's diagnostic policy. It never stringifies
/// unknown objects or mutates input. Policy remains with the supplied scrubbers.
Map<String, dynamic> scrubBoundedDiagnosticMap(
  Map<dynamic, dynamic> raw, {
  required Object? Function(List<String> path, Object? value) scrubField,
  required String Function(String key) scrubKey,
  required int maxValues,
  required int maxDepth,
  required int maxTextLength,
  required int maxTotalTextLength,
  required String omittedMarker,
  required String truncatedMarker,
}) {
  var remaining = maxValues;
  var textRemaining = maxTotalTextLength;
  var omitted = false;
  final path = <String>[];
  Object? walk(Object? value, int depth) {
    if (--remaining < 0 || depth > maxDepth) {
      omitted = true;
      return omittedMarker;
    }
    if (value is String) {
      if (value.length > maxTextLength || value.length > textRemaining) {
        omitted = true;
        return truncatedMarker;
      }
      textRemaining -= value.length;
    }
    final safe = scrubField(path, value);
    if (safe is String) {
      if (safe == omittedMarker || safe == truncatedMarker) omitted = true;
      return safe;
    }
    if (safe is Map) {
      final result = <String, dynamic>{};
      for (final entry in safe.entries) {
        if (--remaining < 0) {
          omitted = true;
          break;
        }
        final name = entry.key;
        if (name is! String || name.length > 128) {
          omitted = true;
          continue;
        }
        if (name.length > textRemaining) {
          omitted = true;
          break;
        }
        textRemaining -= name.length;
        final safeName = scrubKey(name);
        if (result.containsKey(safeName)) {
          omitted = true;
          continue;
        }
        path.add(name);
        result[safeName] = walk(entry.value, depth + 1);
        path.removeLast();
      }
      return result;
    }
    if (safe is List) {
      final result = <dynamic>[];
      for (final item in safe) {
        if (remaining <= 0) {
          omitted = true;
          break;
        }
        path.add('*');
        result.add(walk(item, depth + 1));
        path.removeLast();
      }
      return result;
    }
    if (safe == null || safe is bool || safe is num && safe.isFinite) {
      return safe;
    }
    omitted = true;
    return omittedMarker;
  }

  final result = walk(raw, 0) as Map<String, dynamic>;
  if (omitted) result['_diagnosticOmitted'] = true;
  return result;
}
