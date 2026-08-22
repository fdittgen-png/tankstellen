// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../obd2/api.dart';

/// Build the in-trip reattach-source factory handed to
/// `TripRecordingController` (#797 phase 3, rewritten by #3531 /
/// Epic #3527).
///
/// Historically this built an [AdapterReconnectScanner] — an in-trip
/// DIALING loop that raced the app-wide reconnect authority over the
/// adapter's single RFCOMM channel (the #3386 war; half the #3415
/// storm's connect traffic). The trip layer no longer dials at all:
/// the one [Obd2LinkSupervisor] owns reconnection, and the factory
/// returns a [SupervisorReattachSource] that merely subscribes for the
/// re-attach moment. The DroppedSessionManager's orchestration (silent
/// window, GPS-degrade, grace) is unchanged.
///
/// Returns null in tests / environments where the supervisor provider
/// can't be resolved — the controller then falls back to
/// grace-window-only recovery.
///
/// [onConnected] is invoked with the freshly-reconnected service so the
/// pipeline can swap its `_service` pointer AND the controller's via
/// `replaceService` (#2524). The `pinnedMac` factory parameter is kept
/// for seam compatibility (the supervisor's own dial policy already
/// targets the pinned adapter, #3016).
Obd2ReattachSource? Function(
  String pinnedMac,
  VoidCallback onReconnect,
)? buildReconnectScannerFactory({
  required Ref ref,
  required void Function(Obd2Service service) onConnected,
  // Kept for seam compatibility with existing call sites; the supervisor
  // reads the live transport kind itself at dial time.
  String? Function()? readLinkKind,
  String? Function()? readAdapterName,
}) {
  final Obd2LinkSupervisor supervisor;
  try {
    supervisor = ref.read(obd2ReconnectProvider.notifier).supervisor;
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
      'where': 'Obd2RecordingPipeline: link supervisor unavailable'
    }));
    return null;
  }
  return (pinnedMac, onReconnect) => SupervisorReattachSource(
        supervisor,
        onConnected: onConnected,
        onReconnect: onReconnect,
      );
}
