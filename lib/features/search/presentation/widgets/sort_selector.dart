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
///
/// #3939 (Epic #3937) — the three chips whose glyph is unambiguous render
/// **icon-only**: the navigation arrow is distance, the euro sign is
/// price, the star is rating. `A-Z`, `24h` and `Prix/km` keep their words,
/// because no glyph says those. Every icon-only chip carries its label as
/// a tooltip AND inside its semantics label, so a long-press and a screen
/// reader still get the word.
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
            iconOnly: true,
            selected: selected == SortMode.distance,
            onSelected: () => onChanged(SortMode.distance),
          ),
          _SortChip(
            label: l10n.price,
            icon: Icons.euro,
            iconOnly: true,
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
            iconOnly: true,
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

  /// #3939 — drop the visible word: the glyph already says it. Only ever
  /// true where the glyph is unambiguous (distance, price, rating). The
  /// label survives in the tooltip and in the semantics sentence, so the
  /// chip is never a mystery to a long-press or a screen reader.
  final bool iconOnly;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final chip = ChoiceChip(
      avatar: iconOnly ? null : Icon(icon, size: 14),
      label: iconOnly ? Icon(icon, size: 18) : Text(label),
      labelStyle: Theme.of(context).textTheme.labelSmall,
      selected: selected,
      onSelected: (_) => onSelected(),
      // An icon-only ChoiceChip would swap its ONE glyph for a checkmark
      // when selected, leaving a bare tick that says nothing about which
      // sort is on. Keep the glyph; the chip's selected fill, its outline
      // and the semantics sentence carry the state.
      showCheckmark: !iconOnly,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      // The chips sit shoulder to shoulder; without the word the icon
      // needs a little air of its own to stay a tappable target.
      labelPadding: iconOnly
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : null,
      tooltip: iconOnly ? label : null,
    );
    return Semantics(
      label: AppLocalizations.of(context).sortBySemantic(label, '$selected'),
      child: chip,
    );
  }
}
