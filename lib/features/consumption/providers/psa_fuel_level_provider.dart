// PSA passive-CAN fuel-level stream provider (#1418).
//
// Wires the data-layer [Obd2Service.canFrameStream] (the streaming
// transport added by #1418) through the pure-data
// [PsaFuelLevelCanDecoder] (#1401 phase 5 / PR #1417) and exposes the
// resulting litres-in-tank stream behind a Riverpod `StreamProvider`.
//
// ## Capability gate
//
// The decoder only makes sense on STN-chip adapters that support
// passive listen-mode (`STMA` / `ATCRA`) — i.e. exactly
// [Obd2AdapterCapability.passiveCanCapable]. Lower tiers
// ([standardOnly], [oemPidsCapable]) fall through to the active-poll
// `PsaOemPidTable` path that phase 4 ships; emitting nothing here is
// the expected, "not supported on this adapter" first-class state.
// We deliberately do NOT throw — the trip-recording flow's
// `ref.listen` opt-in (separate epic phase) treats "no events" as
// "no passive samples this trip" and rolls forward unchanged.
//
// ## Service injection seam
//
// The live [Obd2Service] is owned outside Riverpod today (the
// auto-record orchestrator + trip recording controller hold it
// privately). Rather than introduce a fourth owner of the live
// service, this file exposes [psaFuelLevelObd2ServiceProvider] as an
// override seam: in production it returns `null` (the wiring epic
// that propagates the live service across providers is filed
// separately); in tests it's overridden with a service backed by a
// fake transport.
//
// While the production wiring is incomplete, [psaFuelLevelProvider]
// emits no events — exactly the same shape as a real
// `standardOnly` adapter. The trip recorder's opt-in subscription
// works either way.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/obd2/adapter_capability.dart';
import '../data/obd2/can_frame_decoders/psa_fuel_level_can_decoder.dart';
import '../data/obd2/obd2_service.dart';

part 'psa_fuel_level_provider.g.dart';

/// Override seam for the live [Obd2Service] (#1418).
///
/// Returns `null` in production — the live service is currently
/// owned by `Obd2ConnectionService` / the trip-recording stack and
/// is not exposed through Riverpod. The follow-up epic that
/// elevates the live service into Riverpod will replace this
/// default; until then [psaFuelLevelProvider] emits an empty stream
/// (the gate falls through to the `null` branch below).
///
/// Tests override this with a service backed by a fake transport so
/// they can exercise the gate + decoder pipe without touching real
/// Bluetooth.
@riverpod
Obd2Service? psaFuelLevelObd2Service(Ref ref) => null;

/// Stream of decoded litres-in-tank from the PSA instrument-cluster
/// passive-CAN broadcast frame `0x0E6` (#1418).
///
/// Emits nothing (no events, never errors) when:
///   * the live [Obd2Service] override seam is unset
///     ([psaFuelLevelObd2ServiceProvider] returns `null`), or
///   * the connected adapter's runtime capability tier is not
///     [Obd2AdapterCapability.passiveCanCapable].
///
/// Otherwise subscribes to [Obd2Service.canFrameStream] and pipes
/// the raw `(id, payload)` records through
/// [PsaFuelLevelCanDecoder.filterFuelLevelStream] which yields one
/// litres value per successfully-decoded frame.
///
/// `keepAlive: false` — listener teardown is automatic when no UI
/// subscribes, which sends `STMP` to the adapter so the bus returns
/// to normal mode. The trip-recording flow can opt in via
/// `ref.listen` in a separate epic phase.
@riverpod
Stream<double> psaFuelLevel(Ref ref) {
  final service = ref.watch(psaFuelLevelObd2ServiceProvider);
  if (service == null) {
    // No live service plumbed in yet — empty stream is the
    // first-class "not available" state. The decoder + gate fire
    // only when the override seam returns a real service.
    return const Stream<double>.empty();
  }
  if (service.capability != Obd2AdapterCapability.passiveCanCapable) {
    // Capability gate (#1418): exact match. `oemPidsCapable` and
    // `standardOnly` fall through to the active-poll PSA OEM PID
    // table; this provider is the passive-only branch.
    return const Stream<double>.empty();
  }
  const decoder = PsaFuelLevelCanDecoder();
  return decoder.filterFuelLevelStream(service.canFrameStream());
}
