// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/gps_sample_diagnostic.dart';

/// Read-only inspector card for the GPS sample diagnostics captured
/// during a trip recording (#1458 phase 2.5).
///
/// Phase 2 of #1458 captured a [GpsSampleDiagnostic] per position fix
/// with a wall-clock timestamp + the host app's lifecycle state at the
/// time of the fix. Phase 2.5 surfaces those samples on the trip-detail
/// screen so the user can verify GPS sampling cadence under phone-sleep
/// conditions WITHOUT inspecting the persisted Hive JSON. The output of
/// this card is the input to the phase-3 decision: if the median
/// interval, gap count, and lifecycle-state breakdown look healthy, we
/// can ship without an Android foreground service; otherwise phase 3 is
/// required.
///
/// The card collapses by default — trip detail is already busy with the
/// summary, map, insights, score, histogram and four time-series
/// charts. The collapsed header gives an at-a-glance triple
/// ("`samples · timeSpan · gapCount`") and the expanded body surfaces
/// the full breakdown the user actually clicks for.
///
/// The card is purely presentational — all gap / median / lifecycle
/// math lives in the top-level [computeGpsDiagnosticsSummary] helper so
/// tests can assert on the math without pumping a widget tree.
class GpsDiagnosticsCard extends StatelessWidget {
  final List<GpsSampleDiagnostic> diagnostics;

