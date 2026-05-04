// Surfaces the runtime [Obd2AdapterCapability] of the currently
// connected adapter (#1401 phase 6).
//
// Design choice (recorded for the next reader):
//
//   The capability lives on the live [Obd2Service] instance, which
//   is held privately by the auto-record orchestrator + trip
//   recording controller — neither exposes its service via Riverpod.
//   Rather than introduce a fourth owner of the live service, this
//   phase extends [Obd2ConnectionSnapshot] with a `capability` field
//   stamped by [Obd2ConnectionStatus.markConnected], and this provider
//   simply selects it. Producers (the eventual boot-probe / pair flow)
//   will pass `service.capability` into `markConnected` once the
//   shared "live OBD2 service" plumbing lands; until then the UI
//   gracefully renders nothing (the section collapses to
//   `SizedBox.shrink`).
//
// Stateless and side-effect-free — purely derived from
// [obd2ConnectionStatusProvider] so it has zero lifecycle of its own.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/obd2/adapter_capability.dart';
import 'obd2_connection_state_provider.dart';

part 'obd2_capability_provider.g.dart';

/// Current adapter's runtime [Obd2AdapterCapability], or null when no
/// adapter is connected (#1401 phase 6).
///
/// Returns a non-null value only when [Obd2ConnectionStatus] is in
/// the [Obd2ConnectionState.connected] state AND the producer that
/// flipped it stamped a capability. Every other state — idle,
/// attempting, unreachable, permissionDenied, or connected without a
/// capability stamp — yields null so the UI can collapse the
/// capability section.
@riverpod
Obd2AdapterCapability? currentObd2Capability(Ref ref) {
  final snapshot = ref.watch(obd2ConnectionStatusProvider);
  if (snapshot.state != Obd2ConnectionState.connected) return null;
  return snapshot.capability;
}
