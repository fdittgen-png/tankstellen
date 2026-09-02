// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// One aligned criteria option: label + value on a single line, the control
/// full-width beneath it, then a helper caption (#3927, Epic #3925).
///
/// The route options used to be `Row(Text(label), Expanded(Slider),
/// Text(value))` triples. Because the labels differ in width ("Route
/// segment" vs "Minimum saving"), every slider track started at a
/// different x and the block read as three unrelated controls. Giving the
/// label its own line and stretching the control edge-to-edge makes every
/// track start at the same x, whatever the translation does to the label.
class CriteriaOptionRow extends StatelessWidget {
  const CriteriaOptionRow({
    super.key,
    required this.label,
    required this.value,
    required this.child,
    this.caption,
  });

  /// Localized option name, e.g. "Route segment".
  final String label;

  /// The current value, rendered at the end of the label line.
  final String value;

  /// The full-width control — a [Slider] or a chip group.
  final Widget child;

  /// Optional helper sentence below the control.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = this.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.titleSmall),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        child,
        if (caption != null)
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// A [Slider] with the criteria sheet's compact reaction overlay (#1962),
/// stretched to the full row width so every option's track starts at the
/// same x.
class CriteriaOptionSlider extends StatelessWidget {
  const CriteriaOptionSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}
