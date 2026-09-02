// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/guarded.dart';
import '../../../core/time/app_clock.dart';
import '../../obd2/api.dart';
import 'recording_gps_fix_provider.dart';
import 'trip_recording_provider.dart';

/// What the OBD2 link is doing for the running recording, in the five
/// plain-language states the recording screen's status chip renders
/// (#3916, Epic #3914). Sealed so the chip and its sheet switch
/// exhaustively and stay pure presentation.
@immutable
sealed class RecordingObd2Status {
  const RecordingObd2Status();
}

/// Engine data is flowing. [readsPerSecond] is the scheduler's achieved
/// PID read rate when the reading carried one.
class Obd2StatusLive extends RecordingObd2Status {
  const Obd2StatusLive({this.readsPerSecond});
  final int? readsPerSecond;

  @override
  bool operator ==(Object other) =>
      other is Obd2StatusLive && other.readsPerSecond == readsPerSecond;

  @override
  int get hashCode => Object.hash(runtimeType, readsPerSecond);
}

/// The link dropped and the supervisor's backoff loop is dialing.
/// [attempt] is the 1-based attempt ordinal when the supervisor is
/// reachable.
class Obd2StatusReconnecting extends RecordingObd2Status {
  const Obd2StatusReconnecting({this.attempt});
  final int? attempt;

  @override
  bool operator ==(Object other) =>
      other is Obd2StatusReconnecting && other.attempt == attempt;

  @override
  int get hashCode => Object.hash(runtimeType, attempt);
}

/// The adapter is gone and the loop passively waits for it; the trip
/// keeps recording on GPS.
class Obd2StatusGpsOnly extends RecordingObd2Status {
  const Obd2StatusGpsOnly();

  @override
  bool operator ==(Object other) => other is Obd2StatusGpsOnly;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// The engine is off — nothing is broken, the recording waits (#3858).
class Obd2StatusEngineOff extends RecordingObd2Status {
  const Obd2StatusEngineOff();

  @override
  bool operator ==(Object other) => other is Obd2StatusEngineOff;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// A trip recorded without any adapter (the GPS-only trip kind).
class Obd2StatusNoAdapter extends RecordingObd2Status {
  const Obd2StatusNoAdapter();

  @override
  bool operator ==(Object other) => other is Obd2StatusNoAdapter;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Horizontal-accuracy band of the latest fix.
enum GpsFixQuality {
  /// Accuracy radius at or under [RecordingGpsStatus.preciseAccuracyM].
  precise,

  /// A recent fix whose accuracy radius is coarser than the precise band.
  approximate,

  /// A recent fix that carried no accuracy figure.
  unknownAccuracy,

  /// No fix, or the last one is older than [RecordingGpsStatus.staleAfter].
  none,
}

/// What GPS is doing for the running recording (#3916).
@immutable
class RecordingGpsStatus {
  const RecordingGpsStatus({
    required this.quality,
    this.accuracyM,
    this.coveragePercent,
  });

  /// Accuracy radius (metres) at or under which a fix reads "precise".
  static const double preciseAccuracyM = 15.0;

  /// A fix older than this no longer counts as a fix.
  static const Duration staleAfter = Duration(seconds: 15);

  final GpsFixQuality quality;

  /// Accuracy radius of the latest fix in whole metres, when known.
  final int? accuracyM;

  /// Coverage so far (see [RecordingGpsFix.coveragePercent]), when known.
  final int? coveragePercent;

  static const RecordingGpsStatus noFix =
      RecordingGpsStatus(quality: GpsFixQuality.none);

  @override
  bool operator ==(Object other) =>
      other is RecordingGpsStatus &&
      other.quality == quality &&
      other.accuracyM == accuracyM &&
      other.coveragePercent == coveragePercent;

  @override
  int get hashCode => Object.hash(quality, accuracyM, coveragePercent);
}

/// The recording screen's status-strip value: OBD2 + GPS + the adapter
/// name for the sheet title (#3916).
@immutable
class RecordingLinkStatus {
  const RecordingLinkStatus({
    required this.obd2,
    required this.gps,
    this.adapterName,
  });

  final RecordingObd2Status obd2;
  final RecordingGpsStatus gps;
  final String? adapterName;

  @override
  bool operator ==(Object other) =>
      other is RecordingLinkStatus &&
      other.obd2 == obd2 &&
      other.gps == gps &&
      other.adapterName == adapterName;

