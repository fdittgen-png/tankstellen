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

  // ---------------------------------------------------------------------
  // #3614 — shared clock-parsing helpers. Every country adapter parsed
  // some flavour of `HH:MM-HH:MM` with its own copy; the byte-identical
  // pieces live here. Each feed's *accepted inputs* deliberately differ
  // (dots vs colon-only separators, `24:00` end markers, the FR
  // `01:00-01:00` = 24h convention (#3308), CL's stricter clock
  // validation), so the helpers are parameterized/conservative and the
  // per-feed semantics stay in the subclass.
  // ---------------------------------------------------------------------

  static final RegExp _dotOrColonClockRangeRe = RegExp(
    r'(\d{1,2})[.:](\d{2})\s*-\s*(\d{1,2})[.:](\d{2})',
  );
  static final RegExp _colonOnlyClockRangeRe = RegExp(
    r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})',
  );

  /// The one source for the `HH:MM-HH:MM` clock-range pattern (four digit
  /// groups: start hour/minute, end hour/minute).
  ///
  /// [dotSeparator] selects whether `HH.MM` is accepted alongside `HH:MM`
  /// (the CL/FR feeds emit dots; the PT feed is colon-only and must stay
  /// that way — widening its accepted inputs would change behaviour).
  static RegExp clockRangeRe({required bool dotSeparator}) =>
      dotSeparator ? _dotOrColonClockRangeRe : _colonOnlyClockRangeRe;

  /// Builds a [TimeRange] from a [clockRangeRe] match. No validation and
  /// no degenerate handling — the regex guarantees digits, and each feed
  /// owns its own degenerate-range convention (#3308: FR reads
  /// `01:00-01:00` as open-24h; PT drops it as "no interval").
  @protected
  TimeRange rangeFromClockMatch(RegExpMatch m) => TimeRange.fromClock(
        startHour: int.parse(m.group(1)!),
        startMinute: int.parse(m.group(2)!),
        endHour: int.parse(m.group(3)!),
        endMinute: int.parse(m.group(4)!),
      );

  /// `HH:MM` (or `HH:MM:SS` — seconds accepted and dropped) →
  /// minutes-from-midnight (0..1440), or `null` on a malformed clock.
  /// `24:00` is accepted as the end-of-day marker (→ minute 1440).
  @protected
  int? parseClockMinutes(String clock) {
    final parts = clock.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour == 24 && minute == 0) return 1440;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  /// Parses one `HH:MM-HH:MM` clock range (split at the first `-`, both
  /// sides through [parseClockMinutes]), or `null` when malformed.
  ///
  /// Conservative by design: colon-separated clocks only, `24:00`
  /// accepted as the end-of-day marker, and a degenerate (equal-bounds)
  /// range is *returned as-is* — callers own their feed's degenerate
  /// convention (#3308).
  @protected
  TimeRange? parseClockRange(String text) {
    final dash = text.indexOf('-');
    if (dash < 0) return null;
    final start = parseClockMinutes(text.substring(0, dash).trim());
    final end = parseClockMinutes(text.substring(dash + 1).trim());
    if (start == null || end == null) return null;
    return TimeRange(startMinutes: start, endMinutes: end);
  }
}
