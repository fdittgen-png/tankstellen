// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Through the barrel, not the file: feature_boundary_test counts
// non-barrel reach-ins per pair, and `search -> route_search` is at its
// baseline. api.dart exports route_search_strategy.dart (#3132).
import '../../route_search/api.dart';
import '../presentation/widgets/sort_selector.dart';

/// What the user actually arrived with (#4138).
///
/// The criteria sheet asks for fuel type, radius, sort order, mode,
/// strategy, segment length, max detour and minimum saving. Those are
/// the knobs the ENGINE needs. The user arrives with one of about five
/// intents, and each of those implies a configuration the app can set
/// itself.
///
/// ## Presets, not a second search path
///
/// An intent is a named set of values for parameters that already
/// exist. There is no new ranking, no new query and no new provider —
/// `#4138`'s first acceptance criterion is explicit about that, and
/// `docs/specs/refuel-economics.md` §3 forbids naming one station
/// objectively best, so [bestStop] selects a SORT (`bestValue`), never
/// a verdict.
///
/// ## Visible and reversible
///
/// Applying an intent is a one-way write into the existing providers.
/// The knobs stay authoritative: [detectIntent] re-derives which intent
/// (if any) the current parameters still match, so touching any control
/// moves the selection to "Custom" rather than leaving a label that
/// silently contradicts the state.
enum SearchIntent {
  /// The cheapest pump within reach, right now.
  cheapestNearby,

  /// Best value once the drive there is paid for — #4088's effective
  /// price per litre, which is what [SortMode.bestValue] ranks by.
  ///
  /// Requires a known consumption: without it the drive cost cannot be
  /// computed, so the intent is offered DISABLED with the reason rather
  /// than silently falling back to a plain price sort (trust rule 1).
  bestStop,

  /// Stations along a planned route.
  onMyRoute,

  /// The nearest option, cost second.
  fastest,

  /// Go straight to a station the user already chose.
  aFavourite,
}

/// The parameter set an intent implies.
///
/// Only the fields an intent actually decides are non-null. A null
/// means "leave whatever the user (or their profile) already had" —
/// #4138 says intents configure, they do not reset the sheet.
class SearchIntentPreset {
  const SearchIntentPreset({
    required this.intent,
    this.sortMode,
    this.routeStrategy,
    this.openOnly,
    this.excludeHighway,
    this.resultKindFuelOnly,
    this.requiresRoute = false,
    this.requiresConsumption = false,
    this.requiresFavourites = false,
  });

  final SearchIntent intent;

  final SortMode? sortMode;
  final RouteSearchStrategyType? routeStrategy;
  final bool? openOnly;
  final bool? excludeHighway;
  final bool? resultKindFuelOnly;

  /// The intent only makes sense in route mode.
  final bool requiresRoute;

  /// Needs a known vehicle consumption ([bestStop]).
  final bool requiresConsumption;

  /// Needs at least one favourite ([aFavourite]).
  final bool requiresFavourites;
}

/// The canonical presets — defined once, here.
const Map<SearchIntent, SearchIntentPreset> searchIntentPresets = {
  SearchIntent.cheapestNearby: SearchIntentPreset(
    intent: SearchIntent.cheapestNearby,
    sortMode: SortMode.price,
    openOnly: true,
  ),
  SearchIntent.bestStop: SearchIntentPreset(
    intent: SearchIntent.bestStop,
    // #4088 — effective price per litre: pump price plus what the drive
    // there costs, over the litres bought.
    sortMode: SortMode.bestValue,
    openOnly: true,
    requiresConsumption: true,
  ),
  SearchIntent.onMyRoute: SearchIntentPreset(
    intent: SearchIntent.onMyRoute,
    sortMode: SortMode.price,
    routeStrategy: RouteSearchStrategyType.cheapest,
    openOnly: true,
    requiresRoute: true,
  ),
  SearchIntent.fastest: SearchIntentPreset(
    intent: SearchIntent.fastest,
    sortMode: SortMode.distance,
    openOnly: true,
    // A detour onto a motorway service station is the opposite of fast
    // for a driver who is not already on one.
    excludeHighway: false,
  ),
  SearchIntent.aFavourite: SearchIntentPreset(
    intent: SearchIntent.aFavourite,
    sortMode: SortMode.distance,
    resultKindFuelOnly: false,
    requiresFavourites: true,
  ),
};

/// The parameters an intent selection is judged against.
///
/// A plain record rather than a widget read, so [detectIntent] is pure
/// and testable without a container.
typedef SearchIntentState = ({
  SortMode sortMode,
  RouteSearchStrategyType routeStrategy,
  bool openOnly,
  bool excludeHighway,
  bool routeMode,
});

/// Which intent [state] still matches, or null for "Custom".
///
/// Null is the honest answer the moment any knob diverges — #4138's
/// third acceptance criterion is that the sheet never shows a label
/// that no longer matches the state.
SearchIntent? detectIntent(SearchIntentState state) {
  for (final preset in searchIntentPresets.values) {
    if (preset.requiresRoute != state.routeMode) continue;
    if (preset.sortMode != null && preset.sortMode != state.sortMode) {
      continue;
    }
    if (preset.routeStrategy != null &&
        preset.routeStrategy != state.routeStrategy) {
      continue;
    }
    if (preset.openOnly != null && preset.openOnly != state.openOnly) {
      continue;
    }
    if (preset.excludeHighway != null &&
        preset.excludeHighway != state.excludeHighway) {
      continue;
    }
    return preset.intent;
  }
  return null;
}

/// Whether [intent] can be offered, given what the app knows.
///
/// Returns null when it is available; otherwise the reason it is not,
/// as a [SearchIntentBlocker] the UI turns into one line of copy.
SearchIntentBlocker? blockerFor(
  SearchIntent intent, {
  required bool hasConsumption,
  required bool hasFavourites,
  required bool hasRoute,
}) {
  final preset = searchIntentPresets[intent]!;
  if (preset.requiresConsumption && !hasConsumption) {
    return SearchIntentBlocker.consumptionUnknown;
  }
  if (preset.requiresFavourites && !hasFavourites) {
    return SearchIntentBlocker.noFavourites;
  }
  if (preset.requiresRoute && !hasRoute) {
    return SearchIntentBlocker.noRoute;
  }
  return null;
}

/// Why an intent cannot be offered.
enum SearchIntentBlocker {
  /// No measured or estimated consumption, so the drive cost that
  /// [SearchIntent.bestStop] ranks by cannot be computed.
  consumptionUnknown,

  /// Nothing has been favourited yet.
  noFavourites,

  /// Route mode with no route entered.
  noRoute,
}
