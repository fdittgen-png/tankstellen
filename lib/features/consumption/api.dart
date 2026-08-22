// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `consumption` feature (#3132).
///
/// #3743 (epic item 1) — the 62k-line mega-feature was split into
/// `receipts_ocr`, `fill_ups`, `driving_score`, `charging` and `trips`
/// (refile of the half-done #3136). What remains here is the thin
/// conso-mode shell: the three-tab `ConsumptionScreen` (fuel / trajets /
/// charging) plus its app-bar actions — pure composition over the five
/// extracted features' barrels.
///
/// Cross-feature consumers must import THIS file — never a path under
/// `presentation/` of this feature. Enforced by
/// `test/lint/feature_boundary_test.dart` (epic #3129).
library;

export 'presentation/screens/consumption_screen.dart';
