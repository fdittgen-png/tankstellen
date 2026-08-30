// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The ± half-width of the η_v convergence band shown by the Advanced
/// calibration section for a profile with [sampleCount] accepted
/// plein-complet reconciliations (#1626). A sample-count heuristic:
/// `0.10 / (sampleCount + 1)`, clamped to `[0.01, 0.10]`.
double veConvergenceHalfWidth(int sampleCount) {
  final n = sampleCount < 0 ? 0 : sampleCount;
  return (0.10 / (n + 1)).clamp(0.01, 0.10).toDouble();
}
