// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

library;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/ocr/ocr_trace_package.dart';
import '../../data/ocr/ocr_trace_recorder.dart';
import 'ocr_block_overlay_painter.dart';

// The presentational row / tile widgets live in a part so this file stays
// under the 400-line norm; the panel + its row widgets are one unit.
part 'ocr_trace_steps_panel_rows.dart';

/// Per-stage steps panel for the gated OCR tester (#2518, Epic #2516
/// Child 2): one [ExpansionTile] per reasoning stage the pump / receipt
/// pipeline walks through, in the canonical order
/// Capture/Glare → ML Kit → Classify → Assemble → Anchor → Fallback →
/// Cross-check → Confidence → Gate (pump) / Brand → Overrides → Reconcile
/// (receipt) → Result.
///
/// Each tile shows the recorded payload for its stage, flags READ vs
/// DERIVED, surfaces the gate reason + accept/reject, and shows a
/// fallback banner when the magnitude-fallback stage bound a field. A
/// stage the pipeline never reached renders a muted "did not run" line.
///
/// Pure presentational widget — it reads the already-built
/// [OcrTracePackage]; it never runs OCR itself, so it is fully testable
/// from a seeded fixture trace.
class OcrTraceStepsPanel extends StatelessWidget {
  final OcrTracePackage package;

  const OcrTraceStepsPanel({super.key, required this.package});

