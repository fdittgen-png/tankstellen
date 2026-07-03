// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../core/logging/error_logger.dart';
import 'last_good_adapter_store.dart';

/// #3423 — the ONE adapter-pin resolution rule (Epic #3415 task 6).
///
/// The app grew TWO unreconciled adapter pin stores:
///
///  * the **vehicle-profile MAC** (`VehicleProfile.obd2AdapterMac`) — the
///    explicit per-vehicle pairing set in the vehicle settings, and
///  * the **[LastGoodAdapterStore]** auto-pin (#3019) — stamped at the
///    connect chokepoint on EVERY successful connect, regardless of how
///    the session was started.
///
/// The in-trip reconnect target (the `DroppedSessionManager` scanner gate +
/// the reconnect-scanner factory downstream of it) was chosen from the
/// vehicle-profile MAC ONLY — so a picker-started trip whose active vehicle
/// carries no pairing got grace-window-only recovery: a mid-drive drop was
/// never reconnected even though the last-good auto-pin knew exactly which
/// adapter the live session was using.
///
/// [resolveAdapterPin] is the shared, pure resolution both sites now use:
/// **vehicle-profile MAC first** (an explicit user choice always outranks an
/// auto-pin), **else the last-good auto-pin**, else null (no scanner — the
/// grace window stays the sole recovery path, exactly as before).
enum AdapterPinSource {
  /// The explicit per-vehicle pairing (`VehicleProfile.obd2AdapterMac`).
  vehicleProfile,

  /// The #3019 auto-pin stamped on the most recent successful connect.
  lastGoodAdapter,
}

/// The resolved reconnect pin: the MAC to search for plus WHICH store it
/// came from (for traces / tests — the reconnect machinery itself only
/// needs [mac]).
class ResolvedAdapterPin {
  final String mac;
  final AdapterPinSource source;

  const ResolvedAdapterPin({required this.mac, required this.source});

  @override
  String toString() => 'ResolvedAdapterPin(mac: $mac, source: ${source.name})';
}

/// Resolve the in-trip reconnect pin (#3423): [vehicleProfileMac] first,
/// else the [recallLastGood] auto-pin, else null.
///
/// [recallLastGood] is a callback (not a value) so the fallback store is
/// only consulted when the vehicle pin is absent, and so a throwing read
/// (an unresolvable provider in a bare unit context, a corrupt settings
/// box) degrades to "no fallback pin" instead of derailing trip start —
/// this helper never throws.
ResolvedAdapterPin? resolveAdapterPin({
  String? vehicleProfileMac,
  LastGoodAdapter? Function()? recallLastGood,
}) {
  final vehicleMac = vehicleProfileMac?.trim();
  if (vehicleMac != null && vehicleMac.isNotEmpty) {
    return ResolvedAdapterPin(
      mac: vehicleMac,
      source: AdapterPinSource.vehicleProfile,
    );
  }
  LastGoodAdapter? lastGood;
  try {
    lastGood = recallLastGood?.call();
  } catch (e, st) {
    // Best-effort fallback only: a failed recall (provider unresolvable,
    // storage fault) means no auto-pin — never a thrown trip start.
    unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
      'where': 'resolveAdapterPin: last-good recall failed — no fallback pin',
    }));
  }
  final fallbackMac = lastGood?.mac.trim();
  if (fallbackMac == null || fallbackMac.isEmpty) return null;
  return ResolvedAdapterPin(
    mac: fallbackMac,
    source: AdapterPinSource.lastGoodAdapter,
  );
}

/// One-line convenience for call sites that only need the MAC (the
/// recording pipeline's `pinnedAdapterMac` thread): positional params keep
/// the at-cap pipeline file compact.
String? resolveAdapterPinMac(
  String? vehicleProfileMac,
  LastGoodAdapter? Function() recallLastGood,
) =>
    resolveAdapterPin(
      vehicleProfileMac: vehicleProfileMac,
      recallLastGood: recallLastGood,
    )?.mac;
