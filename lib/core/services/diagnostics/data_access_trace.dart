// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'data_access_event.dart';

/// A self-contained, JSON-serialisable snapshot of every recorded data-layer
/// access plus the per-provider compliance aggregates (#2824).
///
/// Mirrors the OCR trace package (#2517) and the driving-analysis trace
/// (#2804): pure Dart, hand-written `toJson`, `schema` versioned. The
/// maintainer exports this from Developer tools, optionally annotates the
/// [comment], and reads back the cache-hit ratio + the inter-request interval
/// per `country|source` to verify each provider's amount + frequency
/// rate-limit policy is respected.
class DataAccessTrace {
  /// Serialisation schema version. Bump when a field's meaning changes.
  static const int schema = 1;

  final DateTime capturedAt;

  /// Free-text annotation slot — defaults to a prompt so the exported file
  /// invites context (which screen / scenario produced this trace).
  final String comment;

  /// Every recorded access, oldest-first (the recorder's ring-buffer order).
  final List<DataAccessEvent> events;

  /// The configured minimum inter-request interval (seconds) per country —
  /// the policy budget each provider's observed interval is checked against.
  /// Keyed by ISO country code.
  final Map<String, double> configuredMinIntervalSec;

  const DataAccessTrace({
    required this.capturedAt,
    required this.events,
    this.configuredMinIntervalSec = const {},
    this.comment = kDataAccessCommentPrompt,
  });

  /// Per-`country|source` aggregates computed from [events] (#2824).
  ///
  /// Groups events by a stable `country|source` key (so the same source under
  /// two countries, or two sources under one country, stay separate), then for
  /// each group computes:
  ///
  ///  - `requestCount`  — total accesses in the group,
  ///  - `networkCount`  — how many were live upstream requests,
  ///  - `cacheHitRatio` — `1 - networkCount / requestCount` (0 when empty),
  ///  - `networkIntervalsSec` — gaps between CONSECUTIVE network events only
  ///    (monotonic-micros delta ÷ 1e6), the spacing a provider's frequency
  ///    policy governs,
  ///  - `minNetworkIntervalSec` / `medianNetworkIntervalSec` — over those gaps
  ///    (null when fewer than two network events: no gap to measure),
  ///  - `configuredMinIntervalSec` — the policy budget for the group's country
  ///    (null when no policy was noted),
  ///  - `compliant` — `minNetworkIntervalSec >= configuredMinIntervalSec`
  ///    (null when either input is null — nothing to judge).
  List<DataAccessAggregate> aggregates() {
    // Preserve first-seen group order for a stable, diff-friendly export.
    final order = <String>[];
    final byKey = <String, List<DataAccessEvent>>{};
    for (final e in events) {
      final key = '${e.country}|${e.source}';
      final group = byKey[key];
      if (group == null) {
        order.add(key);
        byKey[key] = [e];
      } else {
        group.add(e);
      }
    }

    final result = <DataAccessAggregate>[];
    for (final key in order) {
      final group = byKey[key]!;
      final country = group.first.country;
      final source = group.first.source;
      final networkMicros = [
        for (final e in group)
          if (e.isNetwork) e.monotonicMicros,
      ];

      final intervals = <double>[];
      for (var i = 1; i < networkMicros.length; i++) {
        intervals.add((networkMicros[i] - networkMicros[i - 1]) / 1e6);
      }

      final configured = configuredMinIntervalSec[country];
      final minInterval = intervals.isEmpty ? null : _min(intervals);
      final compliant = (minInterval == null || configured == null)
          ? null
          : minInterval >= configured;

      result.add(DataAccessAggregate(
        country: country,
        source: source,
        requestCount: group.length,
        networkCount: networkMicros.length,
        cacheHitRatio: group.isEmpty
            ? 0
            : 1 - networkMicros.length / group.length,
        networkIntervalsSec: intervals,
        minNetworkIntervalSec: minInterval,
        medianNetworkIntervalSec:
            intervals.isEmpty ? null : _median(intervals),
        configuredMinIntervalSec: configured,
        compliant: compliant,
      ));
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'kind': 'dataAccess',
        'capturedAt': capturedAt.toIso8601String(),
        // The annotation slot — first so it is obvious in the shared file.
        'comment': comment,
        'aggregates': [for (final a in aggregates()) a.toJson()],
        'events': [for (final e in events) e.toJson()],
      };

  static double _min(List<double> xs) =>
      xs.reduce((a, b) => a < b ? a : b);

  static double _median(List<double> xs) {
    final sorted = [...xs]..sort();
    final n = sorted.length;
    if (n.isOdd) return sorted[n ~/ 2];
    return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
  }
}

/// One per-`country|source` compliance row of a [DataAccessTrace] (#2824).
class DataAccessAggregate {
  final String country;
  final String source;
  final int requestCount;
  final int networkCount;
  final double cacheHitRatio;
  final List<double> networkIntervalsSec;
  final double? minNetworkIntervalSec;
  final double? medianNetworkIntervalSec;
  final double? configuredMinIntervalSec;

  /// `minNetworkIntervalSec >= configuredMinIntervalSec`, or null when there
  /// is no policy or no measurable interval to judge.
  final bool? compliant;

  const DataAccessAggregate({
    required this.country,
    required this.source,
    required this.requestCount,
    required this.networkCount,
    required this.cacheHitRatio,
    required this.networkIntervalsSec,
    required this.minNetworkIntervalSec,
    required this.medianNetworkIntervalSec,
    required this.configuredMinIntervalSec,
    required this.compliant,
  });

  Map<String, dynamic> toJson() => {
        'country': country,
        'source': source,
        'requestCount': requestCount,
        'networkCount': networkCount,
        'cacheHitRatio': cacheHitRatio,
        'minNetworkIntervalSec': minNetworkIntervalSec,
        'medianNetworkIntervalSec': medianNetworkIntervalSec,
        'configuredMinIntervalSec': configuredMinIntervalSec,
        'compliant': compliant,
      };
}

/// Default [DataAccessTrace.comment] — a prompt inviting the maintainer to
/// note the scenario so the export is self-explanatory when shared back.
const String kDataAccessCommentPrompt =
    'CONTEXT HERE → which screen / scenario produced this trace '
    '(cold start, a search, favorites refresh, a live trip), so the '
    'cache-hit ratio and the per-provider request intervals can be read '
    'against the right usage.';

/// Pretty-prints a [DataAccessTrace] as indented JSON (mirrors
/// `formatDrivingAnalysisTraceJson`).
String formatDataAccessTraceJson(DataAccessTrace trace) =>
    const JsonEncoder.withIndent('  ').convert(trace.toJson());
