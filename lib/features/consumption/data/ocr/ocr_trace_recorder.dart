// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'ocr_trace_package.dart';
import 'recognized_text_block.dart';

/// The reasoning-chain stages the OCR pipelines walk through (#2517).
///
/// Each stage maps to one capture point the recorder is fed from. The
/// tester (Epic #2516 Child 2) renders them in this order as the steps
/// panel; the values themselves accumulate in [OcrTraceRecorder].
enum OcrTraceStage {
  /// Glare-fraction preprocessing reject decision (pump path).
  glare,

  /// ML Kit text recognition (flat text + block geometry).
  mlkit,

  /// Per-block label|numeric|noise classification.
  classify,

  /// Split-label assembly ("PRIX DU" + "LITRE").
  assemble,

  /// Label→numeric anchoring.
  anchor,

  /// Magnitude fallback for still-unbound fields.
  fallback,

  /// `total ≈ volume × €/L` cross-check derivation.
  crossCheck,

  /// Per-component confidence scoring.
  confidence,

  /// The per-country validation gate.
  gate,

  /// Receipt brand detection.
  brand,

  /// Receipt per-station override dispatch.
  overrides,

  /// Receipt cross-field reconcile.
  reconcile,

  /// The final read.
  result,
}

/// In-memory side-channel that accumulates the full OCR reasoning chain
/// (#2517, Epic #2516) — the same spirit as `Obd2DebugSessionRecorder`.
///
/// Production threads `null` through the pump + receipt pipelines, so the
/// existing code path is BYTE-FOR-BYTE unchanged and costs nothing. The
/// dev tester passes a real recorder, the instrumented pipelines feed it
/// at each stage via this thin sink API, and the tester reads back a
/// [build]-ed [OcrTracePackage] (then `formatOcrTracePackageJson`).
///
/// PURE Dart, no I/O — it only collects. The screen wires the actual
/// image bytes ([image]) before export.
class OcrTraceRecorder {
  final OcrTraceKind kind;
  final DateTime _capturedAt;

  OcrTraceInput _input = const OcrTraceInput();
  OcrTracePreprocess? _preprocess;
  OcrTraceMlkit? _mlkit;
  final List<OcrTraceClassification> _classification = [];
  final List<OcrTraceAssembledLabel> _assembled = [];
  final List<OcrTraceAnchor> _anchors = [];
  final List<OcrTracePairing> _pairings = [];
  final List<OcrTraceFallback> _fallbacks = [];
  OcrTraceCrossCheck? _crossCheck;
  OcrTraceConfidence? _confidence;
  OcrTraceGate? _gate;
  OcrTraceReceipt? _receipt;
  OcrTraceResult? _result;
  OcrTraceExpected? _expected;
  OcrTraceImage? _image;

  /// Ordered log of which stages fired, in call order — drives the
  /// tester's steps panel and lets a test assert the path taken.
  final List<OcrTraceStage> _stages = [];

  OcrTraceRecorder({this.kind = OcrTraceKind.pump, DateTime? capturedAt})
      : _capturedAt = capturedAt ?? DateTime.now().toUtc();

  /// The stages recorded so far, in order (may repeat).
  List<OcrTraceStage> get stages => List.unmodifiable(_stages);

  /// Mark that [stage] ran (no payload). The typed sinks below already
  /// log their own stage; use this for stages without a dedicated sink.
  void stage(OcrTraceStage stage) => _stages.add(stage);

  /// Record the active region / profile inputs.
  void input({
    String? country,
    String? brand,
    List<double>? roi,
    Map<String, dynamic>? profile,
  }) {
    _input = OcrTraceInput(
        country: country, brand: brand, roi: roi, profile: profile);
  }

  /// Record the glare-reject preprocessing decision.
  void glare({
    required double fraction,
    required double threshold,
    required bool rejected,
  }) {
    _stages.add(OcrTraceStage.glare);
    _preprocess = OcrTracePreprocess(
        glareFraction: fraction, threshold: threshold, rejected: rejected);
  }

  /// Record ML Kit's flat text and its recognized block geometry.
  void blocks(String flatText, List<RecognizedTextBlock> blocks) {
    _stages.add(OcrTraceStage.mlkit);
    _mlkit = OcrTraceMlkit(
      flatText: flatText,
      blocks: [
        for (final b in blocks)
          OcrTraceBlock(
            text: b.text,
            left: b.box.left,
            top: b.box.top,
            right: b.box.right,
            bottom: b.box.bottom,
          ),
      ],
    );
  }

  /// Record one block's classification outcome.
  void classify(
    String text,
    String kind, {
    String? field,
    int? weight,
    double? value,
    int? decimals,
  }) {
    if (_stages.isEmpty || _stages.last != OcrTraceStage.classify) {
      _stages.add(OcrTraceStage.classify);
    }
    _classification.add(OcrTraceClassification(
      text: text,
      kind: kind,
      field: field,
      weight: weight,
      value: value,
      decimals: decimals,
    ));
  }

  /// Record a split-label merge.
  void assembled({
    required String first,
    required String second,
    required String combined,
    required String field,
  }) {
    if (_stages.isEmpty || _stages.last != OcrTraceStage.assemble) {
      _stages.add(OcrTraceStage.assemble);
    }
    _assembled.add(OcrTraceAssembledLabel(
        first: first, second: second, combined: combined, field: field));
  }

