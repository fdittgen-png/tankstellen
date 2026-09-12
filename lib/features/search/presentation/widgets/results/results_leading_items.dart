// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/domain/search_result_item.dart';
import '../../../../../core/storage/storage_keys.dart';
import '../../../../../core/widgets/help_banner.dart';
import 'decision_header.dart';

/// What rides above the station cards INSIDE the results list.
///
/// Both of these are list items rather than bands above the list, and for
/// the same reason (#3937): on a screen whose purpose is comparing
/// stations, anything that is not a station has to move out of the way on
/// the first flick instead of holding height at every scroll position.
///
/// Owning the index arithmetic here keeps `SearchResultsList` from
/// growing a third `rawIndex - (showX ? 1 : 0)` expression every time
/// something else earns a place at the top — the shape of bug where the
/// count and the builder disagree by one and the last station vanishes.
///
/// The landscape radar pane, which trades every non-essential row for
/// vertical room, carries neither.
@immutable
class ResultsLeadingItems {
  const ResultsLeadingItems({
    required this.showDecision,
    required this.showHelp,
  });

  /// #4090 — the three answers, above the list they speak for.
  final bool showDecision;

  /// #3937 — the paged help bubble the user reads once.
  final bool showHelp;

  /// How many list slots these occupy.
  int get count => (showDecision ? 1 : 0) + (showHelp ? 1 : 0);

  /// The widget for [rawIndex], or `null` when that index is a station
  /// row — in which case the caller subtracts [count] to get the
  /// station's own index.
  Widget? itemAt(int rawIndex, List<SearchResultItem> sorted) {
    if (showDecision && rawIndex == 0) return DecisionHeader(items: sorted);
    if (showHelp && rawIndex == (showDecision ? 1 : 0)) {
      return const HelpBanner(
        storageKey: StorageKeys.helpBannerSearchResults,
        icon: Icons.lightbulb_outline,
        surface: HelpSurface.searchResults,
      );
    }
    return null;
  }
}