  @override
  int get hashCode => Object.hash(obd2, gps, adapterName);
}

/// Pure derivation of the OBD2 status from the recording phase, the link
/// state and the live reading (#3916). Extracted so the decision table
/// is unit-testable without a provider container.
///
/// Precedence:
///  1. a GPS-only trip kind never had an adapter → [Obd2StatusNoAdapter];
///  2. both sources dead ([TripRecordingPhase.pausedDueToDrop]) or an
///     engine-off drop reason / parked link → reconnecting / engine off;
///  3. degraded on GPS: passive wait → [Obd2StatusGpsOnly], else the
///     reconnect in flight;
///  4. otherwise live engine data (or a ready link warming up) → live;
///     a reconnecting link → reconnecting; a parked link → engine off;
///     an idle / user-disconnected link with no engine data → GPS only.
RecordingObd2Status deriveObd2Status({
  required TripRecordingPhase phase,
  required TripDropReason? dropReason,
  required bool reconnectPassiveWaiting,
  required bool hasEngineData,
  required int? readsPerSecond,
  required Obd2LinkState link,
  required bool gpsOnlyTripKind,
  required int? attempt,
}) {
  if (gpsOnlyTripKind) return const Obd2StatusNoAdapter();
  final engineOff =
      dropReason == TripDropReason.engineOff || link == Obd2LinkState.engineOff;
  switch (phase) {
    case TripRecordingPhase.pausedDueToDrop:
      return engineOff
          ? const Obd2StatusEngineOff()
          : Obd2StatusReconnecting(attempt: attempt);
    case TripRecordingPhase.degradedGpsOnly:
      if (engineOff) return const Obd2StatusEngineOff();
      if (reconnectPassiveWaiting) return const Obd2StatusGpsOnly();
      return Obd2StatusReconnecting(attempt: attempt);
    case TripRecordingPhase.idle:
    case TripRecordingPhase.connecting:
    case TripRecordingPhase.recording:
    case TripRecordingPhase.paused:
    case TripRecordingPhase.saving:
    case TripRecordingPhase.finished:
      if (hasEngineData) return Obd2StatusLive(readsPerSecond: readsPerSecond);
      switch (link) {
        case Obd2LinkState.ready:
        case Obd2LinkState.connecting:
          return Obd2StatusLive(readsPerSecond: readsPerSecond);
        case Obd2LinkState.reconnecting:
          return Obd2StatusReconnecting(attempt: attempt);
        case Obd2LinkState.engineOff:
          return const Obd2StatusEngineOff();
        case Obd2LinkState.idle:
        case Obd2LinkState.userDisconnected:
          return const Obd2StatusGpsOnly();
      }
  }
}

/// Pure derivation of the GPS status from the latest fix and the clock
/// (#3916).
RecordingGpsStatus deriveGpsStatus(RecordingGpsFix? fix, DateTime now) {
  if (fix == null) return RecordingGpsStatus.noFix;
  final coverage = fix.coveragePercent;
  if (now.difference(fix.fixAt) > RecordingGpsStatus.staleAfter) {
    return RecordingGpsStatus(
      quality: GpsFixQuality.none,
      coveragePercent: coverage,
    );
  }
  final accuracy = fix.accuracyM;
  if (accuracy == null) {
    return RecordingGpsStatus(
      quality: GpsFixQuality.unknownAccuracy,
      coveragePercent: coverage,
    );
  }
  return RecordingGpsStatus(
    quality: accuracy <= RecordingGpsStatus.preciseAccuracyM
        ? GpsFixQuality.precise
        : GpsFixQuality.approximate,
    accuracyM: accuracy.round(),
    coveragePercent: coverage,
  );
}

/// The recording screen's OBD2 + GPS status (#3916), derived from the
/// recording phase, the ONE reconnect owner's link state, the adapter
/// snapshot and the live GPS fix seam. Every hot value is `select`ed so
/// the 4 Hz live reading only re-derives this when a field the strip
/// shows actually changes; the elapsed-seconds select is the deliberate
/// 1 Hz tick that refreshes the reconnect attempt ordinal and the fix
/// staleness.
final recordingLinkStatusProvider =
    Provider.autoDispose<RecordingLinkStatus>((ref) {
  final phase = ref.watch(tripRecordingProvider.select((s) => s.phase));
  final dropReason =
      ref.watch(tripRecordingProvider.select((s) => s.dropReason));
  final passiveWaiting = ref
      .watch(tripRecordingProvider.select((s) => s.reconnectPassiveWaiting));
  final hasEngineData = ref.watch(tripRecordingProvider.select(
      (s) => s.live?.rpm != null || s.live?.fuelRateLPerHour != null));
  final readsPerSecond = ref.watch(tripRecordingProvider
      .select((s) => s.live?.obd2ReadsPerSecond?.round()));
  // 1 Hz tick — attempt ordinal + fix staleness are clock-driven.
  ref.watch(tripRecordingProvider.select((s) => s.live?.elapsed.inSeconds));
  final link = ref.watch(obd2ReconnectProvider);
  final adapterName =
      ref.watch(obd2ConnectionStatusProvider.select((s) => s.adapterName));
  final fix = ref.watch(recordingGpsFixProvider);
  final now = ref.watch(appClockProvider).now();

  // Non-reactive reads, both guarded: the trip kind is fixed for the
  // trip's lifetime (re-read on every phase change above), and the
  // supervisor is unreachable on a pinned test notifier.
  final gpsOnlyTripKind = guard(
    () => ref.read(tripRecordingProvider.notifier).isGpsOnlyTripActive,
    where: 'recordingLinkStatus: trip kind read failed',
    fallback: false,
  );
  final attempt = link == Obd2LinkState.reconnecting
      ? guard<int?>(
          () => ref.read(obd2ReconnectProvider.notifier).supervisor.attemptNumber,
          where: 'recordingLinkStatus: attempt read failed',
          fallback: null,
        )
      : null;

  return RecordingLinkStatus(
    obd2: deriveObd2Status(
      phase: phase,
      dropReason: dropReason,
      reconnectPassiveWaiting: passiveWaiting,
      hasEngineData: hasEngineData,
      readsPerSecond: readsPerSecond,
      link: link,
      gpsOnlyTripKind: gpsOnlyTripKind,
      attempt: attempt,
    ),
    gps: deriveGpsStatus(fix, now),
    adapterName: adapterName,
  );
});
