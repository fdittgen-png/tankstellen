// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/telemetry/process_death_context.dart';
import '../../obd2/api.dart' show ActiveTripSnapshot, Obd2CommDiagnostics;
import '../data/trip_history_entry.dart';
import '../domain/entities/gps_sample_diagnostic.dart';
import '../domain/entities/trip_termination.dart';
import '../domain/recording_session_journal.dart';
import '../domain/trip_recorder.dart';
import 'recording_lifecycle_marks_recorder.dart';

/// The history row a finished recording is saved as (#726), built beside
/// the rule that names it (#4328) rather than inline in the notifier.
///
/// ## One trip, one id
///
/// [tripId] is the id the trip's recovery rows carry — the active-trip WAL
/// row and a link drop's paused row. The stop used to key the history row
/// by the summary's start time instead, so a kill between the history write
/// and the WAL clear relaunched onto a row naming a DIFFERENT trip, and the
/// drive was saved a second time. Under one id, the launch recovery sees
/// the trip is already in history and retires the row instead.
///
/// A caller without a recovery row falls back to the summary's start time
/// (what every row saved before #4328 is keyed by — those keep loading, an
/// id is opaque to every reader), then to [now].
TripHistoryEntry finishedTripEntry(
  TripSummary summary, {
  required String? tripId,
  required DateTime now,
  required RecordingLifecycleMarksRecorder lifecycleMarks,
  bool automatic = false,
  List<TripSample> samples = const [],
  List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
  String? vehicleId,
  String? adapterMac,
  String? adapterName,
  String? adapterFirmware,
  TripTermination? termination,
  RecordingSessionJournal? sessionJournal,
}) {
  final startedAt = summary.startedAt;
  return TripHistoryEntry(
    id: tripId ?? (startedAt ?? now).toIso8601String(),
    vehicleId: vehicleId,
    summary: summary,
    automatic: automatic,
    samples: samples,
    // #1312 — adapter identity snapshotted at start time. Null for legacy
    // / fake-service code paths; the detail card hides the row then.
    adapterMac: adapterMac,
    adapterName: adapterName,
    adapterFirmware: adapterFirmware,
    // #1458 phase 2 — GPS cadence diagnostics captured during recording.
    // Empty when the GPS feature flag was off for this trip; the entry's
    // JSON serialiser elides the key in that case.
    gpsSampleDiagnostics: gpsSampleDiagnostics,
    // #3465 — background/resume marks windowed to this trip, so the GPS
    // coverage report can attribute track gaps post-hoc.
    lifecycleMarks: startedAt == null
        ? const []
        : lifecycleMarks.marksForWindow(startedAt, summary.endedAt ?? now),
    // #2912 — per-trip OBD2 comm-health diagnostic (never-throws capture).
    // #3573 — only for trips that actually bound an OBD2 service (adapter
    // identity is stamped by the OBD2 pipeline alone): the capture reads a
    // PROCESS-WIDE singleton session, so a GPS-only trip used to inherit
    // whatever idle link the supervisor happened to hold and render a
    // misleading "0% complete · 0% utilization · no dropouts" card for a
    // link the trip never touched.
    obd2Diagnostic: adapterMac == null
        ? null
        : Obd2CommDiagnostics.instance.captureForTrip(),
    // #3795/#3797 — WHY the session ended + its lifecycle timeline.
    // Defaulted to userStopped only when the caller attributed nothing: an
    // unattributed manual save IS a user stop, whereas guessing on the
    // automatic path would mislabel a grace expiry.
    termination: termination ??
        (automatic
            ? null
            : const TripTermination(TripTerminationReason.userStopped)),
    sessionJournal: sessionJournal,
  );
}

/// The history row a trip recovered after its process died is saved as
/// (#1347), under the id its WAL row carries.
TripHistoryEntry recoveredTripEntry(
  ActiveTripSnapshot snapshot,
  TripSummary summary,
) =>
    TripHistoryEntry(
      id: snapshot.id,
      vehicleId: snapshot.vehicleId,
      summary: summary,
      automatic: snapshot.automatic,
      samples: snapshot.samples,
      // #3796 — the honest label. A WAL row whose writing process is not
      // this one was left behind by a process that died: an orderly stop
      // always clears it. Until then this trip was saved indistinguishable
      // from a normal one, after being surfaced to the user as a
      // Bluetooth drop.
      termination:
          ProcessDeathContext.diedWhileRecording(snapshot.processInstanceId)
              ? TripTermination(
                  TripTerminationReason.recoveredAfterProcessDeath,
                  detail: ProcessDeathContext.terminationDetail(),
                )
              : const TripTermination(TripTerminationReason.userStopped,
                  detail: 'finalised from a recovered snapshot'),
    );
