// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/logging/error_logger.dart';
import 'adapter_registry.dart';
import 'obd2_connection_service.dart';
import 'obd2_service.dart';
import 'reconnect_rssi_gate.dart';

/// Drives a single in-trip reconnect attempt for a pinned adapter MAC,
/// DIRECT-CONNECT-FIRST with an RSSI-gated scan fallback (#2245).
///
/// Pulled out of `_buildReconnectScannerFactory` so the connect policy
/// is unit-testable in isolation against a real [Obd2ConnectionService]
/// + fake facade, rather than buried in a provider closure.
///
/// One instance lives per drop (per [AdapterReconnectScanner] the
/// controller builds), holding the small mutable bookkeeping the gate
/// needs across the scanner's repeated connect cycles:
///   * the strongest sighting seen so far ([_lastCandidate]),
///   * the RSSI at the last SUCCESSFUL connect ([_lastSuccessfulRssi]) —
///     the relative-RSSI gate baseline, and
///   * how many back-to-back scan batches have carried the MAC
///     ([_consecutiveBatchesSeen]).
///
/// On a successful connect the new [Obd2Service] is handed to
/// [onConnected] (the provider swaps its owned `_service` pointer) and
/// the attempt returns `true`.
class ReconnectConnector {
  final Obd2ConnectionService connection;

  /// Hook invoked with the freshly-connected service so the owner can
  /// swap its service pointer. Fired exactly once per successful attempt.
  final void Function(Obd2Service service) onConnected;

  ResolvedObd2Candidate? _lastCandidate;
  int? _lastSuccessfulRssi;
  var _consecutiveBatchesSeen = 0;

  ReconnectConnector({
    required this.connection,
    required this.onConnected,
  });

  /// Strongest-seen candidate from the scan fallback. Exposed for tests.
  ResolvedObd2Candidate? get lastCandidate => _lastCandidate;

  /// RSSI recorded at the last successful scan-path connect this drop —
  /// the relative gate baseline. Null until a scan-path connect lands.
  int? get lastSuccessfulRssi => _lastSuccessfulRssi;

  /// Run one connect cycle for [mac]: direct first, gated scan fallback.
  /// Returns `true` once a session is established. Never throws —
  /// failures are logged and surfaced as `false` so the scanner keeps
  /// its backoff schedule.
  Future<bool> attempt(String mac) async {
    // 1) DIRECT-CONNECT FIRST — no scan. `fallbackToScan: false` keeps
    //    the service from running its own (ungated) scan fallback, so we
    //    never double-scan: the single scan below is ours and is gated.
    try {
      final direct = await connection.connectByMacDirect(
        mac,
        fallbackToScan: false,
      );
      if (direct != null) {
        // A direct connect carries no RSSI (it never scanned), so the
        // relative-RSSI baseline is left as-is — it is only ever set
        // from a scan-path candidate, which has a real RSSI reading.
        onConnected(direct);
        return true;
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'ReconnectConnector direct connect failed',
      }));
    }

    // 2) SCAN FALLBACK (ultimate). One scan window: track the strongest
    //    sighting + consecutive-batch count, and only connect when the
    //    relative-RSSI / two-batch gate passes.
    try {
      await for (final batch in connection.scan()) {
        final seen = batch.where((c) => c.candidate.deviceId == mac);
        if (seen.isEmpty) {
          _consecutiveBatchesSeen = 0;
          continue;
        }
        _consecutiveBatchesSeen++;
        // Refresh lastCandidate to the strongest-seen advertisement.
        for (final c in seen) {
          if (_lastCandidate == null ||
              c.candidate.rssi > _lastCandidate!.candidate.rssi) {
            _lastCandidate = c;
          }
        }
        final candidate = _lastCandidate!;
        if (!shouldConnectFromScan(
          lastSuccessfulRssi: _lastSuccessfulRssi,
          seenRssi: candidate.candidate.rssi,
          consecutiveBatchesSeen: _consecutiveBatchesSeen,
        )) {
          // Too weak AND not yet seen twice — keep scanning this window;
          // a later batch may strengthen or repeat it.
          continue;
        }
        final svc = await connection.connect(candidate);
        _lastSuccessfulRssi = candidate.candidate.rssi;
        onConnected(svc);
        return true;
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'ReconnectConnector scan fallback failed',
      }));
    }
    return false;
  }
}
