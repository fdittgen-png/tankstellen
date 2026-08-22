// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'ocr_trace_package.dart';
import 'ocr_trace_recorder.dart';
import 'pump_ocr_config.dart';

/// The domain-sanity validation gate for a pump-display read (#2275).
///
/// Replaces the old "any number that parsed wins" behaviour. A read is
/// accepted for auto-fill only when it is BOTH:
///
///  1. **In range** — each present field falls inside the active
///     country's [OcrLocaleProfile] bounds (price/volume/total), so a
///     mis-decoded `8` that turned `2.199` into `21.99 €/L` is rejected.
///  2. **Arithmetically consistent** — when all three are present they
///     satisfy the identity `litres × €/L ≈ total` within
///     [totalTolerance]. This is the strongest signal the three numbers
///     were read correctly together.
///
/// The gate is country-config-driven (no EUR/German hardcoding) and
/// sits in front of BOTH the on-device read and any future cloud read,
/// so the cloud fallback re-uses exactly this acceptance logic.
class PumpValidationGate {
  /// Absolute € tolerance on the `litres × €/L` identity. Pump displays
  /// round to the cent; a couple of cents covers rounding + last-digit
  /// OCR jitter.
  final double totalTolerance;

  /// Minimum overall confidence below which a read is never
  /// auto-accepted even if it is in range.
  final double minConfidence;

  const PumpValidationGate({
    this.totalTolerance = 0.05,
    this.minConfidence = 0.5,
  });

  /// Evaluates a candidate read against [profile]. Pass the recovered
  /// fields (any may be null) and the recognizer's [confidence].
  PumpValidationResult evaluate({
    required double? total,
    required double? volume,
    required double? pricePerLitre,
    required double confidence,
    OcrLocaleProfile? profile,
    OcrTraceRecorder? trace,
  }) {
    // The ordered checks the recorder mirrors — appended as each runs so
    // the trace shows exactly where the gate stopped (#2517). Recording
    // is a no-op when [trace] is null, so production is unchanged.
    final checks = <OcrTraceGateCheck>[];
    PumpValidationResult record(PumpValidationResult r) {
      trace?.gateCheck(
        checks: checks,
        reason: r.reason,
        accepted: r.accepted,
        identityDelta: r.identityDelta,
      );
      return r;
    }

    final present =
        [total, volume, pricePerLitre].where((v) => v != null).length;
    final enoughFields = present >= 2;
    checks.add(OcrTraceGateCheck(name: 'enough-fields', passed: enoughFields));
    if (!enoughFields) {
      return record(
          const PumpValidationResult(accepted: false, reason: 'too-few'));
    }
    final confidentEnough = confidence >= minConfidence;
    checks
        .add(OcrTraceGateCheck(name: 'confidence', passed: confidentEnough));
    if (!confidentEnough) {
      return record(const PumpValidationResult(
          accepted: false, reason: 'low-confidence'));
    }

    if (profile != null) {
      final priceOk = pricePerLitre == null || profile.priceInRange(pricePerLitre);
      checks.add(OcrTraceGateCheck(name: 'price-in-range', passed: priceOk));
      if (!priceOk) {
        return record(const PumpValidationResult(
            accepted: false, reason: 'price-out-of-range'));
      }
      final volumeOk = volume == null || profile.volumeInRange(volume);
      checks.add(OcrTraceGateCheck(name: 'volume-in-range', passed: volumeOk));
      if (!volumeOk) {
        return record(const PumpValidationResult(
            accepted: false, reason: 'volume-out-of-range'));
      }
      final totalOk = total == null || profile.totalInRange(total);
      checks.add(OcrTraceGateCheck(name: 'total-in-range', passed: totalOk));
      if (!totalOk) {
        return record(const PumpValidationResult(
            accepted: false, reason: 'total-out-of-range'));
      }
    }

    if (total != null && volume != null && pricePerLitre != null) {
      final predicted = volume * pricePerLitre;
      final delta = (predicted - total).abs();
      final identityOk = delta <= totalTolerance;
      checks.add(OcrTraceGateCheck(name: 'identity', passed: identityOk));
      if (!identityOk) {
        return record(PumpValidationResult(
            accepted: false,
            reason: 'identity-mismatch',
            identityDelta: delta));
      }
      return record(PumpValidationResult(
          accepted: true, reason: 'consistent', identityDelta: delta));
    }

    // Two of three present, in range, confident enough — accept as a
    // partial read (caller still lets the user verify before saving).
    return record(
        const PumpValidationResult(accepted: true, reason: 'partial'));
  }
}

/// Outcome of [PumpValidationGate.evaluate].
class PumpValidationResult {
  final bool accepted;

  /// Machine-readable reason code (diagnostics, not user-facing).
  final String reason;

  /// `|litres × €/L − total|` when all three were present.
  final double? identityDelta;

  const PumpValidationResult({
    required this.accepted,
    required this.reason,
    this.identityDelta,
  });
}
