// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import '../../../../core/domain/consumption_estimate.dart';
import '../../domain/driving_score.dart';
import '../../../trips/api.dart';
import '../../domain/lessons/driving_lesson.dart';

/// A self-contained, JSON-serialisable snapshot of a single trip's
/// driving-analysis inputs + outputs, for offline threshold calibration
/// (#2804, Epic #2789 C6).
///
/// Mirrors the OCR trace package (#2517): pure Dart, hand-written `toJson`,
/// `schema` versioned. The maintainer exports this from the trip-detail screen
/// (dev-mode), writes their subjective verdict into [comment] (e.g. "calm
/// motorway cruise — felt smooth"), and shares the JSON back, giving labelled
/// real-trip data to fine-tune the GPS-efficiency KPI verdict bands (RPA / PKE
/// / VAPOS / coasting) and the IMU/score thresholds against reality — instead
/// of guessing cutoffs that could contradict the smooth-driving lesson.
class DrivingAnalysisTrace {
  /// Serialisation schema version. Bump when a field's meaning changes.
  ///
  /// v2 (#3433, Epic #3416) — `obd2Features` gained the consumption-
  /// precision block: `measuredPhi` / `ethanolPercent` distributions,
  /// per-branch `fuelSourceShares` + `dominantFuelSource`, and the
  /// `measuredPhi` / `ethanolPercent` signal-coverage keys. Purely
  /// additive — v1 readers that ignore unknown keys still parse.
  ///
  /// v3 (#3465) — new top-level `gpsCoverage` block: track coverage
  /// ratio, expected-vs-actual fix counts, and the attributed gap list
  /// (capped at 20 entries). Purely additive — null on legacy trips with
  /// under two GPS fixes; v2 readers that ignore unknown keys still parse.
  ///
  /// v4 (#3499, epic #3498) — new top-level `obd2Coverage` block: the share
  /// of samples that carried an engine PID + the coarse reason
  /// (full / partial / droppedMidTrip / noEngineData), so a `gpsPlusObd2`
  /// trip whose `obd2Features` are null is no longer unexplained. Purely
  /// additive — null on empty trips; v3 readers still parse.
  /// v5 (#3798, Epic #3794) — recording-session transparency. Two new
  /// top-level blocks answer the question every field report raises and
  /// no earlier schema could: **why did the session end, and what
  /// happened to the OBD2 link while it ran?**
  ///
  ///  * `session` — the termination class + detail (`userStopped`,
  ///    `graceWindowExpiry`, `recoveredAfterProcessDeath`, …), the
  ///    adapter identity, and the automatic flag.
  ///  * `obd2Link` — the trip-scoped lifecycle timeline: link
  ///    ready/drop/reconnect, protocol establishment and its verdict,
  ///    service rebinds, scheduler gating, GPS-degrade, the staleness
  ///    fence. Always captured (not debug-gated), so an ordinary
  ///    tester's export explains itself.
  ///
  /// Purely additive: both null on legacy trips, and v4 readers that
  /// ignore unknown keys still parse.
  ///
  /// v6 (#4352, Epic #4351) — a new top-level `protection` block: which
  /// **artifact** this trip was recorded on and what native execution
  /// protection the session actually held. The user report behind
  /// #4351 is "recording only works while its form is open", and the
  /// first cause is the artifact, not the code: `FGS_FORM_APPROVED` is
  /// a build define that the Play workflow passes only when the
  /// repository variable is set (it is not), so a Play APK and an
  /// F-Droid APK built from the SAME commit have different
  /// background-recording capability. Without this block an export
  /// cannot tell the two apart, and every screen-off report is
  /// unattributable. `channel` + `foregroundServiceCompiled` are always
  /// emitted (they are compile-time facts); `verdict` is
  /// [RecordingProtectionVerdict.unknown] until a session actually
  /// acquires a lease (S4 / #4352b) — and unknown is never "protected".
  ///
  /// Purely additive; v5 readers that ignore unknown keys still parse.
  static const int schema = 6;

  final DateTime capturedAt;

  /// The maintainer's free-text verdict + notes. Defaults to a prompt so the
  /// exported file invites annotation; the maintainer overwrites it.
  final String comment;

