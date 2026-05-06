import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/entities/feature_vector.dart';
import 'tflite_interpreter.dart';

/// Compile-time master switch for the on-device TFLite predictor.
///
/// **Default: `false`.** When this flag is `false`, [TflitePricePredictor.predict]
/// short-circuits to `null` even if an interpreter is loaded — the heuristic
/// in `pricePredictionProvider` stays authoritative.
///
/// The flag is the bottom layer of a three-layer cake (#1117 phase 2):
///
/// 1. **Compile-time** — this constant. Lives at the predictor entry
///    point so a future "kill switch" only requires flipping one line.
/// 2. **Runtime asset present** — `fromAsset()` returns `null` when
///    `assets/models/price_predictor_v1.tflite` is missing or
///    unparseable. Phase 2 ships the path empty by design.
/// 3. **User-facing toggle** — a settings switch that gates whether
///    the model output is actually consumed by the UI. Wired in a
///    later phase once we have a trained artifact + UX copy.
///
/// Even if a future change accidentally wires the predictor into the
/// existing provider before phase 3, this flag keeps inference dormant.
const bool kTflitePredictorEnabled = false;

/// Asset path for the bundled `.tflite` artifact. Phase 2 ships the
/// directory + tracking file but no model bytes — see the design doc
/// `docs/feature-concepts/2026-05-06-tflite-inference-plumbing.md`.
const String kTflitePredictorAssetPath =
    'assets/models/price_predictor_v1.tflite';

/// Minimum cents/litre we will ever predict. Rejects nonsensical
/// outputs (e.g. negative values, zero) — the static gate in lieu of
/// a real variance estimator (#1117 phase 2 deferred check).
const double _kMinPredictedCents = 50.0;

/// Maximum cents/litre we will ever predict. Above this, we treat the
/// model as miscalibrated and return `null`. EU pump prices have not
/// crossed 300 ct/L EUR-equivalent in living memory; the bound exists
/// to fence off model overflow / NaN, not to assert a price ceiling.
const double _kMaxPredictedCents = 300.0;

/// Result of a successful inference call.
@immutable
class TflitePredictionResult {
  /// Predicted price in cents per litre. Always finite and within
  /// `[`[_kMinPredictedCents]`, `[_kMaxPredictedCents]`]` — values
  /// outside this band cause [TflitePricePredictor.predict] to return `null`.
  final double predictedPriceCents;

  /// Wall-clock latency of the single inference call. The acceptance
  /// criterion in #1117 is `< 50 ms` per call; the test harness asserts
  /// this on a synthetic interpreter to keep the wrapping overhead
  /// honest.
  final Duration inferenceLatency;

  const TflitePredictionResult({
    required this.predictedPriceCents,
    required this.inferenceLatency,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TflitePredictionResult &&
        other.predictedPriceCents == predictedPriceCents &&
        other.inferenceLatency == inferenceLatency;
  }

  @override
  int get hashCode => Object.hash(predictedPriceCents, inferenceLatency);

  @override
  String toString() => 'TflitePredictionResult('
      'predictedPriceCents: $predictedPriceCents, '
      'inferenceLatency: $inferenceLatency)';
}

/// On-device TFLite predictor for fuel-price recommendations
/// (#1117 phase 2 — inference plumbing only).
///
/// **This class is not yet consumed by the heuristic provider.** Phase 2
/// lands the inference path + tests + interpreter seam so a phase-3 PR
/// can drop a trained `.tflite` into `assets/models/` and wire the
/// settings toggle without touching anything else.
///
/// ## Model contract
///
/// The bundled model is expected to:
///
/// - Take a single input tensor of shape `[1, 5]` and dtype `float32`.
///   The five features (in fixed order) are:
///     1. `hourOfDay / 23.0`            — `[0, 1]` normalised
///     2. `(dayOfWeek - 1) / 6.0`       — `[0, 1]` normalised
///     3. `brandId.hashCode mod prime` normalised — placeholder until
///        phase 3 ships a brand vocabulary; for now we send `0.0` and
///        let the trainer learn to ignore it.
///     4. `countryCode.hashCode mod prime` normalised — same as brand.
///     5. `isHoliday ? 1.0 : 0.0`       — boolean as float
/// - Produce a single output tensor of shape `[1, 1]` and dtype
///   `float32` containing the predicted price in **cents per litre**
///   (i.e. EUR/L × 100). The cents convention matches every other UI
///   path; the trainer is responsible for emitting cents, not euros.
///
/// Phase 3 will revisit the brand / country encoding once we have a
/// trained vocabulary; the contract is documented here so the trainer
/// has a single source of truth.
///
/// ## Confidence gate
///
/// Phase 2 implements a **static** band gate (see [_kMinPredictedCents]
/// / [_kMaxPredictedCents]) instead of a variance-based dynamic gate.
/// Variance estimation needs an MC-dropout-or-ensemble model; the
/// XGBoost → ONNX → TFLite pipeline targeted for phase 3 produces
/// point estimates only. When phase 4 introduces uncertainty, this
/// gate becomes `predict() returns null when σ > σ_threshold` and the
/// static band degrades to a sanity check.
class TflitePricePredictor {
  TflitePricePredictor({
    required TfliteInterpreter interpreter,
    Stopwatch Function() stopwatch = Stopwatch.new,
  })  : _interpreter = interpreter,
        _stopwatch = stopwatch,
        _enabledOverride = null;

