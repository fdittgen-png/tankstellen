# Pump-Display OCR / Scan Pipeline — Implementation Overview

> Audit brief for an external review (e.g. Gemini). Generated 2026-06-04.
> Scope: the **pump-display OCR / scan** subsystem of the tankstellen / Sparkilo
> Flutter app — photographing a fuel-pump display and auto-filling the
> "add fill-up" form. On-device only (ML Kit on-device text recognition);
> **no cloud OCR** (standing no-paid-services / privacy constraint). All
> user-facing strings go through ARB localization.

## Purpose

Let a user photograph a fuel-pump display (the three glowing values — total €,
volume L, €/L) and auto-fill the fill-up form, failing **safe** ("try again")
rather than mis-filling when the read is unreliable.

## End-to-end data flow

```
Camera (reticle ROI)                       pump_display_camera_screen.dart
  → ReceiptScanService.parsePumpDisplayImage(path, country, brand, roi, trace)   receipt_scan_service.dart:168
      1. Resolve OcrLocaleProfile for `country`            pump_ocr_config.dart
      2. Glare gate: _isOverGlared(path, roi)  →  reject → "re-angle" prompt    receipt_scan_service.dart:246
      3. _recognisePump → _recogniseRaw → ML Kit TextRecognizer (text + block geometry)   :301 / :320
         (image first cropped to ROI + Sauvola adaptive binarization)           ocr_image_preprocessor.dart
      4. orchestratePumpDisplayParse(blocks, text, profile, parser, gate)       pump_display_orchestrator.dart:26
           a. PRIMARY: extractByLabelAnchor(blocks, profile)  (geometry-aware)   label_anchored_extractor.dart
           b. FALLBACK (if boundCount < 2): PumpDisplayParser.parse(text)        pump_display_parser.dart
           c. PumpValidationGate.evaluate(...) → accepted                        pump_validation_gate.dart
           → PumpDisplayParseResult(validated = profile != null && accepted)     pump_display_parse_result.dart
      5. #2798 retry: if binarized read has no usable data, retry grayscale, keep if it reads more
  → runPumpDisplayScan handler: glare snackbar | autofill liters+cost | failure sheet   fill_up_scan_handlers.dart:154
```

## Two production parse paths + one dormant third

1. **Label-anchored extractor** (`label_anchored_extractor.dart`, 402 LOC) —
   PRIMARY. Uses ML Kit's per-block bounding boxes (`recognized_text_block.dart`)
   to map each number to the printed label above/beside it
   (PRIX / VOLUME / PRIX DU LITRE via `_pump_label_table.dart`), recovering the
   often-dropped unit price and cross-checking arithmetic.
2. **Flat-string parser** (`pump_display_parser.dart`, 313 LOC) — FALLBACK when
   fewer than 2 fields bind from geometry. Pollution-strip
   (`_pump_display_pollution.dart`) + regex (`_pump_display_patterns.dart`) +
   positional inference (`_pump_display_helpers.dart`). Keeps the legacy German /
   Carrefour / Super-U behaviour.
3. **`SevenSegmentRecognizer` + `PumpOcrRecognizer`** (`seven_segment_recognizer.dart`
   384 LOC, `pump_ocr_recognizer.dart` 149 LOC) — a deterministic, ssocr-style
   7-segment LED decoder (row/column ink projection + segment a–g sampling) with
   an orientation-sweep wrapper (`recognizeWithSweep`) and glare rejection.
   **Fully built and unit-tested but DORMANT — zero production callers** (only
   tests reference it). This is the dead code Epic #2823 aims to wire in, because
   ML Kit reads the printed *labels* but **none** of the 7-segment LED *digits*
   (a 7-seg digit is 7 disconnected bars, not a connected glyph).

## Validation gate & result model (the correctness core)

- `PumpValidationGate.evaluate(total, volume, pricePerLitre, confidence, profile)`
  (`pump_validation_gate.dart`): requires ≥2 fields + confidence ≥0.5; when
  `profile != null`, range-checks price/volume/total against the country profile
  and the identity `volume × €/L ≈ total` within **0.05 €**. Returns `accepted` +
  a machine-readable `reason` (`consistent` / `partial` / `price-out-of-range` /
  `too-few` / …).
- `PumpDisplayParseResult` (`pump_display_parse_result.dart`): fields `liters`,
  `totalCost`, `pricePerLiter`, `confidence`, `validated`, `validationReason`,
  `derived`. Getters: `hasUsableData` (≥2 of 3 present), `isConsistent` (all 3
  present **and** `|liters×€/L − total| ≤ 0.02`). Note the **two tolerances**:
  the gate uses 0.05 € (sets `validated`), the `isConsistent` getter uses 0.02 €.