  final TripSummary summary;
  final GpsDrivingFeatures? gpsFeatures;

  /// Per-trip OBD2 telemetry aggregate (#3402). Null when the trip carried no
  /// engine signal — a GPS-only trip, or an OBD2 trip whose link kept dropping
  /// so every read fell back to GPS. A null section is the export's explicit
  /// "0 % OBD2 coverage" marker; a present section surfaces the real RPM /
  /// engine-load / throttle distribution and whether the fuel figure was
  /// measured or estimated.
  final Obd2TripFeatures? obd2Features;

  /// Per-trip GPS coverage + gap-attribution report (#3465). Null when
  /// the trip carries fewer than two GPS fixes (legacy trips, opted-out
  /// trips) — the export's explicit "no track to judge" marker, mirroring
  /// the [obd2Features] null convention.
  final GpsCoverageReport? gpsCoverage;

  /// #3501 (schema v4) — the driver's own post-trip verdict
  /// (`TripVerdict.name`: smooth / moderate / aggressive; `skipped` and
  /// null mean unanswered). The structured replacement for hand-editing
  /// [comment]; when present, the comment prompt is dropped from the
  /// export automatically.
  final String? verdict;

  /// Per-trip engine-sample coverage + reason (#3499, schema v4). Null only
  /// on an empty trip — a present block with `reason: noEngineData` is the
  /// honest explanation for a null [obd2Features] on a `gpsPlusObd2` trip.
  final Obd2EngineCoverage? obd2Coverage;

  final DrivingScore score;
  final List<DrivingLesson> lessons;

  const DrivingAnalysisTrace({
    required this.capturedAt,
    required this.summary,
    required this.score,
    required this.lessons,
    this.gpsFeatures,
    this.obd2Features,
    this.gpsCoverage,
    this.obd2Coverage,
    this.verdict,
    this.comment = kDrivingAnalysisCommentPrompt,
    this.termination,
    this.sessionJournal,
    this.protection,
    this.protectionBuild = RecordingProtectionBuild.current,
    this.adapterName,
    this.adapterMac,
    this.automatic = false,
    this.roadLoad,
    this.dimensions,
  });

  /// #3795 — how the recording ended. Null for trips saved before the
  /// termination taxonomy existed.
  final TripTermination? termination;

  /// #3797 — the session's lifecycle timeline.
  final RecordingSessionJournal? sessionJournal;

  /// #4352 — the protection the session actually held. Null when the
  /// trip predates the contract or never asked for a lease; the export
  /// then still records the artifact's compiled capability below, so
  /// "unknown verdict on a build that could not have promoted anyway"
  /// is distinguishable from "unknown verdict on a capable build".
  final RecordingProtectionStatus? protection;

  /// #4352 — which artifact this trip was recorded on. Defaults to the
  /// running build; overridable so a fixture can assert both channels.
  final RecordingProtectionBuild protectionBuild;

  /// #1312 — adapter identity, already persisted on the trip and until
  /// now dropped at export time.
  final String? adapterName;
  final String? adapterMac;

  /// Whether auto-record started this trip.
  final bool automatic;

  /// #4203 — the derived road-load features (grade / curvature confidence,
  /// stops, curves by approach, oscillations) for model validation.
  final Map<String, Object>? roadLoad;

  /// #4205 — the behaviour dimensions (value + confidence + evidence).
  final Map<String, Object?>? dimensions;

