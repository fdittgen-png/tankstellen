// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'adapter_registry.dart';
import 'obd2_comm_diagnostics.dart' show redactObd2Mac;
import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
import 'obd2_service.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/domain/vehicle_profile.dart';

/// Adapter-identity capture + iOS UUID-rotation rematch (#3168).
///
/// On iOS a BLE `deviceId` is Apple's per-app **CBPeripheral UUID** — not the
/// adapter's MAC — and the OS can ROTATE it (Bluetooth reset, unpair, device
/// restore, adapter re-provision). Every pinned fast path keys on the stored
/// id, and the scan fallback used to match strictly on it, so after a
/// rotation the paired adapter could never re-match again: reconnect was
/// broken forever with no recovery besides re-running the picker (the
/// suspected OBDLink CX field signature; the `pinned-id-mismatch` trace step
/// from #3184(e) is its discriminator). This file is the data-layer seam for
/// both halves of the fix:
///
///  1. **Identity capture** — [Obd2AdapterIdentity.fromCandidate], moved out
///     of the picker widget (which used an inline `Platform.isIOS`, #2350
///     debt). Platform-free by construction: [looksLikeIosPeripheralUuid]
///     tells an iOS CBPeripheral UUID apart from an Android MAC by SHAPE,
///     so no shared code branches on the runtime platform.
///  2. **Name-based rematch** — [Obd2UuidRematchDecision.decide] (the pure
///     decision table) + [connectUuidRematched] (the connect + re-persist
///     driver the scan fallback calls when the pinned id is absent from a
///     non-empty scan).
///
/// Harmless on Android by construction: a MAC-shaped pinned id is never
/// rematch-eligible (Android MACs are stable, and a same-named device under
/// a different MAC there is genuinely a DIFFERENT adapter).

/// Shape of an iOS CBPeripheral identifier: the canonical 36-char UUID
/// (8-4-4-4-12 hex). Android BLE/Classic deviceIds are colon-separated MACs
/// and never match.
final RegExp _iosPeripheralUuidShape = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// True when [id] has the SHAPE of an iOS CBPeripheral UUID (8-4-4-4-12
/// hex). The platform-free discriminator this seam is built on: on iOS
/// `flutter_blue_plus` surfaces `remoteId.str` as exactly this UUID, on
/// Android as a `AA:BB:CC:DD:EE:FF` MAC — so shape ≡ platform without any
/// `Platform.isIOS` in shared code (#2350).
bool looksLikeIosPeripheralUuid(String id) =>
    _iosPeripheralUuidShape.hasMatch(id.trim());

/// The friendly name a candidate is persisted/displayed under everywhere
/// (picker tile, vehicle profile, connect trace headline): the advertised
/// name, or the matched profile's display label when the advertisement was
/// anonymous. ONE definition so capture and rematch can never disagree.
String effectiveCandidateName(ResolvedObd2Candidate c) =>
    c.candidate.deviceName.isEmpty
        ? c.profile.displayName
        : c.candidate.deviceName;

/// Persistable identity of a picked/rematched adapter (#3168) — the three
/// fields the vehicle profile pins (`obd2AdapterMac`, `obd2AdapterName`,
/// `pairedAdapterUuidIos`).
class Obd2AdapterIdentity {
  /// Platform device id — Android MAC, or the iOS CBPeripheral UUID.
  final String deviceId;

  /// Friendly adapter name ([effectiveCandidateName]).
  final String name;

  /// The iOS CoreBluetooth reconnection key (#2282 concern 3): equals
  /// [deviceId] when it is UUID-shaped (iOS), null when it is a MAC
  /// (Android) — mirroring what the picker's old `Platform.isIOS` capture
  /// persisted, without the platform check.
  final String? uuidIos;

  const Obd2AdapterIdentity({
    required this.deviceId,
    required this.name,
    this.uuidIos,
  });

  /// Capture the identity to persist for [c] — the single data-layer
  /// replacement for the picker widget's inline capture.
  factory Obd2AdapterIdentity.fromCandidate(ResolvedObd2Candidate c) {
    final id = c.candidate.deviceId;
    return Obd2AdapterIdentity(
      deviceId: id,
      name: effectiveCandidateName(c),
      uuidIos: looksLikeIosPeripheralUuid(id) ? id : null,
    );
  }
}

