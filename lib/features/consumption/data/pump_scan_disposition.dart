// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'pump_display_parse_result.dart';

/// What the pump-display scan flow should do with a parse result (#2828).
///
/// Extracted as a pure function of [PumpDisplayParseResult] so the
/// auto-fill decision is unit-testable without a widget/`BuildContext`.
enum PumpScanDisposition {
  /// Two-plus fields and either validated, or no profile to validate
  /// against — prefill the form (the user still verifies).
  autofill,

  /// A country profile gated the read and it FAILED (the numbers don't
  /// reconcile — `liters × €/L ≠ total` — or a field is out of range).
  /// Auto-filling here would silently log a plausible-but-wrong pair, so
  /// route to a "values don't add up — enter manually" prompt instead.
  inconsistent,

  /// Fewer than two usable fields — nothing trustworthy to prefill.
  unreadable,
}

/// Decides the [PumpScanDisposition] for [result].
///
/// The order matters: an unusable read (`<2` fields) is `unreadable`
/// regardless of validation; a profile-validated read that the gate
/// rejected is `inconsistent` (#2828 — the old code auto-filled it on
/// [PumpDisplayParseResult.hasUsableData] alone); everything else
/// (validated, or no profile so the gate could not range-check) is
/// `autofill`, keeping profile-less regions non-regressive.
PumpScanDisposition pumpScanDispositionFor(PumpDisplayParseResult result) {
  if (!result.hasUsableData) return PumpScanDisposition.unreadable;
  if (result.validationApplied && !result.validated) {
    return PumpScanDisposition.inconsistent;
  }
  return PumpScanDisposition.autofill;
}
