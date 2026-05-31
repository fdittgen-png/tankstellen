// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Presentational row / tile widgets for the OCR-tester steps panel
// (#2518). Part of `ocr_trace_steps_panel.dart` so it shares that
// library's imports and the two files stay under the 400-line norm.
part of 'ocr_trace_steps_panel.dart';

/// One ExpansionTile for a single stage. Renders a muted "did not run"
/// line when [children] is empty so the pipeline path is still legible.
class _StageTile extends StatelessWidget {
  final OcrTraceStage stage;
  final String label;
  final List<Widget> children;

  const _StageTile({
    super.key,
    required this.stage,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ran = children.isNotEmpty;
    return ExpansionTile(
      title: Text(label),
      leading: Icon(
        ran ? Icons.check_circle_outline : Icons.remove_circle_outline,
        color: ran
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: ran
          ? children
          : [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l?.ocrTesterStageNoData ?? 'Stage did not run.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
    );
  }
}

/// A mono-ish key/value detail row inside a stage tile.
class _KvRow extends StatelessWidget {
  final String label;
  final String value;

  const _KvRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// One classification block row, tinted by its kind colour.
class _ClassifyRow extends StatelessWidget {
  final OcrTraceClassification classification;

  const _ClassifyRow({required this.classification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (classification.kind) {
      'label' => OcrBlockOverlayColors.label,
      'numeric' => OcrBlockOverlayColors.numeric,
      _ => OcrBlockOverlayColors.noise,
    };
    final detail = classification.field ??
        (classification.value != null ? '${classification.value}' : '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.crop_square, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '"${classification.text}" · ${classification.kind}'
              '${detail.isEmpty ? '' : ' · $detail'}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// One anchor candidate row; the chosen pair is bolded.
class _AnchorRow extends StatelessWidget {
  final OcrTraceAnchor anchor;

  const _AnchorRow({required this.anchor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${anchor.labelField}: "${anchor.labelText}" → ${anchor.numericValue}'
        ' (d²=${anchor.sqDistance.toStringAsFixed(0)})',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: anchor.chosen ? FontWeight.w700 : FontWeight.w400,
          color: anchor.chosen
              ? OcrBlockOverlayColors.anchor
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// A final-read value row with a READ / DERIVED chip.
class _ResultRow extends StatelessWidget {
  final String label;
  final double? value;
  final Set<String> derived;
  final String field;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.derived,
    required this.field,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (value == null) return const SizedBox.shrink();
    final isDerived = derived.contains(field);
    final chipText = isDerived
        ? (l?.ocrTesterChipDerived ?? 'DERIVED')
        : (l?.ocrTesterChipRead ?? 'READ');
    final chipColor = isDerived
        ? OcrBlockOverlayColors.derived
        : OcrBlockOverlayColors.numeric;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text('$value', style: theme.textTheme.bodyMedium),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              chipText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The amber fallback banner shown above the stage list when the
/// magnitude-fallback stage bound a field.
class _FallbackBanner extends StatelessWidget {
  final String text;

  const _FallbackBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('ocr_steps_fallback_banner'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: OcrBlockOverlayColors.derived.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: OcrBlockOverlayColors.derived, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
