// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

enum SortMode { distance, price, name, open24h, rating, priceDistance }

/// The sort chips on the results row (row B).
///
/// #3926 — was a horizontally scrolling [Row]: at 320 dp it cut the "24h"
/// chip in half at the right edge, and the three chips past it were
/// invisible with no affordance saying so. A [Wrap] moves a whole chip to
/// the next line instead, so a chip is never clipped mid-glyph in any
/// locale or at any text scale — and every sort option stays reachable
/// without a horizontal drag.
class SortSelector extends StatelessWidget {
  final SortMode selected;
  final ValueChanged<SortMode> onChanged;

  const SortSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        children: [
          _SortChip(
            label: l10n.sortDistance,
            icon: Icons.near_me,
            selected: selected == SortMode.distance,
            onSelected: () => onChanged(SortMode.distance),
          ),
          _SortChip(
            label: l10n.price,
            icon: Icons.euro,
            selected: selected == SortMode.price,
            onSelected: () => onChanged(SortMode.price),
          ),
          _SortChip(
            label: 'A-Z',
            icon: Icons.sort_by_alpha,
            selected: selected == SortMode.name,
            onSelected: () => onChanged(SortMode.name),
          ),
          _SortChip(
            label: l10n.sortOpen24h,
            icon: Icons.schedule,
            selected: selected == SortMode.open24h,
            onSelected: () => onChanged(SortMode.open24h),
          ),
          _SortChip(
            label: l10n.sortRating,
            icon: Icons.star,
            selected: selected == SortMode.rating,
            onSelected: () => onChanged(SortMode.rating),
          ),
          _SortChip(
            label: l10n.sortPriceDistance,
            icon: Icons.balance,
            selected: selected == SortMode.priceDistance,
            onSelected: () => onChanged(SortMode.priceDistance),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).sortBySemantic(label, '$selected'),
      child: ChoiceChip(
        avatar: Icon(icon, size: 14),
        label: Text(label),
        labelStyle: Theme.of(context).textTheme.labelSmall,
        selected: selected,
        onSelected: (_) => onSelected(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
