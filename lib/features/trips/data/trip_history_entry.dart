// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../domain/entities/gps_sample_diagnostic.dart';
import '../domain/entities/recording_lifecycle_mark.dart';
import '../domain/entities/trip_termination.dart';
import '../domain/recording_session_journal.dart';
import '../domain/trip_recorder.dart';
import '../../obd2/api.dart';
import 'trip_sample_codec.dart';
import 'trip_summary_codec.dart';

/// One finalised trip as shown in the Trip history list (#726).
///
/// Wraps a [TripSummary] with the persisted bookkeeping fields — a
/// stable id so list widgets can key on it, and the vehicleId so the
/// list can be filtered down the road. The summary already carries
/// `startedAt` / `endedAt`; we don't duplicate those here.
///
/// Extracted from `trip_history_repository.dart` (#3613) so the
/// repository could gain the summary-only decode path without breaching
/// the 400-line cap; that file re-exports this one, so every existing
/// import keeps working.
@immutable
class TripHistoryEntry {
  final String id;
  final String? vehicleId;
  final TripSummary summary;

  /// Whether this trip was captured by the auto-record path
  /// (#1004 phase 4). Drives the badge-decrement call when the user
  /// opens the detail screen — manual trips don't decrement because
  /// they were never counted as "unseen". Defaults to false so all
  /// pre-#1004 entries deserialise as manual.
  final bool automatic;

  /// Per-tick recording profile used by the trip-detail charts (#1040).
  ///
  /// Captured by [TripRecordingController] at ~1 Hz throughout the
  /// recording — the speed / RPM / fuel-rate fields render the
  /// speed / fuel-rate / RPM line charts in the trip-detail screen.
  /// Empty for legacy trips written before #1040 landed: the charts
  /// fall back to the shared "No samples recorded" caption in that
  /// case, which is the honest answer for trips whose buffer was
  /// never persisted.
  ///
  /// Storage budget: ~1 Hz × 8 fields, so a 39-min trip is roughly
  /// 19 KB compressed. A year of daily commutes is around 7 MB —
  /// well below the rolling-log cap.
  ///
  /// #3613 — ALWAYS empty on entries produced by
  /// [TripHistoryRepository.loadSummaries]; use [sampleCount] (not
  /// `samples.length` / `samples.isEmpty`) wherever the *stored*
  /// sample count matters (ghost de-dupe, badges), because it stays
  /// truthful on the summary-only decode path.
  final List<TripSample> samples;

  /// The number of samples the PERSISTED entry carries (#3613).
  ///
  /// On a fully-decoded entry this is simply `samples.length`. On a
  /// summary-only entry (from [TripHistoryRepository.loadSummaries])
  /// the samples list is deliberately not materialised, but the stored
  /// count is preserved here so summary-level consumers — most
  /// importantly the #2833 ghost de-dupe, which distinguishes 0-sample
  /// ghosts from their sampled twins — keep working unchanged.
  int get sampleCount => _persistedSampleCount ?? samples.length;
  final int? _persistedSampleCount;

  /// Stable BLE remote-id / Classic MAC of the OBD2 adapter that was
  /// connected when this trip was recorded (#1312). Lets the trip
  /// detail summary card name the suspect device when the user files
  /// a bug report about adapter-specific PID gaps. Null for trips
  /// recorded before #1312 landed and for any trip whose connect path
  /// didn't stamp the service (e.g. test fakes).
  final String? adapterMac;
  /// Friendly device name advertised by the OBD2 adapter, falling
  /// back to the registry's display label when the advertisement was
  /// empty (#1312). Same null-semantics as [adapterMac].
  final String? adapterName;
  /// ELM327 firmware string returned by `ATI` during the init
  /// sequence, when the connect path captured one (#1312). Currently
  /// always null in production; persisted as a forward-compat field
  /// so a future enhancement that snapshots `ATI` doesn't have to
  /// migrate the trip-history schema again.
  final String? adapterFirmware;

