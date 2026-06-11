// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../station_detail/domain/open_now.dart';
import '../../../core/domain/opening_hours.dart';

/// Derives the tri-state `Station.isOpen` snapshot from a parsed weekly
/// schedule at fetch time (#3198).
///
/// Returns:
///  - `true` / `false` when [hours] resolves to a definite open/closed
///    state at [now] (via [computeOpenNow]);
///  - `null` when [hours] is absent, carries no usable schedule, or
///    resolves to [OpenStatus.unknown] — the honest "no data" signal the
///    UI renders as *unknown* instead of the old hard-coded `true`.
///
/// Pure — the caller passes [now] (use the station country's wall clock,
/// see `nowInCountry`), so services keep an injectable clock seam and the
/// helper stays deterministic under test. Never throws: [computeOpenNow]
/// is total over its inputs, and a `null` [hours] short-circuits.
bool? openStateFromHours(WeeklyOpeningHours? hours, DateTime now) {
  if (hours == null) return null;
  return switch (computeOpenNow(hours, now).status) {
    OpenStatus.open => true,
    OpenStatus.closed => false,
    OpenStatus.unknown => null,
  };
}
