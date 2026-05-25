<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# 2026-05-06 — TFLite Inference Plumbing

## Status

Phase 2 of #1117 (price prediction). Lands the in-app **inference path** for an on-device TFLite model. Does **not** land a trained model — the trained `.tflite` artifact arrives in a separate phase 2-train follow-up once the offline training pipeline (XGBoost → ONNX → TFLite on aggregated history) is decided.

The heuristic predictor in `lib/features/price_history/providers/price_prediction_provider.dart` stays authoritative throughout phase 2. `TflitePricePredictor` is constructed but never consumed; flipping it on is a phase-3 concern.

## Two-PR strategy

The phased split decouples two independent risks:

| Phase | Surface | Risk |
|------|---------|------|
| **Phase 2 (this PR)** | `TflitePricePredictor`, `TfliteInterpreter` seam, asset path, feature flag, tests | Cross-platform plugin compatibility, FFI loading, asset bundling |
| **Phase 2-train** | A single binary asset committed to `assets/models/price_predictor_v1.tflite` | Training-data choice, label noise, model size budget |
| **Phase 3** | Settings toggle + cutover wiring in the heuristic provider | UX copy, A/B comparison vs heuristic |

Shipping plumbing first means the trainer side doesn't block the app side. When training is solved, the entire payload is "commit one binary asset and a `pubspec.yaml` line" — no Dart changes.

## Interpreter seam pattern

```
TflitePricePredictor
        │
        ▼
TfliteInterpreter (abstract)        ← seam
   ├── TfliteFlutterInterpreter     (production — wraps `tflite_flutter`)
   └── _FakeInterpreter             (tests — pure Dart, no FFI)
```

Why a seam:

1. The `tflite_flutter` plugin loads its native FFI binding lazily on first use. On a host without the bundled `.so` / `.dylib` / `.dll` (e.g. headless Linux CI before the model lands), constructing a real `Interpreter` throws.
2. The phase-2 PR ships **no** `.tflite` bytes — there is nothing to construct against. Tests would have to either ship a synthetic model byte buffer (non-trivial; TFLite FlatBuffers are not trivially handcraftable in pure Dart) or skip the inference path entirely.
3. The seam lets every test run against a `_FakeInterpreter` that is a 30-line stub. The production adapter (`TfliteFlutterInterpreter`) delegates to the real plugin and is exercised once a real model lands.

Trade-off: the seam is one extra indirection in the call graph. Worth it because it deletes the "we can't test this until the trainer ships" coupling.

## Feature-flag layer cake

Three independent gates, ordered from loudest to quietest:

1. **Compile-time** — `kTflitePredictorEnabled` (`const bool = false`). Flips the entire predictor off without redeploying assets. Phase 2 ships it `false`. Phase 3 either flips it `true` or removes it once the user-facing toggle is the canonical control.
2. **Runtime asset present** — `TflitePricePredictor.fromAsset()` returns `null` when the bundled `.tflite` is missing or unparseable. Phase 2 ships the asset path empty by design (only `.gitkeep` in `assets/models/`); the factory's "under-trigger preference" guarantees the heuristic stays authoritative.
3. **User-facing toggle** — a settings switch wired in phase 3. Until then, even a successful inference is invisible to the UI.

The cake is intentionally redundant. Each layer is a kill switch the next session up the stack can flip without touching the others. This is the same pattern used elsewhere in the project for risky background features (see auto-record / radius alerts) — silent failure beats user-visible regression every time.

## Static confidence gate

Phase 2 implements a **static** band gate in `TflitePricePredictor.predict`: outputs outside `[50, 300]` ct/L return `null`. EU pump prices have not crossed 300 ct/L in living memory, so the band fences off model overflow / NaN, not a real price ceiling.

The acceptance criterion in #1117 is "confidence threshold gate". A real variance-based gate needs an MC-dropout-or-ensemble model; the XGBoost → ONNX → TFLite pipeline targeted for phase 2-train produces point estimates only. When phase 4 introduces uncertainty estimation, the static band degrades to a sanity check and the gate becomes `predict() returns null when σ > σ_threshold`.

This is documented on the class doc and the deferral is acknowledged in the commit message — not a silent omission.

## What's still needed to flip `kTflitePredictorEnabled`

1. **Training data decision.** Aggregated price history needs an offline export path (existing `PriceRecord` Hive store → CSV → trainer). Open question: is this a user-consent-gated upload, or a manual export the maintainer runs locally on dev-device snapshots?
2. **Trainer pipeline.** XGBoost (best per-feature interpretability for time + brand interactions) → ONNX → `onnx2tflite`. Output a `< 200 KB` quantised TFLite artifact.
3. **Stub-asset replacement.** Drop the trained `.tflite` into `assets/models/price_predictor_v1.tflite`. No Dart changes needed — `pubspec.yaml` already includes `assets/models/`.
4. **Settings toggle.** Add a switch under Settings → Advanced (or whatever the design surfaces). Wire to `priceUsesMlPredictionProvider` (new). Read in `pricePredictionProvider`; when `true` AND `tflitePricePredictorProvider.value != null`, route inference output through the existing `PricePrediction` shape.
5. **Latency budget verification on real device.** The phase-2 acceptance criterion is `< 50 ms`. The fake-interpreter test asserts wrapping overhead is negligible; the real number needs a profiler run on a low-end Android (Pixel 4a or similar).
6. **"Bounded by historical range" verification on real model.** The phase-2 test asserts the wrapping does not perturb a clamped-by-fake value. The real model should be trained with a clip layer or post-processing that enforces `[historicalMin, historicalMax]` per station.

## Files in this PR

- `lib/features/price_history/data/tflite_price_predictor.dart` — `TflitePricePredictor`, `TflitePredictionResult`, `kTflitePredictorEnabled`, `kTflitePredictorAssetPath`
- `lib/features/price_history/data/tflite_interpreter.dart` — `TfliteInterpreter` seam + `TfliteFlutterInterpreter` adapter
- `lib/features/price_history/providers/tflite_price_predictor_provider.dart` — auto-disposed `FutureProvider` (not yet consumed)
- `assets/models/.gitkeep` — directory placeholder
- `pubspec.yaml` — adds `tflite_flutter: ^0.12.1` and registers `assets/models/`
- `test/features/price_history/data/tflite_price_predictor_test.dart` — feature-flag, latency, bounded-range, dispose, asset-failure cases

## Pointers

- Training pipeline (open ticket): split out from #1117 once data export decision lands.
- Phase-1 surface (locked): `lib/features/price_history/domain/entities/feature_vector.dart`, `lib/features/price_history/domain/services/price_feature_extractor.dart`, `lib/core/calendar/public_holiday_calendar.dart`.
- Heuristic baseline (stays authoritative): `lib/features/price_history/providers/price_prediction_provider.dart`.
