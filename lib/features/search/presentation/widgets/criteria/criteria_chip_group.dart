// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// A wrapping group of criteria chips with a "Show more (n)" affordance
/// (#3927, Epic #3925).
///
/// The criteria sheet used to render its fuel / amenity / brand chips in
/// horizontal scrollers. Those clipped mid-word ("W…", "Intermarch…"),
/// gave no affordance that anything was off-screen, and — worst — could
/// hide the user's OWN selection past the right edge (the E85 report on
/// the 2026-09-02 screenshots).
///
/// This group fixes all three at once:
///   * chips [Wrap] onto as many rows as they need, so nothing is clipped;
///   * collapsed, it shows the first [collapsedCount] chips **plus every
///     selected chip** — a selection can never be hidden, whatever its
///     position;
///   * the remainder is reachable through one "Show more (n)" chip (and
///     foldable again through "Show less").
///
/// [pinned] chips (e.g. the brand group's "All" / highway toggles) always
/// render first and never count against the collapse budget.
class CriteriaChipGroup extends StatefulWidget {
  const CriteriaChipGroup({
    super.key,
    required this.chips,
    required this.selectedFlags,
    this.pinned = const <Widget>[],
    this.collapsedCount = 6,
    this.groupKeyPrefix = 'criteria',
  });

  /// The collapsible chips, in display order.
  final List<Widget> chips;

  /// Selection flag per entry of [chips] (same length). A selected chip is
  /// always visible, even past the collapse cut.
  final List<bool> selectedFlags;

  /// Chips that always render, ahead of [chips], outside the collapse budget.
  final List<Widget> pinned;

  /// How many of [chips] stay visible while collapsed — roughly two rows
  /// at 360 dp for label-sized chips.
  final int collapsedCount;

  /// Prefix for the show-more / show-less widget keys so several groups on
  /// one screen stay individually addressable from tests.
  final String groupKeyPrefix;

  @override
  State<CriteriaChipGroup> createState() => _CriteriaChipGroupState();
}

class _CriteriaChipGroupState extends State<CriteriaChipGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = <Widget>[...widget.pinned];
    var hidden = 0;
    for (var i = 0; i < widget.chips.length; i++) {
      final selected =
          i < widget.selectedFlags.length && widget.selectedFlags[i];
      if (_expanded || i < widget.collapsedCount || selected) {
        visible.add(widget.chips[i]);
      } else {
        hidden++;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...visible,
        if (hidden > 0)
          ActionChip(
            key: ValueKey('${widget.groupKeyPrefix}-show-more'),
            avatar: const Icon(Icons.expand_more, size: 18),
            label: Text(l10n.criteriaShowMore(hidden)),
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _expanded = true),
          )
        else if (_expanded && widget.chips.length > widget.collapsedCount)
          ActionChip(
            key: ValueKey('${widget.groupKeyPrefix}-show-less'),
            avatar: const Icon(Icons.expand_less, size: 18),
            label: Text(l10n.criteriaShowLess),
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _expanded = false),
          ),
      ],
    );
  }
}
