// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

enum SortMode { distance, price, name, open24h, rating, priceDistance }

/// The sort group that now lives **inside** the results icon row (#3943).
///
/// #3926 gave the chips a `Wrap` of their own, which cost the results
/// screen a whole strip — two lines of it once six chips no longer fit one.
/// #3939 then made the three self-evident chips icon-only. #3943 finishes
/// the move: only those three glyph chips stay on screen, they join the
/// radar / filter / view / overflow row, and the strip is gone.
///
/// The three demoted modes (`A-Z`, `24h`, `Price/km`) are NOT deleted —
/// they moved into the labelled overflow menu (`ResultsActionMenu`), the
/// same pattern #3926 used for the map / radar-scope / calculator actions.
///
/// ## Why a scroll view, not a `Wrap` or a `LayoutBuilder`
/// The row must not overflow at 320 dp under a 1.3x text scale with three
/// chips plus four controls. A `LayoutBuilder` cannot help: a non-flex
/// child of a `Row` is laid out with unbounded width, so nothing inside it
/// can measure the room actually left. Instead the caller puts this widget
/// in an [Expanded] — a genuinely bounded slot, whatever the fixed
/// controls take — and the group scrolls inside that slot rather than
/// pushing the row past its own width. At every size in the support
/// matrix the three chips fit with room to spare; the scroller is the
/// guarantee, not the everyday experience.
class SortSelector extends StatelessWidget {
  final SortMode selected;
  final ValueChanged<SortMode> onChanged;

  const SortSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// The modes that keep a visible chip: their glyph is unambiguous (the
  /// navigation arrow is distance, the euro sign is price, the star is
  /// rating). Every other mode is a labelled entry in the overflow menu.
  static const List<SortMode> visibleModes = <SortMode>[
    SortMode.distance,
    SortMode.price,
    SortMode.rating,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SortChip(
            label: l10n.sortDistance,
            icon: Icons.near_me,
            selected: selected == SortMode.distance,
            onSelected: () => onChanged(SortMode.distance),
          ),
          const SizedBox(width: 4),
          _SortChip(
            label: l10n.price,
            icon: Icons.euro,
            selected: selected == SortMode.price,
            onSelected: () => onChanged(SortMode.price),
          ),
          const SizedBox(width: 4),
          _SortChip(
            label: l10n.sortRating,
            icon: Icons.star,
            selected: selected == SortMode.rating,
            onSelected: () => onChanged(SortMode.rating),
          ),
        ],
      ),
    );
  }
}

/// One icon-only sort chip.
///
/// #3939 — the visible word is dropped: the glyph already says it. The
/// label survives in the tooltip and in the semantics sentence, so the
/// chip is never a mystery to a long-press or a screen reader.
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
    final chip = ChoiceChip(
      label: Icon(icon, size: 18),
      labelStyle: Theme.of(context).textTheme.labelSmall,
      selected: selected,
      onSelected: (_) => onSelected(),
      // An icon-only ChoiceChip would swap its ONE glyph for a checkmark
      // when selected, leaving a bare tick that says nothing about which
      // sort is on. Keep the glyph; the chip's selected fill, its outline
      // and the semantics sentence carry the state.
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      // The chips sit shoulder to shoulder; without the word the icon
      // needs a little air of its own to stay a tappable target.
      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      tooltip: label,
    );
    return Semantics(
      label: AppLocalizations.of(context).sortBySemantic(label, '$selected'),
      child: chip,
    );
  }
}
