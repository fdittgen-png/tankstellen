// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../station_detail/domain/opening_hours.dart';

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
}