  const GpsDiagnosticsCard({super.key, required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = computeGpsDiagnosticsSummary(diagnostics);

    final title = l.gpsDiagnosticsTitle;
    final headerLine = l.gpsDiagnosticsHeader(
      summary.sampleCount.toString(),
      _formatDuration(summary.timeSpan),
      summary.gapCount,
    );
    final cadenceLine = l.gpsDiagnosticsCadence(summary.medianIntervalMs);
    final explainLine = l.gpsDiagnosticsExplain;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: ExpansionTile(
        // Locks down a stable selector for widget tests.
        key: const Key('gps_diagnostics_tile'),
        // Collapsed by default — the user opts in to the detail.
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(
          headerLine,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(cadenceLine, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              _formatLifecycleBreakdown(summary.lifecyclePercent, l),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l.gpsDiagnosticsLargestGap(summary.largestGap.inSeconds),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            explainLine,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pure-function aggregate produced by [computeGpsDiagnosticsSummary].
///
/// Holds everything the card needs to render — kept as a value type
/// (with `==` / `hashCode`) so tests can assert on a single equality
/// check rather than reaching into many fields.
@immutable
class GpsDiagnosticsSummary {
  /// Total number of [GpsSampleDiagnostic] records in the trip.
  final int sampleCount;

  /// Wall-clock duration between the FIRST and the LAST diagnostic.
  /// [Duration.zero] when [sampleCount] is 0 or 1.
  final Duration timeSpan;

  /// Median sample-to-sample interval in milliseconds, rounded to the
  /// nearest 100 ms (per the issue's "rounded to 100 ms" instruction).
  /// 0 when there are fewer than two diagnostics.
  final int medianIntervalMs;

  /// Map from a lifecycle-state name (e.g. `'resumed'`) to its
  /// percentage of the total sample count, rounded to the nearest
  /// integer. The percentages may not sum to exactly 100 due to
  /// rounding — the card's display copy is "92% · 5% · 3%" style and
  /// readers don't expect a strict total.
  final Map<String, int> lifecyclePercent;

  /// Number of intervals whose delta exceeded `3 × medianInterval`
  /// (heuristic threshold for a "GPS-throttled" gap). 0 when there
  /// are fewer than two diagnostics or no median exists.
  final int gapCount;

  /// Largest interval observed across the whole trip. [Duration.zero]
  /// when there are fewer than two diagnostics.
  final Duration largestGap;

  const GpsDiagnosticsSummary({
    required this.sampleCount,
    required this.timeSpan,
    required this.medianIntervalMs,
    required this.lifecyclePercent,
    required this.gapCount,
    required this.largestGap,
  });

  /// Stable empty value — used by the helper for empty / single-sample
  /// inputs and by tests that want to assert the empty shape.
  static const GpsDiagnosticsSummary empty = GpsDiagnosticsSummary(
    sampleCount: 0,
    timeSpan: Duration.zero,
    medianIntervalMs: 0,
    lifecyclePercent: <String, int>{},
    gapCount: 0,
    largestGap: Duration.zero,
  );

  @override
  bool operator ==(Object other) {
    if (other is! GpsDiagnosticsSummary) return false;
    if (other.sampleCount != sampleCount) return false;
    if (other.timeSpan != timeSpan) return false;
    if (other.medianIntervalMs != medianIntervalMs) return false;
    if (other.gapCount != gapCount) return false;
    if (other.largestGap != largestGap) return false;
    if (other.lifecyclePercent.length != lifecyclePercent.length) return false;
    for (final entry in lifecyclePercent.entries) {
      if (other.lifecyclePercent[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    sampleCount,
    timeSpan,
    medianIntervalMs,
    gapCount,
    largestGap,
    Object.hashAllUnordered(
      lifecyclePercent.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

/// Compute the read-only diagnostic summary for a list of GPS sample
/// diagnostics (#1458 phase 2.5).
///
/// Pure — does not allocate any platform handles, does not depend on
/// the framework, safe to call from a unit test or a build method.
///
/// Heuristics:
///   * Median interval is computed across consecutive sample deltas
///     (sorted, mid-element on odd / average on even, like a textbook
///     median). Rounded to the nearest 100 ms so the displayed value
///     looks like a real cadence ("1000 ms") rather than a noisy
///     timestamp diff ("1023 ms").
///   * A "gap" is an interval whose delta is at least `3 × median`.
///     `3×` lands somewhere between Android's typical 1 Hz cadence
///     during normal sampling and the > 5 s pauses we see when the
///     OS throttles the GPS stream during sleep — a coarse but useful
///     signal for "did the OS throttle this trip?".
///   * Lifecycle percentages are rounded to the nearest integer; the
///     map preserves insertion order via [Map.toList] sort by count
///     desc so the largest state shows up first when iterated.
@visibleForTesting
GpsDiagnosticsSummary computeGpsDiagnosticsSummary(
  List<GpsSampleDiagnostic> diagnostics,
) {
  if (diagnostics.isEmpty) return GpsDiagnosticsSummary.empty;
  if (diagnostics.length == 1) {
    return GpsDiagnosticsSummary(
      sampleCount: 1,
      timeSpan: Duration.zero,
      medianIntervalMs: 0,
      lifecyclePercent: <String, int>{diagnostics.first.lifecycleState: 100},
      gapCount: 0,
      largestGap: Duration.zero,
    );
  }

  // Defensive copy + sort by timestamp — the recorder appends in
  // arrival order which is normally already monotonic, but a clock
  // adjustment mid-trip would technically violate that and this
  // helper is meant to be safe against malformed inputs.
  final sorted = [...diagnostics]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final timeSpan = sorted.last.timestamp.difference(sorted.first.timestamp);

  // Per-interval deltas in milliseconds.
  final intervals = <int>[];
  for (var i = 1; i < sorted.length; i++) {
    final ms = sorted[i].timestamp
        .difference(sorted[i - 1].timestamp)
        .inMilliseconds;
    // Defensive clamp: backwards-clock anomalies become 0 rather than
    // contaminating the median.
    intervals.add(ms < 0 ? 0 : ms);
  }

  // Median (textbook).
  final sortedIntervals = [...intervals]..sort();
  final n = sortedIntervals.length;
  final medianRaw = n.isOdd
      ? sortedIntervals[n ~/ 2].toDouble()
      : (sortedIntervals[(n ~/ 2) - 1] + sortedIntervals[n ~/ 2]) / 2.0;
  // Round to nearest 100 ms.
  final medianMs = ((medianRaw / 100).round()) * 100;

  // Largest gap.
  final largestMs = sortedIntervals.last;

  // Gap count: intervals at least 3× the (un-rounded) median. We use
  // the un-rounded median here so a tiny rounding step doesn't flip a
  // borderline interval in or out of the count.
  final gapThreshold = medianRaw * 3;
  // When the median is 0 (all samples on the same millisecond — degenerate
  // input), gaps are not a meaningful signal, so report 0.
  final gapCount = medianRaw == 0
      ? 0
      : intervals.where((d) => d >= gapThreshold).length;

  // Lifecycle breakdown.
  final lifecycleCounts = <String, int>{};
  for (final d in sorted) {
    lifecycleCounts[d.lifecycleState] =
        (lifecycleCounts[d.lifecycleState] ?? 0) + 1;
  }
  final total = sorted.length;
  // Sort entries by count desc so the dominant state renders first.
  final orderedEntries = lifecycleCounts.entries.toList(growable: false)
    ..sort((a, b) => b.value.compareTo(a.value));
  final lifecyclePercent = <String, int>{};
  for (final e in orderedEntries) {
    lifecyclePercent[e.key] = ((e.value / total) * 100).round();
  }

  return GpsDiagnosticsSummary(
    sampleCount: total,
    timeSpan: timeSpan,
    medianIntervalMs: medianMs,
    lifecyclePercent: lifecyclePercent,
    gapCount: gapCount,
    largestGap: Duration(milliseconds: largestMs),
  );
}

/// Format a duration into "Hh Mmin" (e.g. "1h 23min", "12min", "0min").
/// Hours are dropped when zero so short trips don't read "0h 12min".
String _formatDuration(Duration d) {
  if (d == Duration.zero) return '0min';
  final hours = d.inHours;
  final minutes = d.inMinutes - hours * 60;
  if (hours == 0) return '${minutes}min';
  return '${hours}h ${minutes}min';
}

/// Format the lifecycle-percent map into a "Resumed 92% · Paused 5% · …"
/// line. The map is already sorted by count desc by the helper. Each
/// lifecycle key is mapped to a localized label via [_lifecycleLabel];
/// without this the raw enum keys ("resumed"/"inactive"/"paused") leaked
/// onto every non-English locale (#2765).
String _formatLifecycleBreakdown(
  Map<String, int> lifecyclePercent,
  AppLocalizations l,
) {
  if (lifecyclePercent.isEmpty) return '';
  return lifecyclePercent.entries
      .map((e) => '${_lifecycleLabel(e.key, l)} ${e.value}%')
      .join(' · ');
}

/// Map a raw [AppLifecycleState]-derived key (e.g. `'resumed'`,
/// `'paused'`, `'inactive'`) to its localized label (#2765). Unknown
/// keys fall back to the raw key so a future lifecycle value never
/// renders as a blank — but the three states the recorder actually
/// captures are all covered.
String _lifecycleLabel(String key, AppLocalizations l) {
  switch (key) {
    case 'resumed':
      return l.gpsLifecycleResumed;
    case 'paused':
      return l.gpsLifecyclePaused;
    case 'inactive':
      return l.gpsLifecycleInactive;
    default:
      return key;
  }
}
