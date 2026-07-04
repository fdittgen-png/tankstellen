// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/location/recording_location_settings.dart';
import 'entities/recording_lifecycle_mark.dart';
import 'gps_track_distance.dart';
import 'trip_sample.dart';

/// Why a stretch of the recorded GPS track has no fixes (#3465).
///
/// A field report of "my trace has holes" was previously unanswerable per
/// trip: the causes were known in aggregate (#3253 tallies, #1458 cadence
/// diagnostics) but never JOINED to the individual gap. Each gap in a
/// [GpsCoverageReport] carries one of these verdicts.
enum GpsGapAttribution {
  /// The gap majority-overlaps a backgrounded stretch of the trip AND the
  /// build ships without the recording foreground service
  /// (`kGpsRecordingForegroundServiceEnabled` off, #3417 pending) — the
  /// OS batched/paused the backgrounded stream. The dominant field cause.
  backgroundThrottle,

  /// A burst of tightly-spaced fixes right after the gap carries roughly
  /// the fixes that should have been spread across it — the OS queued
  /// fixes and delivered them late in one batch (#3253 fix-clock
  /// stamping makes the late delivery visible).
  osBatching,

  /// The gap is flanked by link-down samples on an OBD2 trip (RPM null on
  /// both sides while most of the trip carries RPM): GPS ingest stalled
  /// while an OBD2 reconnect episode monopolised the UI isolate /
  /// serialized transport — the field-observed foreground-gap correlate
  /// (flapping link, one connect cycle every ~9 s).
  linkRecovery,

  /// The #2963/#1979/#3004 distance gates rejected enough fixes/segments
  /// (per the trip's [GpsGateRejectionTally]) to account for the fixes
  /// missing from this gap.
  gateRejected,

  /// The app was foregrounded (per the lifecycle marks) and neither a
  /// late burst nor the gate tally explains the gap: GPS reception
  /// itself dropped (tunnel, parking garage, urban canyon).
  signalLoss,

  /// No verdict possible — typically a legacy trip persisted without
  /// lifecycle marks, or a backgrounded gap on an FGS-enabled build
  /// (where backgrounding should NOT throttle, so the cause is unclear).
  unknown,
}

/// One attributed hole in the GPS track: no fix arrived for more than
/// [GpsCoverageReport.kGapFactor] × the expected fix interval.
class GpsCoverageGap {
  /// Timestamp of the last fix BEFORE the gap.
  final DateTime start;

  /// Time until the next fix after [start].
  final Duration duration;

  final GpsGapAttribution attribution;

  const GpsCoverageGap({
    required this.start,
    required this.duration,
    required this.attribution,
  });

  /// Compact export encoding ('startMs' epoch ms, 'durationMs', enum name).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'startMs': start.millisecondsSinceEpoch,
        'durationMs': duration.inMilliseconds,
        'attribution': attribution.name,
      };
}

/// The expected recording GPS cadence: the #2766 recording settings request
/// a ~1 s interval (`AndroidSettings.intervalDuration: 1 s`,
/// `distanceFilter: 0`; iOS automotiveNavigation streams comparably), and
/// the OBD2 path merges fixes onto its ~1 Hz sample ticks. Post-hoc
/// consumers ([GpsCoverageReport.forTrip]) use this as the default
/// `expectedFixInterval`.
const Duration kGpsExpectedRecordingFixInterval = Duration(seconds: 1);

/// Pure per-trip GPS coverage + gap-attribution report (#3465).
///
/// Built from the persisted [TripSample] stream (only fix-bearing samples
/// count — `latitude`/`longitude` non-null), the trip's
/// [RecordingLifecycleMark]s, the optional [GpsGateRejectionTally], and
/// whether the build ships the recording foreground service. Pure math
/// over the supplied lists — no I/O, no framework; [fromSamples] never
/// throws on malformed input (unsorted / duplicate timestamps, negative
/// deltas, empty lists all degrade to a defensible report).
class GpsCoverageReport {
  /// An inter-fix interval is a GAP once it exceeds `kGapFactor ×
  /// expectedFixInterval`. 2× matches the issue's coverage definition
  /// ("time within ≤2× expected fix interval"): one skipped fix plus
  /// jitter is tolerated; two consecutive missed fixes are a hole.
  static const int kGapFactor = 2;

