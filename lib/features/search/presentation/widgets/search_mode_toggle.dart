// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/search_mode.dart';

/// Two-button SegmentedButton that switches between *nearby* and *along
/// route* search modes. Stateless: the parent owns the [SearchMode] state
/// and receives changes via [onChanged].
///
/// #3927 — the toggle used to render the full sentences ("Nearby stations"
/// / "Search along route") and wrapped them over two lines on a phone.
/// It now renders the SHORT labels, keeps the long form on each segment's
/// tooltip (so nothing is lost for screen readers or a long-press), and
/// under width pressure drops the leading icons rather than the words.
/// A label never wraps and never breaks a word: it is a single line that
/// ellipsises only in the pathological case (en_XA at 320 dp).
class SearchModeToggle extends StatelessWidget {
  final SearchMode mode;
  final ValueChanged<SearchMode> onChanged;

  const SearchModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  /// Below this much width *per segment* (in unscaled logical pixels) the
  /// icons go and the label gets the whole segment. Two ~16 dp icons plus
  /// their 8 dp gaps cost about a third of a 320 dp phone's segment.
  static const double _iconDropSegmentWidth = 116;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Text scaling eats the same budget as a narrow screen, so fold
        // it into one number: the width one segment has per unit of text.
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final perSegment = constraints.hasBoundedWidth
            ? constraints.maxWidth / 2 / (textScale <= 0 ? 1 : textScale)
            : double.infinity;
        final showIcons = perSegment >= _iconDropSegmentWidth;
        return SegmentedButton<SearchMode>(
          key: const ValueKey('criteria-mode-toggle'),
          segments: [
            ButtonSegment(
              value: SearchMode.nearby,
              label: _SegmentLabel(l10n.criteriaModeNearby),
              icon: showIcons ? const Icon(Icons.near_me) : null,
              tooltip: l10n.searchNearby,
            ),
            ButtonSegment(
              value: SearchMode.route,
              label: _SegmentLabel(l10n.criteriaModeRoute),
              icon: showIcons ? const Icon(Icons.route) : null,
              tooltip: l10n.searchAlongRoute,
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selected) => onChanged(selected.first),
        );
      },
    );
  }
}

/// A segment label that stays on one line whatever the translation does.
/// `SegmentedButton` already wraps the label in a `Flexible`, so a
/// single-line, ellipsising `Text` can never overflow its segment.
class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
  );
}
