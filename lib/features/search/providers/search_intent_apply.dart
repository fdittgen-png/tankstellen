// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/search_intent.dart';
import 'brand_filter_provider.dart';
import 'mixed_results_filter_provider.dart';
import 'search_screen_ui_provider.dart';

/// Applying an intent (#4138) — the one place a preset becomes state.
///
/// The domain owns WHAT an intent means ([searchIntentPresets]); this
/// owns writing it through the controls that already exist. There is no
/// new parameter and no second search path: every line below is a
/// setter the criteria sheet's own widgets call.
///
/// A null field on the preset is deliberately skipped rather than
/// written as a default — an intent configures what it decides and
/// leaves the rest as the user (or their profile) had it.
void applySearchIntent(WidgetRef ref, SearchIntent intent) {
  final preset = searchIntentPresets[intent]!;

  final sortMode = preset.sortMode;
  if (sortMode != null) {
    ref.read(selectedSortModeProvider.notifier).set(sortMode);
  }

  final strategy = preset.routeStrategy;
  if (strategy != null) {
    ref.read(selectedRouteStrategyProvider.notifier).set(strategy);
  }

  final openOnly = preset.openOnly;
  if (openOnly != null) {
    ref.read(openOnlyFilterProvider.notifier).set(openOnly);
  }

  final excludeHighway = preset.excludeHighway;
  if (excludeHighway != null) {
    ref.read(excludeHighwayStationsProvider.notifier).set(excludeHighway);
  }

  final fuelOnly = preset.resultKindFuelOnly;
  if (fuelOnly != null) {
    ref
        .read(resultKindFilterProvider.notifier)
        .set(fuelOnly ? ResultKind.fuel : ResultKind.both);
  }
}

/// The parameters [detectIntent] judges, read from the live providers.
SearchIntentState readSearchIntentState(WidgetRef ref, {required bool routeMode}) => (
      sortMode: ref.watch(selectedSortModeProvider),
      routeStrategy: ref.watch(selectedRouteStrategyProvider),
      openOnly: ref.watch(openOnlyFilterProvider),
      excludeHighway: ref.watch(excludeHighwayStationsProvider),
      routeMode: routeMode,
    );
