// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';
// #3776 — Obd2LinkSupervisorActions.reportServiceDead (extension scope).
import '../data/session/obd2_link_supervisor.dart';
import '../data/session/obd2_service.dart';
import '../data/obd2_session_context_block.dart';
import 'obd2_reconnect_provider.dart';

/// #3527 keep-link semantics for trip teardown.
///
/// Trip end is a TRIP concern, not a link concern: when [svc] is the
/// link supervisor's current live service, it must be LEFT CONNECTED —
/// the supervisor keeps supervising (the dot stays green, auto-record's
/// next trip needs no fresh dial, and a parked car converges to the
/// engineOff state via the adapter's own sleep → drop → dial →
/// silent-bus classification). Only a service the supervisor does NOT
/// own (test-injected / legacy path) is torn down, else it would leak.
Future<void> teardownServiceRespectingSupervisor(
  Ref ref,
  Obd2Service svc,
) async {
  if (supervisorOwnsService(ref, svc)) return;
  try {
    await svc.disconnect();
  } catch (e, st) {
    // #2472 — context adds the obd2Session block only when dev-armed.
    log.error(e, st, layer: ErrorLayer.providers, context: obd2DisconnectTraceContext());
  }
}

/// #3776 — the trip layer never closes a supervisor-owned link: a dead
/// one is handed to the owner, which closes and redials. False when the
/// owner declined it, or when there is no supervisor graph (widget tests,
/// the legacy path) — the caller then closes the service itself. Moved
/// out of `Obd2RecordingPipeline` unchanged (#4344, its line cap).
bool reportDeadLinkToSupervisor(Ref ref, Obd2Service svc, String reason) {
  try {
    return ref
        .read(obd2ReconnectProvider.notifier)
        .supervisor
        .reportServiceDead(svc, reason: reason);
  } catch (_) {
    // No supervisor graph (widget tests / legacy path) — the
    // caller closes the service itself.
    return false;
  }
}

/// Whether [svc] is the link supervisor's current live service.
/// Best-effort: an unresolvable provider graph (widget tests) reads as
/// "not owned", preserving the legacy teardown.
bool supervisorOwnsService(Ref ref, Obd2Service svc) {
  try {
    return identical(
        ref.read(obd2ReconnectProvider.notifier).supervisor.service, svc);
  } catch (_) {
    // ignore: silent_catch — no supervisor in this graph ⇒ legacy teardown path
    return false;
  }
}