/// Re-persist seam fired AFTER a successful UUID-rotation rematch connect
/// (#3168): [staleId] is the pinned id that no longer matches; [fresh] the
/// identity the adapter now advertises under. Wired by the provider layer
/// to update the vehicle profile(s) pinned to the stale id.
typedef Obd2AdapterIdentityRotated = Future<void> Function({
  required String staleId,
  required Obd2AdapterIdentity fresh,
});

/// Terminal states of the rematch decision table (#3168).
enum Obd2UuidRematchResult {
  /// The pinned id is not rotation-prone (Android MAC shape) or there is
  /// no persisted name to rematch by. Never rematch.
  notEligible,

  /// Eligible, but no scanned device advertises the persisted name under
  /// a different id.
  noCandidate,

  /// Two or more scanned devices advertise the persisted name — picking
  /// one would be a guess, so the rematch is skipped (the picker fallback
  /// lets the user disambiguate).
  ambiguous,

  /// Exactly one scanned device advertises the persisted name under a
  /// fresh id — the rotated-UUID signature. Connect to it.
  matched,
}

/// Outcome of [decide] — the pure, unit-testable rematch decision (#3168).
class Obd2UuidRematchDecision {
  final Obd2UuidRematchResult result;

  /// The single rematch candidate; non-null iff [result] is
  /// [Obd2UuidRematchResult.matched].
  final ResolvedObd2Candidate? candidate;

  /// How many same-named candidates were in the scan (diagnostic detail
  /// for the ambiguous trace step).
  final int candidateCount;

  const Obd2UuidRematchDecision._(
      this.result, this.candidate, this.candidateCount);

  /// The #3168 decision table. [pinnedId]/[pinnedName] are the persisted
  /// identity; [ranked] the accumulated scan result. Pure — no IO, no
  /// trace writes — so the table is exhaustively unit-testable.
  static Obd2UuidRematchDecision decide({
    required String pinnedId,
    required String? pinnedName,
    required List<ResolvedObd2Candidate> ranked,
  }) {
    if (pinnedName == null || pinnedName.trim().isEmpty) {
      return const Obd2UuidRematchDecision._(
          Obd2UuidRematchResult.notEligible, null, 0);
    }
    // Android MACs are stable — a MAC-shaped pinned id must never rematch
    // (a same-named device under another MAC is a different adapter there).
    if (!looksLikeIosPeripheralUuid(pinnedId)) {
      return const Obd2UuidRematchDecision._(
          Obd2UuidRematchResult.notEligible, null, 0);
    }
    final pinnedUpper = pinnedId.trim().toUpperCase();
    final candidates = <ResolvedObd2Candidate>[
      for (final r in ranked)
        if (effectiveCandidateName(r) == pinnedName &&
            r.candidate.deviceId.trim().toUpperCase() != pinnedUpper)
          r,
    ];
    if (candidates.isEmpty) {
      return const Obd2UuidRematchDecision._(
          Obd2UuidRematchResult.noCandidate, null, 0);
    }
    if (candidates.length > 1) {
      return Obd2UuidRematchDecision._(
          Obd2UuidRematchResult.ambiguous, null, candidates.length);
    }
    return Obd2UuidRematchDecision._(
        Obd2UuidRematchResult.matched, candidates.single, 1);
  }
}

