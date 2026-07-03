// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../core/logging/error_logger.dart';
import 'obd2_service.dart';

/// #3420 — fire-and-forget-safe teardown for the one leak the 2026-07-02
/// field log caught at `PlatformDispatcher.onError`:
/// `PlatformException(io, bt socket closed, read return: -1)`.
///
/// [Obd2Service.disconnect] can rethrow a platform teardown error (the
/// transport's EventChannel cancel / native socket close racing a dying
/// link). Every `unawaited(service.disconnect())` call site therefore
/// leaked that error into the zone as an UNHANDLED async error — six such
/// sites existed (the pre-warm coordinator × 5, the trip-start watchdog
/// abort × 1). Route them through this wrapper instead.
extension Obd2DisconnectQuietly on Obd2Service {
  /// Disconnect, swallowing (and error-logging) any teardown error.
  /// Never throws — safe under `unawaited(...)`.
  Future<void> disconnectQuietly() async {
    try {
      await disconnect();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'Obd2Service.disconnectQuietly: teardown error (swallowed)',
      }));
    }
  }
}