  /// #4233 — the trip's consumption as the canonical contract. No vehicle:
  /// the export records the stored figure, never a re-expression.
  ConsumptionEstimate get _consumption =>
      tripConsumptionEstimate(summary, null);

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'kind': 'drivingAnalysis',
        'capturedAt': capturedAt.toIso8601String(),
        // The annotation slot — first so it is obvious in the shared file.
        // #3501 — once an in-app verdict exists the begging prompt is
        // replaced by a pointer to the structured field below.
        'comment': verdict != null && comment == kDrivingAnalysisCommentPrompt
            ? 'verdict captured in-app — see the "verdict" field'
            : comment,
        'verdict': verdict,
        'summary': {
          'tripKind': summary.kind.name,
          'distanceKm': _round(summary.distanceKm, 3),
          'durationSec': _durationSec(summary),
          'avgLPer100Km': _roundN(summary.avgLPer100Km, 2),
          // #4233 — the figure's provenance through the canonical adapter
          // (ADR 0024 §7); additive, the stored figure above is unchanged.
          'consumptionSource': _consumption.sourceClass.name,
          'consumptionVersion': _consumption.version?.toJson(),
          'distanceSource': summary.distanceSource,
          // #3599 — engine-off transport (tow/flatbed/train) telemetry.
          'engineRunningSeconds': _roundN(summary.engineRunningSeconds, 1),
          'engineOffTransport': isEngineOffTransport(summary),
        },
        'imu': {
          // #2895 — whether the inertial sensor ran. A genuine IMU zero with
          // active=true VETOES a noisy GPS over-count in the score; active=false
          // means the (clamped) GPS-derived counts were used.
          'active': summary.imuActive,
          'hardAccelCount': summary.imuHardAccelCount,
          'hardBrakeCount': summary.imuHardBrakeCount,
          'sharpCornerCount': summary.sharpCornerCount,
          'hardAccelPerKm': _round(summary.imuHardAccelPerKm, 3),
          'hardBrakePerKm': _round(summary.imuHardBrakePerKm, 3),
          'sharpCornersPerKm': _round(summary.sharpCornersPerKm, 3),
          // #3589 — per-stretch magnitude records (confirmed + rejected
          // near-misses) for threshold calibration against verdicts.
          'events': [for (final r in summary.imuEventRecords) r.toJson()],
          'droppedEvents': summary.imuEventRecordsDropped,
        },
        'roadLoad': roadLoad,
        'dimensions': dimensions,
        'gpsFeatures': gpsFeatures == null
            ? null
            : {
                'rpa': _round(gpsFeatures!.relativePositiveAcceleration, 4),
                'pke': _round(gpsFeatures!.positiveKineticEnergy, 4),
                'vapos': _round(gpsFeatures!.meanPositiveVa, 4),
                'coastShare': _round(gpsFeatures!.coastShare, 4),
                'climbEnergyPerKm': _round(gpsFeatures!.climbEnergyPerKm, 2),
                'accelEvents': gpsFeatures!.accelEvents,
                'brakeEvents': gpsFeatures!.brakeEvents,
                'sharpCornerEvents': gpsFeatures!.sharpCornerEvents,
                'maxAccelG': _round(gpsFeatures!.maxAccelG, 3),
                // #3503 — self-describing gates: the field export that
                // motivated epic #3498 read "maxAccelG 0.341 g yet
                // accelEvents 0" as a contradiction. The peak is a
                // sample-to-sample instantaneous derivative (physically
                // clamped); events must SUSTAIN ≥1 s above the threshold
                // through the accuracy/min-speed gates.
                'gates': const {
                  'maxAccelG': 'instantaneous sample-to-sample peak, clamped',
                  'events':
                      'sustained >=1.0s at >=3.0 (accel) / >=3.5 (brake) '
                          'm/s2, accuracy- and min-speed-gated',
                },
                'meanSpeedKmh': _round(gpsFeatures!.meanSpeedKmh, 1),
                'speedBandSeconds': {
                  'idle': _round(gpsFeatures!.idleSeconds, 0),
                  'low': _round(gpsFeatures!.lowSpeedSeconds, 0),
                  'cruise': _round(gpsFeatures!.cruiseSeconds, 0),
                  'high': _round(gpsFeatures!.highSpeedSeconds, 0),
                },
              },
        // #3402 — the real OBD2 telemetry the trip captured (RPM / engine-load
        // / throttle / pedal distribution, measured-vs-estimated fuel, and a
        // per-signal coverage map). Null when no engine signal landed, which
        // makes a broken-link GPS-fallback trip read as `obd2Features: null`.
        'obd2Features': obd2Features?.toJson(),
        // #3499 (schema v4) — engine-sample coverage + reason, the honest
        // companion to a null obd2Features on a gpsPlusObd2 trip.
        'obd2Coverage': obd2Coverage?.toJson(),
        // #3795/#3798 — WHY the session ended, plus the identity a field
        // report needs to attribute it. Emitted even when the
        // termination is unknown, so "not recorded" is explicit rather
        // than a missing key the reader has to interpret.
        'session': {
          'terminationReason':
              termination?.reason.name ?? 'unrecorded',
          if (termination?.detail != null)
            'terminationDetail': termination!.detail,
          'automatic': automatic,
          if (adapterName != null) 'adapterName': adapterName,
          if (adapterMac != null) 'adapterMac': adapterMac,
          'startedAt': summary.startedAt?.toIso8601String(),
          'endedAt': summary.endedAt?.toIso8601String(),
        },
        // #3797/#3798 — the correlated lifecycle timeline. Null (not an
        // empty object) when the trip never recorded one, so a legacy
        // export stays visibly distinct from a trip that genuinely had
        // no link events.
        'obd2Link': sessionJournal == null
            ? null
            : {
                'events': sessionJournal!.events
                    .map((e) => e.toJson())
                    .toList(growable: false),
                if (sessionJournal!.droppedEvents > 0)
                  'droppedEvents': sessionJournal!.droppedEvents,
              },
        // #4352/#4351 (schema v6) — the artifact's protection capability
        // and the session's actual verdict, beside the journal. Always
        // emitted: the build half is a compile-time fact, and an absent
        // block would be indistinguishable from a capable build that
        // simply never reported. `verdict: unknown` is NOT protected.
        'protection': <String, Object?>{
          ...protectionBuild.toJson(),
          ...?protection?.toJson(),
          if (protection == null)
            'verdict': RecordingProtectionVerdict.unknown.name,
        },
        // #3465 — GPS coverage + attributed track gaps (schema v3). Null
        // when there is no track to judge; the gap list inside is capped
        // at [GpsCoverageReport.kExportGapCap] entries.
        'gpsCoverage': gpsCoverage?.toJson(),
        'score': {
          'overall': score.score,
          'styleClass': score.styleClass.name,
          // #3350 — the counts the penalties were ACTUALLY computed from,
          // read straight off the score so they can never disagree with the
          // penalty. #3029 sourced these from `summary.harshAccelerations`,
          // but on an OBD2 trip with the IMU inactive the score's penalty is
          // driven by the sample-derived gate, not the (suppressed→0) summary
          // figure — so a 15-pt penalty showed alongside count 0 (the phantom
          // this fixes). The `imu.*Count` block above stays the inertial-sensor
          // truth.
          'hardAccelCount': score.hardAccelEvents,
          'hardBrakeCount': score.hardBrakeEvents,
          'hardAccelPenalty': _round(score.hardAccelPenalty, 2),
          'hardBrakePenalty': _round(score.hardBrakePenalty, 2),
          'idlingPenalty': _round(score.idlingPenalty, 2),
          'highRpmPenalty': _round(score.highRpmPenalty, 2),
          'luggingPenalty': _round(score.luggingPenalty, 2),
        },
        // What the app currently TELLS the user — so an annotation that
        // disagrees pinpoints exactly which judgment to retune.
        'lessons': [
          for (final l in lessons)
            {'id': l.id, 'polarity': l.polarity.name, 'title': l.title},
        ],
      };

  static double _round(double v, int places) {
    final f = _pow10(places);
    return (v * f).round() / f;
  }

  static double? _roundN(double? v, int places) =>
      v == null ? null : _round(v, places);

  static double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  static double? _durationSec(TripSummary s) {
    final start = s.startedAt, end = s.endedAt;
    if (start == null || end == null) return null;
    return end.difference(start).inSeconds.toDouble();
  }
}

/// Default [DrivingAnalysisTrace.comment] — a prompt inviting the maintainer to
/// label the trip so the export is self-explanatory when shared back.
const String kDrivingAnalysisCommentPrompt =
    'YOUR VERDICT HERE → how did this trip actually feel? '
    '(smooth / moderate / aggressive) + any notable hard accel/brake/corner '
    'moments, so the RPA/PKE/VAPOS/coasting bands can be calibrated to match.';

/// Pretty-prints a [DrivingAnalysisTrace] as indented JSON (mirrors
/// `formatOcrTracePackageJson`).
String formatDrivingAnalysisTraceJson(DrivingAnalysisTrace trace) =>
    const JsonEncoder.withIndent('  ').convert(trace.toJson());
