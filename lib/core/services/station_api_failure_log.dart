// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../error/exceptions.dart';
import '../logging/error_logger.dart';
import '../telemetry/collectors/breadcrumb_collector.dart';

/// #3370 — classify a station-service API failure for logging.
///
/// An `unsupported` [ApiException] is an EXPECTED, permanent capability gap (a
/// country whose regulated-prices feed exposes no per-station detail, e.g.
/// Luxembourg — `throwDetailUnavailable`), not an outage. Breadcrumb it instead
/// of ERROR-logging it on every detail tap (recurring field noise). Any other
/// failure is a real fault and keeps the #2296 error trace (with its stack).
void logStationApiFailure(
  Object error,
  StackTrace stackTrace, {
  required String countryCode,
  required String cacheKey,
}) {
  if (error is ApiException && error.kind == FailureKind.unsupported) {
    BreadcrumbCollector.add(
      'service: detail unavailable ($countryCode)',
      detail: error.toString(),
    );
    return;
  }
  unawaited(errorLogger.log(ErrorLayer.services, error, stackTrace, context: {
    'where': 'StationServiceChain.apiCall',
    'country': countryCode,
    'key': cacheKey,
  }));
}