/// Drive the #3168 rematch for a scan fallback that found NO exact-id match:
/// decide via [Obd2UuidRematchDecision.decide], stamp the decision onto the
/// active connect trace (`uuid-rematch` step), connect to the rematched
/// candidate via [connect], and on SUCCESS fire [onIdentityRotated] so the
/// fresh UUID is re-persisted (`uuid-repersist` step).
///
/// Returns null when the decision is anything but matched (the caller falls
/// back to the picker exactly as before — behaviour is never worse than
/// today). A connect failure on the rematched candidate propagates like the
/// exact-id path's would. The re-persist is best-effort: a throwing
/// [onIdentityRotated] is logged + stamped and never re-thrown, so it can
/// never derail the connect that just succeeded.
Future<Obd2Service?> connectUuidRematched({
  required String pinnedId,
  required String? pinnedName,
  required List<ResolvedObd2Candidate> ranked,
  required Future<Obd2Service> Function(ResolvedObd2Candidate candidate)
      connect,
  required Obd2AdapterIdentityRotated? onIdentityRotated,
}) async {
  final decision = Obd2UuidRematchDecision.decide(
    pinnedId: pinnedId,
    pinnedName: pinnedName,
    ranked: ranked,
  );
  switch (decision.result) {
    case Obd2UuidRematchResult.notEligible:
    case Obd2UuidRematchResult.noCandidate:
      return null;
    case Obd2UuidRematchResult.ambiguous:
      Obd2ConnectTraceLog.active?.addStep(
        label: 'uuid-rematch',
        status: Obd2ConnectStepStatus.fail,
        detail: '${decision.candidateCount} scanned devices named '
            '"$pinnedName" — ambiguous, rematch skipped (#3168)',
      );
      return null;
    case Obd2UuidRematchResult.matched:
      break;
  }
  final candidate = decision.candidate!;
  final fresh = Obd2AdapterIdentity.fromCandidate(candidate);
  Obd2ConnectTraceLog.active?.addStep(
    label: 'uuid-rematch',
    status: Obd2ConnectStepStatus.ok,
    detail: 'pinned id ${redactObd2Mac(pinnedId)} absent from scan but '
        '"$pinnedName" advertises under ${redactObd2Mac(fresh.deviceId)} — '
        'iOS CBPeripheral UUID rotated; connecting to the fresh id (#3168)',
  );
  final service = await connect(candidate);
  // The connect SUCCEEDED on the fresh id — re-persist it so the next
  // session's pinned fast path dials the right peripheral. Best-effort.
  if (onIdentityRotated != null) {
    try {
      await onIdentityRotated(staleId: pinnedId, fresh: fresh);
      Obd2ConnectTraceLog.active?.addStep(
        label: 'uuid-repersist',
        status: Obd2ConnectStepStatus.ok,
        detail: 'pinned identity updated '
            '${redactObd2Mac(pinnedId)} → ${redactObd2Mac(fresh.deviceId)}',
      );
    } catch (e, st) {
      Obd2ConnectTraceLog.active?.addStep(
        label: 'uuid-repersist',
        status: Obd2ConnectStepStatus.fail,
        detail: e.toString(),
      );
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'connectUuidRematched: identity re-persist failed (#3168)',
      }));
    }
  }
  return service;
}

/// Update every vehicle profile pinned to [staleId] (by `obd2AdapterMac` or
/// `pairedAdapterUuidIos`, case-insensitively) to the [fresh] identity —
/// the provider-layer body behind the [Obd2AdapterIdentityRotated] seam.
///
/// Only the two IDENTITY fields rotate; the user-facing `obd2AdapterName`
/// and every other preference on the profile are deliberately left intact
/// (#3168 — the rematch was keyed on that very name). Never throws: a
/// failing [save] is logged as a storage error and swallowed, so the
/// connect that triggered the rotation is never derailed.
Future<void> repersistRotatedAdapterIdentity({
  required List<VehicleProfile> profiles,
  required Future<void> Function(VehicleProfile profile) save,
  required String staleId,
  required Obd2AdapterIdentity fresh,
}) async {
  try {
    final stale = staleId.trim().toUpperCase();
    for (final p in profiles) {
      final mac = p.obd2AdapterMac?.trim().toUpperCase();
      final uuid = p.pairedAdapterUuidIos?.trim().toUpperCase();
      if (mac != stale && uuid != stale) continue;
      await save(p.copyWith(
        obd2AdapterMac: fresh.deviceId,
        pairedAdapterUuidIos: fresh.uuidIos,
      ));
    }
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
      'where': 'repersistRotatedAdapterIdentity failed (#3168)',
    }));
  }
}
