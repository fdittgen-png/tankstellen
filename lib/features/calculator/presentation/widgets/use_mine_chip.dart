// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// "Use mine" prefill affordance for a calculator input (#2543).
///
/// Renders an [ActionChip] labelled with the live source value
/// (e.g. "Use 150.0 km") that, when tapped, applies that value to the
/// field. The host hides the chip entirely when its source is null, so
/// this widget assumes a non-null [valueLabel] and never renders a
/// placeholder itself.
class UseMineChip extends StatelessWidget {
  /// Formatted source value shown in the chip (already unit/currency
  /// correct — the host passes a `UnitFormatter`/`PriceFormatter`
  /// string).
  final String valueLabel;

  /// Prefix shown before [valueLabel], e.g. "Use" / "Applied". Already
  /// localised by the caller.
  final String prefix;

  /// Whether this source has already been applied (the route-supplied
  /// price). Renders a check icon and disables the tap.
  final bool applied;

  final VoidCallback onApply;

  const UseMineChip({
    super.key,
    required this.valueLabel,
    required this.prefix,
    required this.onApply,
    this.applied = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = '$prefix $valueLabel';
    if (applied) {
      return Chip(
        avatar: const Icon(Icons.check, size: 16),
        label: Text(label),
        visualDensity: VisualDensity.compact,
      );
    }
    return ActionChip(
      avatar: const Icon(Icons.auto_awesome, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      onPressed: onApply,
    );
  }
}