  /// Per-sample GPS cadence diagnostics captured under phone-sleep
  /// conditions (#1458 phase 2). Records the wall-clock timestamp and
  /// app-lifecycle state at every position fix, plus a monotonic index
  /// — lets a future diagnostics sheet (or a power user inspecting
  /// the persisted entry) reconstruct exactly when the OS throttled or
  /// paused the GPS stream during an unpinned recording. Empty for
  /// trips recorded before #1458 phase 2 landed and for trips whose
  /// `Feature.gpsTripPath` flag was off at recording start.
  final List<GpsSampleDiagnostic> gpsSampleDiagnostics;

  /// Foreground↔background transitions observed during the recording,
  /// windowed to the trip (#3465). A tiny list (one entry per transition,
  /// led by a clamped trip-start anchor — see
  /// `RecordingLifecycleMarksRecorder.marksForWindow`) that lets the
  /// post-hoc GPS coverage report attribute a track gap to OS background
  /// throttling on a no-FGS build. Empty for legacy trips recorded before
  /// this field landed.
  final List<RecordingLifecycleMark> lifecycleMarks;

  /// OBD2 communication-health diagnostic snapshotted at trip finish
  /// (#2912, Epic #2904). The dev-only trip-detail comm-health card was
  /// **always empty** because it read the process-wide in-memory
  /// `Obd2CommDiagnostics.instance` singleton — wiped on restart and never
  /// tied to a trip — instead of the viewed trip's own diagnostic. This
  /// field persists the per-trip snapshot (connection attempts + the #2905
  /// reconnect timeline / session-state transitions / fallback markers,
  /// captured even when the adapter never connected) so the card can render
  /// THIS trip's health after a restart.
  ///
  /// Null for GPS-only trips that never touched OBD2, for production builds
  /// (the collector is disarmed unless `Feature.debugMode` is on), and for
  /// every legacy trip recorded before this field landed — in all of which
  /// the card keeps self-hiding. Round-trips via the existing JSON
  /// persistence under the compact key `'obd2d'`; the nested freezed model
  /// carries its own `toJson`/`fromJson` (heeding the #2776 round-trip
  /// lesson — it is a real serialised field, not `@JsonKey`-excluded).
  final Obd2SessionDiagnostic? obd2Diagnostic;

  /// The driver's own post-trip verdict (#3501) — `TripVerdict.name`, or
  /// null while the prompt hasn't been answered. `skipped` records a
  /// dismissal so the prompt never nags twice for the same trip.
  final String? verdict;

  /// #3795 — WHY this recording ended. Null on rows written before the
  /// termination taxonomy landed (and on the legacy paths that still
  /// cannot attribute an end); never inferred at read time, so an absent
  /// value stays honestly unknown.
  final TripTermination? termination;

  /// #3797 — the correlated lifecycle timeline of the recording session
  /// (link ready/drop/reconnect, protocol establishment, rebinds,
  /// scheduler gating, GPS-degrade, the terminal event). Null for trips
  /// recorded before it existed; empty for a GPS-only trip that never
  /// touched the link.
  final RecordingSessionJournal? sessionJournal;

  const TripHistoryEntry({
    required this.id,
    required this.vehicleId,
    required this.summary,
    this.automatic = false,
    this.samples = const [],
    int? sampleCount,
    this.adapterMac,
    this.adapterName,
    this.adapterFirmware,
    this.gpsSampleDiagnostics = const [],
    this.lifecycleMarks = const [],
    this.obd2Diagnostic,
    this.verdict,
    this.termination,
    this.sessionJournal,
  }) : _persistedSampleCount = sampleCount;

