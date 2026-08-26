// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'entities/gps_sample_diagnostic.dart';

/// #3785 — the arrival-vs-fix skew analysis behind
/// [GpsGapAttribution.deliveryStall].
///
/// Extracted from `gps_coverage_report.dart` as its own collaborator:
/// the report was at the #1680 length cap, and this is a genuinely
/// separate, pure question — "did delivery fall behind the receiver?" —
/// that deserves to be unit-testable on its own.
///
/// The field motivation: six ~24.5 s gaps on a FOREGROUND trip were all
/// labelled `signalLoss`, which is a residual bucket and therefore said
/// nothing about the cause. Recording BOTH clocks per fix makes an
/// app-side delivery stall positively identifiable.
class GpsDeliverySkew {
  GpsDeliverySkew._();

  /// #3785 — did the fix that ENDED this gap arrive materially later
  /// than the receiver stamped it, when the one that began it did not?
  ///
  /// That pairing is the discriminator: a lone large skew can simply be
  /// a slow tail, but a jump ACROSS the gap means the receiver kept
  /// producing while delivery fell behind. The threshold is one whole
  /// expected interval of extra lag, so ordinary jitter never qualifies.
  ///
  /// Returns false when either clock pair is missing — an unmeasured
  /// gap must fall through to the residual bucket rather than be
  /// asserted as a stall.
  static bool stalledAcross(
    List<GpsSampleDiagnostic> diagnostics,
    DateTime gapStart,
    DateTime gapEnd,
    Duration interval,
  ) {
    if (diagnostics.isEmpty) return false;
    final before = skewAtFix(diagnostics, gapStart, interval);
    final after = skewAtFix(diagnostics, gapEnd, interval);
    if (before == null || after == null) return false;
    return after - before >= interval;
  }

  /// The delivery skew of the diagnostic whose FIX clock matches [at]
  /// within half an interval. Matching on the fix clock (not arrival) is
  /// what makes the lookup valid precisely when arrival has drifted.
  static Duration? skewAtFix(
    List<GpsSampleDiagnostic> diagnostics,
    DateTime at,
    Duration interval,
  ) {
    final tolerance = interval ~/ 2;
    for (final d in diagnostics) {
      final fixAt = d.fixAt;
      if (fixAt == null) continue;
      final delta = fixAt.difference(at);
      if (delta.abs() <= tolerance) return d.deliverySkew;
    }
    return null;
  }
}