  /// Test-only constructor — lets the test suite exercise the enabled
  /// inference path even though [kTflitePredictorEnabled] is `false` at
  /// compile time. **Not for production use.** The override is `null`
  /// in production and `true` / `false` in tests; when non-null it
  /// supersedes the compile-time flag. Hidden behind
  /// [visibleForTesting] so accidental call sites trigger an analyzer
  /// warning.
  @visibleForTesting
  TflitePricePredictor.test({
    required TfliteInterpreter interpreter,
    Stopwatch Function() stopwatch = Stopwatch.new,
    required bool enabled,
  })  : _interpreter = interpreter,
        _stopwatch = stopwatch,
        _enabledOverride = enabled;

  final TfliteInterpreter _interpreter;
  final Stopwatch Function() _stopwatch;
  final bool? _enabledOverride;
  bool _disposed = false;

  bool get _enabled => _enabledOverride ?? kTflitePredictorEnabled;

  /// Loads a [TflitePricePredictor] from a bundled asset path.
  ///
  /// Returns `null` on **any** I/O / parse failure — the heuristic
  /// stays authoritative under all error conditions. This is the
  /// "under-trigger preference" required by #1117: a missing / malformed
  /// model never surfaces as a user-visible error.
  ///
  /// This entry point is also gated by [kTflitePredictorEnabled]: when
  /// the flag is `false` (the phase-2 default) the factory returns
  /// `null` without touching the asset bundle. That keeps the cold-start
  /// cost at zero until phase 3 flips the flag.
  static Future<TflitePricePredictor?> fromAsset(
    String path, {
    TfliteInterpreter? Function(List<int> bytes) interpreterFactory =
        TfliteFlutterInterpreter.fromBuffer,
    @visibleForTesting bool? enabledOverride,
  }) async {
    final enabled = enabledOverride ?? kTflitePredictorEnabled;
    if (!enabled) return null;

    final ByteData data;
    try {
      data = await rootBundle.load(path);
    } catch (e, st) {
      debugPrint(
        'TflitePricePredictor.fromAsset: missing asset "$path": $e\n$st',
      );
      return null;
    }

    final TfliteInterpreter? interpreter;
    try {
      interpreter = interpreterFactory(data.buffer.asUint8List());
    } catch (e, st) {
      debugPrint(
        'TflitePricePredictor.fromAsset: interpreter build failed: $e\n$st',
      );
      return null;
    }
    if (interpreter == null) return null;

    return TflitePricePredictor(interpreter: interpreter);
  }

  /// Runs inference for a single [FeatureVector].
  ///
  /// Returns `null` when:
  /// - [kTflitePredictorEnabled] is `false` (compile-time master switch),
  /// - the predictor has been [dispose]d,
  /// - the interpreter does not write a finite output value, or
  /// - the predicted price falls outside the static confidence band.
  ///
  /// Successful calls return a [TflitePredictionResult] with the
  /// predicted price (cents/litre) and the wall-clock inference
  /// [Duration].
  TflitePredictionResult? predict(FeatureVector features) {
    if (!_enabled) return null;
    if (_disposed) return null;

    final input = _toModelInput(features);
    // Shape `[1, 1]` output — pre-allocate so the interpreter can fill
    // in place. We keep this as a `List<List<double>>` for parity with
    // `tflite_flutter`'s public API; the FlatBuffer runtime accepts it
    // verbatim.
    final output = <List<double>>[<double>[double.nan]];

    final stopwatch = _stopwatch()..start();
    _interpreter.run(input, output);
    stopwatch.stop();

    final raw = output[0][0];
    if (!raw.isFinite) {
      debugPrint('TflitePricePredictor.predict: non-finite output ($raw)');
      return null;
    }
    if (raw < _kMinPredictedCents || raw > _kMaxPredictedCents) {
      debugPrint(
        'TflitePricePredictor.predict: out-of-band output ($raw cents) — '
        'rejecting per static confidence gate',
      );
      return null;
    }

    return TflitePredictionResult(
      predictedPriceCents: raw,
      inferenceLatency: stopwatch.elapsed,
    );
  }

  /// Releases the underlying interpreter. Calling [predict] after
  /// [dispose] returns `null`.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _interpreter.close();
  }

  /// Builds the `[1, 5]` `float32` input tensor for [features]. Kept
  /// `@visibleForTesting` so the trainer-pipeline integration test in a
  /// future phase can assert encoding stability.
  @visibleForTesting
  static List<List<double>> toModelInput(FeatureVector features) =>
      _toModelInput(features);
}

List<List<double>> _toModelInput(FeatureVector features) {
  final hour = features.hourOfDay.clamp(0, 23) / 23.0;
  final day = (features.dayOfWeek.clamp(1, 7) - 1) / 6.0;
  // Brand and country are placeholders until phase 3 ships a trained
  // vocabulary; emit `0.0` so the trainer learns to ignore the slot.
  // We keep the columns in the input tensor so the model shape is
  // stable across phase 2/3 — only the values change.
  const brandSlot = 0.0;
  const countrySlot = 0.0;
  final holiday = features.isHoliday ? 1.0 : 0.0;
  return <List<double>>[
    <double>[hour, day, brandSlot, countrySlot, holiday],
  ];
}