  /// A post-gap burst attributes the gap to [GpsGapAttribution.osBatching]
  /// when the burst's fix count "stands in" for at least this share of the
  /// fixes the gap swallowed (`burstCount × expectedFixInterval ≥ 0.6 ×
  /// gapDuration`). 60 % per the issue: a partial batch still proves the
  /// receiver was alive and the OS was queueing.
  static const double kOsBatchingBackfillShare = 0.6;

  /// Consecutive fixes count as one delivery BURST while their spacing is
  /// ≤ `0.5 × expectedFixInterval` — i.e. clearly faster than the sensor's
  /// real cadence, which only a queued batch flush produces.
  static const double kOsBatchingBurstSpacingFactor = 0.5;

  /// A gap "majority-overlaps" a backgrounded stretch when more than half
  /// of its duration falls inside backgrounded intervals per the marks.
  static const double kBackgroundOverlapShare = 0.5;

  /// The export serialises at most this many gaps (worst legacy traces
  /// carry hundreds); `gapCount` still reports the true total.
  static const int kExportGapCap = 20;

  /// Share of the fix-to-fix span covered by intervals ≤ [kGapFactor] ×
  /// the expected fix interval. 1.0 = a hole-free track; 0.0 when fewer
  /// than two fixes exist (no coverage is provable).
  final double coverageRatio;

  /// Fixes the expected cadence would have produced over the span
  /// (`span / expectedFixInterval + 1`), vs the fixes actually captured.
  final int expectedFixCount;
  final int actualFixCount;

  /// The cadence the report was judged against (serialised for context).
  final Duration expectedFixInterval;

  /// Every detected gap, chronological, each with its attribution.
  final List<GpsCoverageGap> gaps;

  /// The single longest gap, or null on a gap-free (or <2-fix) track.
  final GpsCoverageGap? longestGap;

  /// Share of the trip span spent backgrounded per the lifecycle marks.
  /// Null when the trip carries no marks (legacy trips) — 0.0 would
  /// falsely read as "provably foreground the whole time".
  final double? backgroundShare;

  /// Whether the build ships the recording foreground service — the gate
  /// on the [GpsGapAttribution.backgroundThrottle] verdict.
  final bool fgsEnabled;

  const GpsCoverageReport({
    required this.coverageRatio,
    required this.expectedFixCount,
    required this.actualFixCount,
    required this.expectedFixInterval,
    required this.gaps,
    required this.longestGap,
    required this.backgroundShare,
    required this.fgsEnabled,
  });

