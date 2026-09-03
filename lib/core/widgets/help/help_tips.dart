// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../l10n/app_localizations.dart';

/// Every surface whose help bubble carries MORE than one tip (#3938,
/// Epic #3937).
///
/// The principle behind the epic: an icon that carries the meaning gets no
/// label, and **explanation is not chrome**. Everything the results screen
/// used to spend permanent height explaining — the two-line all-prices
/// legend, what the price arrows actually rank — lives here instead, in a
/// bubble the user pages through once and then dismisses forever.
///
/// The four pre-#3938 surfaces (search criteria, alerts, consumption,
/// vehicles) still pass their single `message:` straight to `HelpBanner`;
/// a one-message bubble renders exactly as it always did, with no chevrons
/// and no indicator. They join this catalog the day they get a second tip.
enum HelpSurface {
  /// The station results list — the surface the epic reclaimed.
  searchResults,
}

/// The tips [surface] teaches, ordered **basic → deeper**: the first tip is
/// what a first-time user needs, the last is the trick a returning user
/// has not met yet. The bubble's position memory rotates through them, so
/// ordering is a teaching order, not a priority order.
///
/// Never empty — a surface in the enum owes the bubble at least one tip.
List<String> helpTipsFor(AppLocalizations l10n, HelpSurface surface) =>
    switch (surface) {
      HelpSurface.searchResults => <String>[
        // 1 — where the whole search is steered from. The summary bar is a
        // band of grey pills; nothing on it says "tap me".
        l10n.helpSearchTipSummaryBar,
        // 2 — the fill emphasis, evicted from the all-prices column header
        // (#3939). It only ever needed saying once.
        l10n.helpSearchTipFillEmphasis,
        // 3 — the second figure in an all-prices cell, the other half of
        // that deleted legend.
        l10n.helpSearchTipSecondFigure,
        // 4 — the ↓ – ↑ glyph beside a compact-card price. `priceTierOf()`
        // classifies the price WITHIN the current result set (bottom /
        // middle / top third), so it is a ranking, never a time trend —
        // the single most misread mark on the screen.
        l10n.helpSearchTipPriceArrows,
        // 5 — the view toggle, the deepest of the five: it exists only
        // once the user wants to compare fuels rather than stations.
        l10n.helpSearchTipViewToggle,
      ],
    };

/// Where a fresh visit opens: the tip AFTER [lastShown], wrapping.
///
/// A never-visited surface (`null`) opens on tip 1. A stored index from a
/// tip list that has since grown or shrunk is taken modulo [tipCount], so
/// an old device never lands out of range.
int initialTipIndex(int? lastShown, int tipCount) {
  if (tipCount <= 0) return 0;
  if (lastShown == null) return 0;
  return ((lastShown + 1) % tipCount + tipCount) % tipCount;
}