- `validated = profile != null && gate.accepted` (orchestrator:72 / :80) — so a
  read with **no country profile** is always `validated == false`.

## Per-country / per-brand config

`pump_ocr_config.dart` (346 LOC) + `OcrLocaleProfile`: currency-aware
price/volume/total ranges per country (no EUR/German hardcoding). Brand **ROI
templates** (per-field crop rectangles for the dormant recognizer) live in
`assets/ocr_config/index.json` and currently exist **only for tokheim/FR** —
every other pump falls back to the flat-string path.

## Diagnostics & dev tooling (Feature.debugMode gated)

- `pump_ocr_tester_screen.dart` — runs the real pipeline on a captured/picked
  image, renders an ML Kit block overlay, per-stage steps, and exports a trace
  package; "Save as fixture" promotes a scan to a committable regression fixture
  (#2518 / #2519).
- `ocr_trace_recorder.dart` / `ocr_trace_package.dart` — schema-versioned
  `.ocrpkg.json` trace (image + every stage's input/output) for off-device
  debugging.
- `tool/promote_ocr_fixture.dart` — turns a saved `.ocrpkg.json` into a CI replay
  test.
- The recently merged **#2822** fixed an EXIF-orientation flip in the tester
  preview.

## Tests & fixtures

`test/features/consumption/data/ocr/`: `seven_segment_recognizer_test` (synthetic
7-seg glyphs, deterministic, confidence 1.0), `pump_ocr_recognizer_test`
(glare/sweep), `label_anchored_extractor_test`, `pump_validation_gate_test`,
`pump_ocr_config_test`, `ocr_image_preprocessor_test`,
`fr_tokheim_18_59eur_23_30l_fixture_test` (a GREEN `.ocrpkg.json` replay of the
ML-Kit label-anchored path), and **`fr_tokheim_real_ocr_fixture_test`** (real
photos — every per-value read is `markTestSkipped`). Fixtures in
`test/fixtures/pump_displays/` (`tokheim_*.png`, `dresser_wayne_*.png`,
`fr_tokheim/` real photos, `1711/` issue repro).

ARB strings (`_fragments/fill_up_scan_*.arb`): `scanPumpGlare`, `scanPumpSuccess`,
`scanPumpFailed`, `scanPumpUnreadable`.

## Known issues / audit hot-spots

1. **Autofill gate defect** (open #2828): `runPumpDisplayScan` gates autofill on
   `hasUsableData` (`fill_up_scan_handlers.dart:194`) and populates the form
   (lines 200-205) **without consulting `result.validated`** — even though the
   model dartdoc explicitly says "Auto-fill should gate on this, not on
   `hasUsableData` alone." So an identity-inconsistent read (volume×€/L ≠ total)
   auto-fills a *plausible-but-wrong* pair. Fix must be profile-aware (only
   require `validated` when a profile drove validation) to stay non-regressive.
2. **Dormant recognizer / dead code**: the 7-seg decoder has zero production
   callers (Epic #2823).
3. **On-device decode gap**: the on-device 7-seg decoder cannot reliably read
   real glare/angled photos (6/8 real `fr_tokheim` fixtures skip per-value
   asserts). The premise that on-device decode suffices is unproven; reliable
   coverage may exceed on-device capability, and cloud OCR is ruled out by
   constraint.
4. **Single-brand ROIs** (tokheim/FR only).
5. **Two identity tolerances** (0.05 € gate vs 0.02 € `isConsistent`) —
   intentional but worth a consistency check.
6. **Image/privacy lifecycle**: temp capture deletion paths, and the bad-scan
   report flow (`reportBadPumpScan` → GitHub issue) — worth auditing what leaves
   the device.

## Suggested audit questions

- Correctness of the gate's range/identity logic and the (pending) profile-aware
  autofill decision.
- Robustness of the label-anchored geometry mapping (block→label binding).
- The Sauvola binarization params + the binarize→grayscale retry (#2798)
  determinism — could it drop faint digits or produce non-deterministic reads?
- The dormant 7-seg decode algorithm's real-world robustness.
- Image-handling / privacy: temp-file lifecycle, what the bad-scan report uploads.

## Epic #2823 status (validated breakdown)

The "wire the recognizer" epic was validated against the code and re-sequenced:
- #2827 — test(ocr): RED baseline (inconsistent-autofill) + synthetic-frame recognizer routing contract (CI-buildable now)
- #2828 — fix(pump-scan): gate autofill on `validated`, not `hasUsableData` (the confirmed bug)
- #2829 — feat(l10n): `scanPumpInconsistent` + 23-locale fan-out
- #2830 — feat(ocr): wire `PumpOcrRecognizer` as a strictly-additive 3rd source behind the gate
- #2831 — chore(ocr): capture + promote a real reticle-cropped fixture (on-device, needs maintainer device)
