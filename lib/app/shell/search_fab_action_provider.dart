// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_fab_action_provider.g.dart';

/// Override hook for the central search FAB in [ShellBottomBar] (#2113).
///
/// The FAB normally jumps to the Search branch. Surfaces that want
/// the same hit-target to do something contextual (e.g. the criteria
/// screen wants the FAB to *fire* the active search, the results
/// screen wants it to *open* criteria for refining) register a
/// [SearchFabAction] here in their `initState`/`didChangeDependencies`
/// and clear it in `dispose`. While the action is set, [ShellBottomBar]
/// reads it and:
///   - swaps the FAB icon to [SearchFabAction.icon],
///   - swaps the tooltip to [SearchFabAction.tooltip],
///   - calls [SearchFabAction.onTap] instead of the default branch jump.
///
/// `null` (the default) restores the original "jump to Search branch"
/// behaviour so every tab that doesn't opt in keeps working unchanged.
class SearchFabAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// When false, [ShellBottomBar] greys the icon and treats taps as a
  /// no-op. Lets the criteria screen mirror the inline submit button's
  /// disabled state (e.g. route tab with no destination yet) without
  /// the registrant having to manage two separate actions.
  final bool enabled;

  const SearchFabAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });
}

@Riverpod(keepAlive: true)
class SearchFabActionController extends _$SearchFabActionController {
  @override
  SearchFabAction? build() => null;

  /// Replace the current FAB action. Pass null to clear.
  void set(SearchFabAction? action) {
    state = action;
  }

  /// Clears the action only if the currently-held action matches the
  /// one the caller previously set. Lets a screen safely call this
  /// from `dispose` without stomping on a sibling that already
  /// registered. Comparison is by identity — both `set` and `clearIf`
  /// use the same `SearchFabAction` instance.
  void clearIf(SearchFabAction action) {
    if (identical(state, action)) state = null;
  }
}