  /// Returns a copy with the given fields replaced (#1858). The
  /// retroactive η_v recompute uses it to swap in a rescaled [summary]
  /// while leaving the id / vehicle / samples / adapter identity
  /// untouched.
  TripHistoryEntry copyWith({TripSummary? summary, String? verdict}) =>
      TripHistoryEntry(
        id: id,
        vehicleId: vehicleId,
        summary: summary ?? this.summary,
        automatic: automatic,
        samples: samples,
        sampleCount: _persistedSampleCount,
        adapterMac: adapterMac,
        adapterName: adapterName,
        adapterFirmware: adapterFirmware,
        gpsSampleDiagnostics: gpsSampleDiagnostics,
        lifecycleMarks: lifecycleMarks,
        obd2Diagnostic: obd2Diagnostic,
        verdict: verdict ?? this.verdict,
        termination: termination,
        sessionJournal: sessionJournal,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'summary': tripSummaryToJson(summary),
        if (automatic) 'automatic': true,
        if (samples.isNotEmpty)
          'samples': samples.map(sampleToJson).toList(growable: false),
        // #1312 — adapter identity. Compact keys so the per-trip JSON
        // payload doesn't balloon (most trips carry one MAC + one
        // name; firmware stays null until the connect path captures
        // it). Each key is omitted when null so legacy entries
        // round-trip unchanged.
        if (adapterMac != null) 'adapterMac': adapterMac,
        if (adapterName != null) 'adapterName': adapterName,
        if (adapterFirmware != null) 'adapterFirmware': adapterFirmware,
        // #1458 phase 2 — GPS cadence diagnostics. Compact key 'gpsd'
        // keeps the per-trip JSON tight; emitted only when at least one
        // diagnostic was recorded so legacy trips and flag-off trips
        // round-trip unchanged.
        if (gpsSampleDiagnostics.isNotEmpty)
          'gpsd': gpsSampleDiagnostics
              .map((d) => d.toJson())
              .toList(growable: false),
        // #3465 — recording lifecycle marks. Compact key 'lcm', emitted
        // only when at least one mark was captured, so legacy trips
        // round-trip unchanged (the mq/ep additive-optional precedent).
        if (lifecycleMarks.isNotEmpty)
          'lcm':
              lifecycleMarks.map((m) => m.toJson()).toList(growable: false),
        // #2912 — per-trip OBD2 comm-health diagnostic. Compact key 'obd2d'.
        // Emitted only when a diagnostic was captured (debug-mode trips that
        // touched OBD2), so production / GPS-only / legacy trips round-trip
        // with zero bytes added. The nested freezed model serialises itself
        // via its own short-keyed toJson, so the persisted snapshot reloads
        // intact (NOT @JsonKey-dropped — #2776 lesson).
        if (obd2Diagnostic != null) 'obd2d': obd2Diagnostic!.toJson(),
        // #3501 — the driver's post-trip verdict. Omitted when unanswered so
        // legacy entries round-trip unchanged. A synced-entity FIELD add is
        // TankSync-transparent (JSONB data column, #2929).
        if (verdict != null) 'verdict': verdict,
        // #3795 — termination class + detail. Compact key 'term',
        // omitted when unknown so legacy rows round-trip byte-identical.
        if (termination != null) 'term': termination!.toJson(),
        // #3797 — the session lifecycle timeline. Compact key 'sj',
        // omitted when no event was ever recorded (GPS-only / legacy),
        // so trips that never touched the link add zero bytes.
        if (sessionJournal != null && sessionJournal!.events.isNotEmpty)
          'sj': sessionJournal!.toJson(),
      };

