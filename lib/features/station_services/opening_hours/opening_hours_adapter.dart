// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../../core/domain/opening_hours.dart';

/// Per-country adapter that normalises a provider's raw opening-hours payload
/// into the common [WeeklyOpeningHours] model.
///
/// ## Contract (every implementation MUST honour it)
/// - **Pure** — [parse] reads only its argument; no I/O, no clock, no
///   provider state.
/// - **Never throws** — a malformed / unexpected `rawProviderData` shape must
///   be caught internally and reported as no-data, not propagated. The
///   six country adapters feed user-facing UI; a parse fault must degrade
///   gracefully, never crash the station-detail screen.
/// - **Never returns `null`** — on missing or unparseable input return
///   [WeeklyOpeningHours.notAvailable] so the no-data UI path is uniform
///   across all countries (no per-call null checks at the call site).
///
/// `rawProviderData` is intentionally `dynamic`: each country feeds a
/// different shape (an OSM `opening_hours` string, a JSON map, a list of
/// weekday rows). The adapter owns the shape-narrowing and the fault
/// handling so the contract above holds.
abstract class OpeningHoursAdapter {
  const OpeningHoursAdapter();

  /// Normalises [rawProviderData] into a [WeeklyOpeningHours]. Pure, never
  /// throws, never returns `null` — see the class contract.
  WeeklyOpeningHours parse(dynamic rawProviderData);

  /// Country codes that already reported a parse failure this session
  /// (#3148). One static set shared by every adapter: each adapter passes
  /// its own country code, so the throttle is per adapter, per session.
  static final Set<String> _reportedCountries = <String>{};

  /// Clears the per-session throttle. Call from test `setUp`/`tearDown`.
  @visibleForTesting
  static void resetParseFailureReportsForTest() => _reportedCountries.clear();

  /// #3148 — release-visible parse-failure report for the catch block every
  /// adapter's [parse] carries. The previous assert-wrapped `print` was
  /// compiled out of release builds, so a provider changing its hours format
  /// degraded EVERY station to "no data" with zero field signal.
  ///
  /// Throttled to the first occurrence per adapter per session: a format
  /// change hits every station card in a result list, and one trace is
  /// enough to triage. Adds an `oh-parse-failed` breadcrumb (drained into
  /// every error trace) and routes one errorLogger ERROR with the country
  /// + exception type. Swallows nothing new — callers still return
  /// [WeeklyOpeningHours.notAvailable].
  @protected
  void reportParseFailure(String countryCode, Object e, StackTrace st) {
    if (!_reportedCountries.add(countryCode)) return;
    BreadcrumbCollector.add(
      'oh-parse-failed',
      detail: '$countryCode ${e.runtimeType}',
    );
    unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
      'where': 'OpeningHoursAdapter.parse',
      'country': countryCode,
    }));
  }
}