  /// Build the report from a trip's raw samples.
  ///
  /// Only fix-bearing samples (non-null latitude AND longitude) enter the
  /// analysis; an OBD2 trip's engine-only ticks are transparent. Inputs
  /// are defensively sorted by timestamp. A non-positive
  /// [expectedFixInterval] falls back to [kGpsExpectedRecordingFixInterval]
  /// rather than dividing by zero.
  ///
  /// Attribution precedence per gap (first match wins), documented in
  /// [GpsGapAttribution]:
  ///  1. [GpsGapAttribution.backgroundThrottle] — `!fgsEnabled`, marks
  ///     present, and > [kBackgroundOverlapShare] of the gap inside a
  ///     backgrounded interval.
  ///  2. [GpsGapAttribution.osBatching] — the post-gap burst backfills
  ///     ≥ [kOsBatchingBackfillShare] of the gap (see the constants).
  ///  3. [GpsGapAttribution.gateRejected] — the [tally]'s rejected
  ///     fix/segment budget (accuracy + teleport + decimation) still
  ///     covers this gap's missing-fix count; the budget DEPLETES across
  ///     gaps (chronological) so one small tally can't explain every hole.
  ///  4. [GpsGapAttribution.signalLoss] — marks present and the gap is
  ///     majority-foreground.
  ///  5. [GpsGapAttribution.unknown] — everything else (no marks, or a
  ///     backgrounded-majority gap on an FGS build).
  factory GpsCoverageReport.fromSamples(
    List<TripSample> samples, {
    required Duration expectedFixInterval,
    GpsGateRejectionTally? tally,
    List<RecordingLifecycleMark> marks = const [],
    required bool fgsEnabled,
  }) {
    final interval = expectedFixInterval > Duration.zero
        ? expectedFixInterval
        : kGpsExpectedRecordingFixInterval;
    final gpsSamples = [
      for (final s in samples)
        if (s.latitude != null && s.longitude != null) s,
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final fixes = [for (final s in gpsSamples) s.timestamp];
    // Link-recovery correlate (#3465): only meaningful on a trip that
    // carried OBD2 data at all.
    final tripHasObd2 = samples.isNotEmpty &&
        samples.where((s) => s.rpm != null).length >= 0.2 * samples.length;
    final sortedMarks = [...marks]..sort((a, b) => a.at.compareTo(b.at));

    if (fixes.length < 2 || !fixes.last.isAfter(fixes.first)) {
      // Degenerate track: nothing to cover, no gap is provable.
      return GpsCoverageReport(
        coverageRatio: 0,
        expectedFixCount: fixes.length,
        actualFixCount: fixes.length,
        expectedFixInterval: interval,
        gaps: const [],
        longestGap: null,
        backgroundShare: sortedMarks.isEmpty ? null : 0.0,
        fgsEnabled: fgsEnabled,
      );
    }

    final spanUs = fixes.last.difference(fixes.first).inMicroseconds;
    final intervalUs = interval.inMicroseconds;
    final gapThresholdUs = kGapFactor * intervalUs;

    // Pass 1 — covered time + raw gap positions.
    var coveredUs = 0;
    final rawGaps = <({int endIndex, int dtUs})>[];
    for (var i = 1; i < fixes.length; i++) {
      final dtUs = fixes[i].difference(fixes[i - 1]).inMicroseconds;
      if (dtUs <= gapThresholdUs) {
        coveredUs += dtUs;
      } else {
        rawGaps.add((endIndex: i, dtUs: dtUs));
      }
    }

    // Pass 2 — attribute each gap (chronological; the gate budget depletes).
    var gateBudget = tally == null
        ? 0
        : tally.accuracyRejectedSegments +
            tally.teleportRejectedSegments +
            tally.decimationDroppedFixes;
    final gaps = <GpsCoverageGap>[];
    for (final raw in rawGaps) {
      final gapStart = fixes[raw.endIndex - 1];
      final gapEnd = fixes[raw.endIndex];
      GpsGapAttribution attribution;
      final backgroundedUs =
          _backgroundedOverlapUs(sortedMarks, gapStart, gapEnd);
      final rawMissing = (raw.dtUs / intervalUs).round() - 1;
      final missingFixes = rawMissing > 0 ? rawMissing : 0;
      if (!fgsEnabled &&
          sortedMarks.isNotEmpty &&
          backgroundedUs > kBackgroundOverlapShare * raw.dtUs) {
        attribution = GpsGapAttribution.backgroundThrottle;
      } else if (_burstBackfillsGap(
          fixes, raw.endIndex, raw.dtUs, intervalUs)) {
        attribution = GpsGapAttribution.osBatching;
      } else if (tripHasObd2 &&
          gpsSamples[raw.endIndex - 1].rpm == null &&
          gpsSamples[raw.endIndex].rpm == null) {
        attribution = GpsGapAttribution.linkRecovery;
      } else if (tally != null &&
          missingFixes > 0 &&
          gateBudget >= missingFixes) {
        gateBudget -= missingFixes;
        attribution = GpsGapAttribution.gateRejected;
      } else if (sortedMarks.isNotEmpty &&
          backgroundedUs <= kBackgroundOverlapShare * raw.dtUs) {
        attribution = GpsGapAttribution.signalLoss;
      } else {
        attribution = GpsGapAttribution.unknown;
      }
      gaps.add(GpsCoverageGap(
        start: gapStart,
        duration: Duration(microseconds: raw.dtUs),
        attribution: attribution,
      ));
    }

    GpsCoverageGap? longest;
    for (final g in gaps) {
      if (longest == null || g.duration > longest.duration) longest = g;
    }

    return GpsCoverageReport(
      coverageRatio: (coveredUs / spanUs).clamp(0.0, 1.0).toDouble(),
      expectedFixCount: spanUs ~/ intervalUs + 1,
      actualFixCount: fixes.length,
      expectedFixInterval: interval,
      gaps: List.unmodifiable(gaps),
      longestGap: longest,
      backgroundShare: sortedMarks.isEmpty
          ? null
          : (_backgroundedOverlapUs(sortedMarks, fixes.first, fixes.last) /
                  spanUs)
              .clamp(0.0, 1.0)
              .toDouble(),
      fgsEnabled: fgsEnabled,
    );
  }

  /// Production convenience for the trip-detail card + the
  /// driving-analysis export: derives the gate tally by re-running the
  /// #2963/#1979 gates over the persisted track (REUSING
  /// [GpsTrackDistance.haversineKm]'s tally seam, not duplicating gate
  /// logic — the #3004 decimation figures stay 0 post-hoc because the
  /// persisted samples are already the decimated truth), reads the FGS
  /// build flag, and returns null when the trip has fewer than two fixes
  /// (nothing to report — the card self-hides).
  static GpsCoverageReport? forTrip(
    List<TripSample> samples, {
    List<RecordingLifecycleMark> marks = const [],
    Duration expectedFixInterval = kGpsExpectedRecordingFixInterval,
    bool fgsEnabled = kGpsRecordingForegroundServiceEnabled,
  }) {
    final track = <GpsTrackPoint>[
      for (final s in samples)
        if (s.latitude != null && s.longitude != null)
          GpsTrackPoint(
            s.latitude!,
            s.longitude!,
            hAccuracyM: s.hAccuracyM,
            at: s.timestamp,
          ),
    ];
    if (track.length < 2) return null;
    final tally = GpsGateRejectionTally();
    GpsTrackDistance.haversineKm(track, tally: tally);
    return GpsCoverageReport.fromSamples(
      samples,
      expectedFixInterval: expectedFixInterval,
      tally: tally,
      marks: marks,
      fgsEnabled: fgsEnabled,
    );
  }

  /// Microseconds of `[from, to]` that fall inside a backgrounded interval
  /// per [sortedMarks]. Time before the first mark counts as FOREGROUND
  /// (recordings start from a user interaction; the recorder also emits a
  /// leading clamped mark, so this branch only matters for hand-built
  /// inputs). The last mark's state extends to [to].
  static int _backgroundedOverlapUs(
    List<RecordingLifecycleMark> sortedMarks,
    DateTime from,
    DateTime to,
  ) {
    if (sortedMarks.isEmpty || !to.isAfter(from)) return 0;
    var overlapUs = 0;
    for (var i = 0; i < sortedMarks.length; i++) {
      if (!sortedMarks[i].backgrounded) continue;
      final segStart = sortedMarks[i].at;
      final segEnd =
          i + 1 < sortedMarks.length ? sortedMarks[i + 1].at : to;
      final s = segStart.isAfter(from) ? segStart : from;
      final e = segEnd.isBefore(to) ? segEnd : to;
      if (e.isAfter(s)) overlapUs += e.difference(s).inMicroseconds;
    }
    return overlapUs;
  }

  /// True when the run of tightly-spaced fixes beginning at the gap-end
  /// fix ([burstStartIndex]) is large enough to stand in for
  /// ≥ [kOsBatchingBackfillShare] of the fixes the gap swallowed. See the
  /// two `kOsBatching*` constants for the thresholds.
  static bool _burstBackfillsGap(
    List<DateTime> fixes,
    int burstStartIndex,
    int gapUs,
    int intervalUs,
  ) {
    final burstSpacingUs = (kOsBatchingBurstSpacingFactor * intervalUs).ceil();
    var burstCount = 1; // The gap-end fix itself.
    for (var j = burstStartIndex; j + 1 < fixes.length; j++) {
      final dt = fixes[j + 1].difference(fixes[j]).inMicroseconds;
      if (dt > burstSpacingUs) break;
      burstCount++;
    }
    return burstCount * intervalUs >= kOsBatchingBackfillShare * gapUs;
  }

  /// JSON block for the driving-analysis export (#3465, schema v3).
  /// Additive; the gap list is capped at [kExportGapCap] entries
  /// (`gapCount` keeps the true total; `gapsTruncated` flags the cap).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'coverageRatio': _round4(coverageRatio),
        'expectedFixCount': expectedFixCount,
        'actualFixCount': actualFixCount,
        'expectedFixIntervalMs': expectedFixInterval.inMilliseconds,
        'fgsEnabled': fgsEnabled,
        'backgroundShare':
            backgroundShare == null ? null : _round4(backgroundShare!),
        'gapCount': gaps.length,
        'longestGap': longestGap?.toJson(),
        'gaps': [
          for (final g in gaps.take(kExportGapCap)) g.toJson(),
        ],
        if (gaps.length > kExportGapCap) 'gapsTruncated': true,
      };

  static double _round4(double v) => (v * 10000).round() / 10000;
}