  /// Record all anchor candidates for one label, flagging the chosen one.
  void anchorCandidates(List<OcrTraceAnchor> candidates) {
    if (candidates.isEmpty) return;
    if (_stages.isEmpty || _stages.last != OcrTraceStage.anchor) {
      _stages.add(OcrTraceStage.anchor);
    }
    _anchors.addAll(candidates);
  }

  /// Record one spatial label→value pairing decision (#3458): the label
  /// box, the value box it claimed, and the rule that fired. Logged
  /// under the anchor stage — pairing IS the receipt parser's anchoring.
  void pairing(OcrTracePairing decision) {
    if (_stages.isEmpty || _stages.last != OcrTraceStage.anchor) {
      _stages.add(OcrTraceStage.anchor);
    }
    _pairings.add(decision);
  }

  /// Record one magnitude-fallback bucket decision.
  void fallback({
    required String field,
    required double value,
    required int decimals,
    required String reason,
  }) {
    if (_stages.isEmpty || _stages.last != OcrTraceStage.fallback) {
      _stages.add(OcrTraceStage.fallback);
    }
    _fallbacks.add(OcrTraceFallback(
        field: field, value: value, decimals: decimals, reason: reason));
  }

  /// Record the cross-check derivation branch + inputs + computed value.
  void crossCheck({
    double? total,
    double? volume,
    double? price,
    required String derivedPath,
    double? computed,
  }) {
    _stages.add(OcrTraceStage.crossCheck);
    _crossCheck = OcrTraceCrossCheck(
      total: total,
      volume: volume,
      price: price,
      derivedPath: derivedPath,
      computed: computed,
    );
  }

  /// Record the per-component confidence breakdown.
  void confidence({
    required bool hasTotal,
    required bool hasVolume,
    required bool hasPrice,
    required bool isConsistent,
    required double total,
  }) {
    _stages.add(OcrTraceStage.confidence);
    _confidence = OcrTraceConfidence(
      hasTotal: hasTotal,
      hasVolume: hasVolume,
      hasPrice: hasPrice,
      isConsistent: isConsistent,
      total: total,
    );
  }

  /// Record the ordered validation-gate decision.
  void gateCheck({
    required List<OcrTraceGateCheck> checks,
    required String reason,
    required bool accepted,
    double? identityDelta,
  }) {
    _stages.add(OcrTraceStage.gate);
    _gate = OcrTraceGate(
      checks: checks,
      reason: reason,
      accepted: accepted,
      identityDelta: identityDelta,
    );
  }

  /// Record receipt brand detect + dispatched layout.
  void brand(String? brand, String layout) {
    _stages.add(OcrTraceStage.brand);
    _receipt = OcrTraceReceipt(brand: brand, layout: layout);
  }

  /// Record one per-station override field that fired.
  void overrideField({
    required String field,
    required String pattern,
    required String match,
    double? value,
  }) {
    if (_stages.isEmpty || _stages.last != OcrTraceStage.overrides) {
      _stages.add(OcrTraceStage.overrides);
    }
    final base = _receipt;
    _receipt = OcrTraceReceipt(
      brand: base?.brand,
      layout: base?.layout ?? 'generic',
      overrides: [
        ...?base?.overrides,
        OcrTraceOverride(
            field: field, pattern: pattern, match: match, value: value),
      ],
      reconcile: base?.reconcile,
    );
  }

  /// Record the receipt reconcile outcome.
  void reconcile({
    double? read,
    double? derived,
    double? predictedTotal,
    double? delta,
  }) {
    _stages.add(OcrTraceStage.reconcile);
    final base = _receipt;
    _receipt = OcrTraceReceipt(
      brand: base?.brand,
      layout: base?.layout ?? 'generic',
      overrides: base?.overrides ?? const [],
      reconcile: OcrTraceReconcile(
        read: read,
        derived: derived,
        predictedTotal: predictedTotal,
        delta: delta,
      ),
    );
  }

  /// Record the final read.
  void result({
    double? totalCost,
    double? liters,
    double? pricePerLiter,
    Set<String> derived = const {},
    double confidence = 0,
    bool validated = false,
    String? validationReason,
  }) {
    _stages.add(OcrTraceStage.result);
    _result = OcrTraceResult(
      totalCost: totalCost,
      liters: liters,
      pricePerLiter: pricePerLiter,
      derived: derived,
      confidence: confidence,
      validated: validated,
      validationReason: validationReason,
    );
  }

  /// Attach ground-truth expected values (fixture promotion).
  void expected({double? totalCost, double? liters, double? pricePerLiter}) {
    _expected = OcrTraceExpected(
        totalCost: totalCost, liters: liters, pricePerLiter: pricePerLiter);
  }

  /// Attach the capture image (base64 + sibling file name) for export.
  void image({required String fileName, required String base64}) {
    _image = OcrTraceImage(fileName: fileName, base64: base64);
  }

  /// Snapshot everything recorded so far into a serialise-ready package.
  OcrTracePackage build() => OcrTracePackage(
        kind: kind,
        capturedAt: _capturedAt,
        input: _input,
        preprocess: _preprocess,
        mlkit: _mlkit,
        classification: List.unmodifiable(_classification),
        assembledLabels: List.unmodifiable(_assembled),
        anchors: List.unmodifiable(_anchors),
        pairings: List.unmodifiable(_pairings),
        magnitudeFallback: List.unmodifiable(_fallbacks),
        crossCheck: _crossCheck,
        confidence: _confidence,
        gate: _gate,
        receipt: _receipt,
        result: _result,
        expected: _expected,
        image: _image,
      );
}