  static TripHistoryEntry fromJson(Map<String, dynamic> json) =>
      TripHistoryEntry(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String?,
        summary: tripSummaryFromJson(
          (json['summary'] as Map).cast<String, dynamic>(),
        ),
        automatic: (json['automatic'] as bool?) ?? false,
        samples: (json['samples'] as List?)
                ?.map(
                    (e) => sampleFromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false) ??
            const [],
        // #1312 — adapter identity. Reads as `String?` so legacy
        // entries written before this field landed deserialise with
        // null rather than throwing (mirrors the schema-drift lesson
        // from #1301).
        adapterMac: json['adapterMac'] as String?,
        adapterName: json['adapterName'] as String?,
        adapterFirmware: json['adapterFirmware'] as String?,
        // #1458 phase 2 — GPS cadence diagnostics. Missing key →
        // empty list so trips recorded before this PR (and flag-off
        // trips that never recorded a diagnostic) deserialise cleanly.
        gpsSampleDiagnostics: (json['gpsd'] as List?)
                ?.map((e) => GpsSampleDiagnostic.fromJson(
                      (e as Map).cast<String, dynamic>(),
                    ))
                .toList(growable: false) ??
            const [],
        // #3465 — recording lifecycle marks. Missing key → empty list so
        // legacy trips deserialise cleanly (and the coverage report reads
        // "no marks" as its honest unknown-attribution input).
        lifecycleMarks: (json['lcm'] as List?)
                ?.map((e) => RecordingLifecycleMark.fromJson(
                      (e as Map).cast<String, dynamic>(),
                    ))
                .toList(growable: false) ??
            const [],
        // #2912 — per-trip OBD2 comm-health diagnostic. Missing key → null
        // so legacy trips, GPS-only trips and production (gate-off) trips
        // deserialise cleanly and the card keeps self-hiding for them.
        obd2Diagnostic: json['obd2d'] == null
            ? null
            : Obd2SessionDiagnostic.fromJson(
                (json['obd2d'] as Map).cast<String, dynamic>(),
              ),
        // #3501 — missing key → null (unanswered) on legacy entries.
        verdict: json['verdict'] as String?,
        // #3795/#3797 — missing key → null on every pre-existing row, so
        // the history decodes unchanged and an absent value reads as an
        // honest "not recorded" rather than a guessed reason.
        termination: json['term'] == null
            ? null
            : TripTermination.fromJson(
                (json['term'] as Map).cast<String, dynamic>(),
              ),
        sessionJournal: json['sj'] == null
            ? null
            : RecordingSessionJournal.fromJson(
                (json['sj'] as Map).cast<String, dynamic>(),
              ),
      );

  /// Summary-only decode (#3613) — everything [fromJson] produces
  /// EXCEPT the heavy per-tick payloads: `samples`, `gpsd`, `lcm` and
  /// `obd2d` are NOT materialised (jsonDecode has already parsed them
  /// into raw maps; the dominant cost this path avoids is constructing
  /// a [TripSample] / [GpsSampleDiagnostic] object per tick — tens of
  /// thousands per long trip). The stored sample count is preserved on
  /// [sampleCount] so the #2833 ghost de-dupe stays correct.
  ///
  /// Only [TripHistoryRepository.loadSummaries] should call this;
  /// consumers that render samples must go through the full decode.
  static TripHistoryEntry summaryFromJson(Map<String, dynamic> json) =>
      TripHistoryEntry(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String?,
        summary: tripSummaryFromJson(
          (json['summary'] as Map).cast<String, dynamic>(),
        ),
        automatic: (json['automatic'] as bool?) ?? false,
        samples: const [],
        sampleCount: (json['samples'] as List?)?.length ?? 0,
        adapterMac: json['adapterMac'] as String?,
        adapterName: json['adapterName'] as String?,
        adapterFirmware: json['adapterFirmware'] as String?,
        verdict: json['verdict'] as String?,
        // #3795 — the termination is a single small map, not a per-tick
        // payload, and the history LIST wants it (a crash-truncated trip
        // should be flaggable without a full decode), so it is
        // materialised on the summary path too. The journal is NOT —
        // that one is a list and belongs to the detail/export path.
        termination: json['term'] == null
            ? null
            : TripTermination.fromJson(
                (json['term'] as Map).cast<String, dynamic>(),
              ),
      );
}
