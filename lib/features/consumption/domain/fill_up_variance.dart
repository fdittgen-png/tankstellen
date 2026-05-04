import 'entities/fill_up.dart';

/// Pure helpers for the OBD2 fill-up reconciliation flow (#1401 phase 7b).
///
/// A fill-up is "verified by adapter" when both [FillUp.fuelLevelBeforeL]
/// and [FillUp.fuelLevelAfterL] were captured from the OBD2 fuel-level
/// PID — once at pump start, once at pump end. The adapter delta
/// `(after - before)` is the litres pumped according to the car's own
/// tank-level sensor; comparing it to the user-entered litres surfaces
/// pump-display read errors and OCR mistakes before they corrupt the
/// consumption history.
///
/// Kept as a top-level utility (no class) to match the codebase style
/// for one-shot helpers — see e.g. `fill_up_auto_cost_calculator.dart`
/// for the same shape.
class FillUpVariance {
  FillUpVariance._();

  /// Threshold above which the variance prompt fires. 5 % matches the
  /// typical pump-meter accuracy class plus normal sloshing in the
  /// tank during refuel; below that we trust the user's entry without
  /// nagging.
  static const double thresholdFraction = 0.05;

  /// Whether [fillUp] has both fuel-level captures and is therefore
  /// eligible for the verified-by-adapter badge AND the variance
  /// prompt. Either field null means we don't have a full delta — no
  /// badge, no dialog.
  static bool hasAdapterCapture(FillUp fillUp) =>
      fillUp.fuelLevelBeforeL != null && fillUp.fuelLevelAfterL != null;

  /// Adapter-measured litres pumped: tank level after the pump minus
  /// tank level before. Returns null when either capture is missing.
  /// The result can be negative if the adapter reports an unexpected
  /// dip (sensor noise, very-low-tank readings) — callers should
  /// guard with [hasAdapterCapture] first; this helper does NOT clamp
  /// because the dialog text wants the raw delta the user can sanity
  /// check.
  static double? adapterDeltaL(FillUp fillUp) {
    final before = fillUp.fuelLevelBeforeL;
    final after = fillUp.fuelLevelAfterL;
    if (before == null || after == null) return null;
    return after - before;
  }

  /// Returns true when the user-entered [userL] differs from the
  /// adapter-derived [adapterL] by strictly more than [thresholdFraction]
  /// of [adapterL]. We compare against the adapter value because it's
  /// the trusted reference; comparing against `userL` would let a
  /// 0 L user entry sail past with infinite ratio. Returns false when
  /// [adapterL] is non-positive — no meaningful baseline to compare.
  static bool isVarianceAbove5Percent(double userL, double adapterL) {
    if (adapterL <= 0) return false;
    final delta = (userL - adapterL).abs();
    return delta > adapterL * thresholdFraction;
  }
}
