// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../data/obd2/obd2_connection_errors.dart';

// #2763 — `recordObd2ReadFailure` / `isExpectedObd2ReadTransient` live in the
// data layer (so `obd2_service` can use them without a presentation→data
// inversion) but are re-exported here so this file stays the single
// discoverable home for OBD2 telemetry-level routing.
export '../data/obd2/obd2_read_telemetry.dart';

/// #2745 — route an OBD2 connect-flow failure to the right telemetry level.
///
/// Error-log #14 trace #5 was an `[ui] Obd2AdapterUnresponsive` ERROR spooled
/// for a connect failure that the UI already surfaces to the user (a localized
/// snackbar + a fall-through to the picker). An EXPECTED, user-actionable
/// condition ([Obd2ConnectionError.isExpectedUserCondition]) records a
/// diagnostic [BreadcrumbCollector] breadcrumb instead — NOT an ERROR trace.
/// A GENUINE fault (permission denied, counterfeit-clone init string, or any
/// non-OBD2 exception) still `errorLogger.log`s at [ErrorLayer.ui] so it stays
/// visible. Shared by the pinned-connect picker path and the live-trip
/// recording-start path so the two can't drift.
void recordObd2ConnectFailure(
  Object error,
  StackTrace stack, {
  required String where,
}) {
  if (error is Obd2ConnectionError && error.isExpectedUserCondition) {
    BreadcrumbCollector.add(
      'OBD2 connect failed — expected user condition',
      detail: '$where: ${error.runtimeType}',
    );
    return;
  }
  unawaited(errorLogger.log(ErrorLayer.ui, error, stack,
      context: {'where': where}));
}
