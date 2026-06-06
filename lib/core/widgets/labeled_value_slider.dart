// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// A [Slider] that *always* shows its current value at rest.
///
/// `Slider(label: ...)` only paints the value inside the drag bubble while
/// the thumb is being dragged — at rest the user sees a bare track with no
/// readout (#2920). This widget wraps the slider in a
/// `label · Expanded(Slider) · trailing-value` [Row] so the current value
/// is visible at all times, mirroring the Edit-profile radius slider.
///
/// It is the single source of truth for this pattern: both
/// `ProfileRadiusSlider` and the Voice-Announcements sliders compose it.
///
/// The [valueLabel] is rendered both as the persistent trailing readout
/// *and* as the slider's drag-bubble [Slider.label], so the in-drag bubble
/// and the at-rest readout agree.
class LabeledValueSlider extends StatelessWidget {
  /// Leading description of what the slider controls (already localized).
  final String label;

  /// The current value formatted for display (e.g. `"2.5 km"`, `"30 min"`,
  /// a formatted price). Shown as the persistent trailing readout.
  final String valueLabel;

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  /// Optional [Key] forwarded to the inner [Slider] so existing tests and
  /// call sites that target the slider by key keep working.
  final Key? sliderKey;

  /// Optional text style for the leading [label] (defaults to the slider's
  /// surrounding text style).
  final TextStyle? labelStyle;

  const LabeledValueSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.sliderKey,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: Text(label, style: labelStyle)),
        Expanded(
          flex: 2,
          child: Slider(
            key: sliderKey,
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ),
        Text(valueLabel, style: labelStyle),
      ],
    );
  }
}
