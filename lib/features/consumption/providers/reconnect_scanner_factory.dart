// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../data/obd2/adapter_reconnect_scanner.dart';
import '../data/obd2/obd2_connection_service.dart';
import '../data/obd2/obd2_service.dart';
import '../data/obd2/reconnect_connector.dart';

/// Build the reconnect-scanner factory handed to `TripRecordingController`
/// (#797 phase 3), extracted out of `Obd2RecordingPipeline` as a free
/// function so threading the live transport kind through the connector keeps
/// the pipeline under the #1680 file-length cap (sanctioned #2190
/// decomposition — move-only, behaviour preserved + the #2565 hint thread).
///
/// Returns null in tests / environments where [obd2ConnectionProvider] can't
/// be resolved — the controller then falls back to grace-window-only
/// recovery.
///
/// [onConnected] is invoked with the freshly-reconnected service so the
/// pipeline can swap its `_service` pointer AND the controller's via
/// `replaceService` (#2524). [readLinkKind] reads the (dead-but-typed) live
/// service's `linkKind` at handle-drop time so the connector dispatches the
/// reconnect over the SAME transport that just dropped (#2565) — a Classic
/// adapter reconnects over RFCOMM, not a doomed 4 s BLE GATT timeout.
AdapterReconnectScanner? Function(
  String pinnedMac,
  VoidCallback onReconnect,
)? buildReconnectScannerFactory({
  required Ref ref,
  required void Function(Obd2Service service) onConnected,
  required String? Function() readLinkKind,
}) {
  final Obd2ConnectionService connection;
  try {
    connection = ref.read(obd2ConnectionProvider);
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
      'where': 'Obd2RecordingPipeline: connection provider unavailable'
    }));
    return null;
  }
  return (pinnedMac, onReconnect) {
    // One connector per drop holds the gate bookkeeping across the
    // scanner's repeated connect cycles. The connect callback prefers a
    // DIRECT connect over the LIVE transport kind (#2565) — Classic goes
    // straight to RFCOMM, BLE keeps its direct-GATT-first path (#2245) —
    // and only falls back to a transport-aware RSSI-gated scan.
    // #2524 — swap the pipeline's pointer (so stop() tears down the LIVE
    // svc) AND the controller's via `replaceService` (so the loop polls the
    // reconnected transport, not the closed one).
    final connector = ReconnectConnector(
      connection: connection,
      onConnected: onConnected,
      // #2565 — the transport kind ('ble'/'classic') of the link that just
      // dropped, read off the dead service. Null when unknown ⇒ the legacy
      // BLE-direct-first path (behaviour unchanged for BLE adapters).
      transportHint: readLinkKind(),
    );
    final scanner = AdapterReconnectScanner(
      pinnedMac: pinnedMac,
      probe: (mac) async => true,
      connect: connector.attempt,
      // #2261 concern 2 — after the active-scan miss ceiling switch to a
      // passive autoConnect GATT wait for the rest of the 15-min grace.
      passiveConnect: connector.attemptPassive,
      onReconnect: onReconnect,
    );
    // #2905 — let the connector's per-attempt telemetry rows carry the
    // scanner's live episode ordinal + backoff. Wired here (not via the ctor)
    // so the connector→scanner dependency stays one-directional.
    connector
      ..attemptNumber = (() => scanner.currentAttemptNumber)
      ..backoffMs = (() => scanner.currentBackoffMs);
    return scanner;
  };
}