  /// Canonical stage order per kind. Receipt swaps the pump-only
  /// anchor/fallback/cross-check/confidence/gate stages for
  /// brand/overrides/reconcile.
  List<OcrTraceStage> get _stages => package.kind == OcrTraceKind.receipt
      ? const [
          OcrTraceStage.mlkit,
          OcrTraceStage.brand,
          OcrTraceStage.overrides,
          OcrTraceStage.reconcile,
          OcrTraceStage.result,
        ]
      : const [
          OcrTraceStage.glare,
          OcrTraceStage.mlkit,
          OcrTraceStage.classify,
          OcrTraceStage.assemble,
          OcrTraceStage.anchor,
          OcrTraceStage.fallback,
          OcrTraceStage.crossCheck,
          OcrTraceStage.confidence,
          OcrTraceStage.gate,
          OcrTraceStage.result,
        ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_fallbackFired) _FallbackBanner(text: l.ocrTesterFallbackBanner),
        for (final stage in _stages)
          _StageTile(
            key: Key('ocr_step_${stage.name}'),
            stage: stage,
            label: _stageLabel(l, stage),
            children: _stageChildren(context, l, stage),
          ),
      ],
    );
  }

  bool get _fallbackFired => package.magnitudeFallback.isNotEmpty;

  String _stageLabel(AppLocalizations l, OcrTraceStage stage) =>
      switch (stage) {
        OcrTraceStage.glare => l.ocrTesterStageGlare,
        OcrTraceStage.mlkit => l.ocrTesterStageMlkit,
        OcrTraceStage.classify => l.ocrTesterStageClassify,
        OcrTraceStage.assemble => l.ocrTesterStageAssemble,
        OcrTraceStage.anchor => l.ocrTesterStageAnchor,
        OcrTraceStage.fallback => l.ocrTesterStageFallback,
        OcrTraceStage.crossCheck => l.ocrTesterStageCrossCheck,
        OcrTraceStage.confidence => l.ocrTesterStageConfidence,
        OcrTraceStage.gate => l.ocrTesterStageGate,
        OcrTraceStage.brand => l.ocrTesterStageBrand,
        OcrTraceStage.overrides => l.ocrTesterStageOverrides,
        OcrTraceStage.reconcile => l.ocrTesterStageReconcile,
        OcrTraceStage.result => l.ocrTesterStageResult,
      };

  /// The detail rows for [stage], or an empty list (→ "did not run").
  List<Widget> _stageChildren(
    BuildContext context,
    AppLocalizations l,
    OcrTraceStage stage,
  ) {
    return switch (stage) {
      OcrTraceStage.glare => _glareRows(),
      OcrTraceStage.mlkit => _mlkitRows(context),
      OcrTraceStage.classify => _classifyRows(context),
      OcrTraceStage.assemble => _assembleRows(),
      OcrTraceStage.anchor => _anchorRows(context),
      OcrTraceStage.fallback => _fallbackRows(),
      OcrTraceStage.crossCheck => _crossCheckRows(),
      OcrTraceStage.confidence => _confidenceRows(),
      OcrTraceStage.gate => _gateRows(context, l),
      OcrTraceStage.brand => _brandRows(),
      OcrTraceStage.overrides => _overrideRows(),
      OcrTraceStage.reconcile => _reconcileRows(),
      OcrTraceStage.result => _resultRows(context, l),
    };
  }

  List<Widget> _glareRows() {
    final p = package.preprocess;
    if (p == null) return const [];
    return [
      _kv('fraction', p.glareFraction.toStringAsFixed(3)),
      _kv('threshold', p.threshold.toStringAsFixed(3)),
      _kv('rejected', '${p.rejected}'),
    ];
  }

  List<Widget> _mlkitRows(BuildContext context) {
    final m = package.mlkit;
    if (m == null) return const [];
    return [
      _kv('blocks', '${m.blocks.length}'),
      _kv('chars', '${m.flatText.length}'),
    ];
  }

  List<Widget> _classifyRows(BuildContext context) {
    if (package.classification.isEmpty) return const [];
    return [
      for (final c in package.classification) _ClassifyRow(classification: c),
    ];
  }

  List<Widget> _assembleRows() {
    if (package.assembledLabels.isEmpty) return const [];
    return [
      for (final a in package.assembledLabels)
        _kv(a.field, '"${a.first}" + "${a.second}" → "${a.combined}"'),
    ];
  }

  List<Widget> _anchorRows(BuildContext context) {
    if (package.anchors.isEmpty) return const [];
    return [for (final a in package.anchors) _AnchorRow(anchor: a)];
  }

  List<Widget> _fallbackRows() {
    if (package.magnitudeFallback.isEmpty) return const [];
    return [
      for (final f in package.magnitudeFallback)
        _kv(f.field, '${f.value} (${f.decimals}dp) — ${f.reason}'),
    ];
  }

  List<Widget> _crossCheckRows() {
    final c = package.crossCheck;
    if (c == null) return const [];
    return [
      _kv('derivedPath', c.derivedPath),
      if (c.computed != null) _kv('computed', '${c.computed}'),
      if (c.total != null) _kv('total', '${c.total}'),
      if (c.volume != null) _kv('volume', '${c.volume}'),
      if (c.price != null) _kv('price', '${c.price}'),
    ];
  }

  List<Widget> _confidenceRows() {
    final c = package.confidence;
    if (c == null) return const [];
    return [
      _kv('total', c.total.toStringAsFixed(2)),
      _kv('hasTotal', '${c.hasTotal}'),
      _kv('hasVolume', '${c.hasVolume}'),
      _kv('hasPrice', '${c.hasPrice}'),
      _kv('consistent', '${c.isConsistent}'),
    ];
  }

  List<Widget> _gateRows(BuildContext context, AppLocalizations l) {
    final g = package.gate;
    if (g == null) return const [];
    final verdict = g.accepted
        ? (l.ocrTesterGateAccepted)
        : (l.ocrTesterGateRejected);
    return [
      _kv('verdict', verdict),
      _kv('reason', g.reason),
      if (g.identityDelta != null)
        _kv('identityDelta', g.identityDelta!.toStringAsFixed(4)),
      for (final c in g.checks) _kv(c.name, c.passed ? '✓' : '✗'),
    ];
  }

  List<Widget> _brandRows() {
    final r = package.receipt;
    if (r == null) return const [];
    return [
      if (r.brand != null) _kv('brand', r.brand!),
      _kv('layout', r.layout),
    ];
  }

  List<Widget> _overrideRows() {
    final r = package.receipt;
    if (r == null || r.overrides.isEmpty) return const [];
    return [
      for (final o in r.overrides)
        _kv(
          o.field,
          '/${o.pattern}/ → "${o.match}"'
          '${o.value != null ? ' = ${o.value}' : ''}',
        ),
    ];
  }

  List<Widget> _reconcileRows() {
    final rec = package.receipt?.reconcile;
    if (rec == null) return const [];
    return [
      if (rec.read != null) _kv('read', '${rec.read}'),
      if (rec.derived != null) _kv('derived', '${rec.derived}'),
      if (rec.predictedTotal != null)
        _kv('predictedTotal', '${rec.predictedTotal}'),
      if (rec.delta != null) _kv('delta', '${rec.delta}'),
    ];
  }

  List<Widget> _resultRows(BuildContext context, AppLocalizations l) {
    final r = package.result;
    if (r == null) return const [];
    return [
      _ResultRow(
        label: 'total',
        value: r.totalCost,
        derived: r.derived,
        field: 'total',
      ),
      _ResultRow(
        label: 'volume',
        value: r.liters,
        derived: r.derived,
        field: 'volume',
      ),
      _ResultRow(
        label: 'pricePerLitre',
        value: r.pricePerLiter,
        derived: r.derived,
        field: 'pricePerLitre',
      ),
      _kv('confidence', r.confidence.toStringAsFixed(2)),
      _kv('validated', '${r.validated}'),
      if (r.validationReason != null) _kv('reason', r.validationReason!),
    ];
  }

  static Widget _kv(String k, String v) => _KvRow(label: k, value: v);
}
