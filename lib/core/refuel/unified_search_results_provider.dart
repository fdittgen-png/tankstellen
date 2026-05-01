import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/search/domain/entities/search_result_item.dart';
import '../../features/search/providers/ev_search_provider.dart';
import '../../features/search/providers/search_provider.dart';
import 'charging_station_as_refuel_option.dart';
import 'refuel_option.dart';
import 'station_as_refuel_option.dart';
import 'unified_search_results_enabled.dart';

part 'unified_search_results_provider.g.dart';

/// Combines fuel + EV search results into a single
/// [List<RefuelOption>] for the #1116 phase-3 unified search list.
///
/// Phase 3a (this file) lays the foundation. The search screen still
/// reads `searchStateProvider` directly today; phase 3b ships the
/// mixed-card widgets and phase 3c rewires the screen to consume this
/// provider behind the [unifiedSearchResultsEnabledProvider] flag.
///
/// Contract:
///
/// * When the flag is off, returns an empty list. Callers fall back to
///   the legacy fuel-only path. This keeps the no-op semantics until
///   phase 3b/c land.
/// * When the flag is on, walks both upstream sources independently:
///   - the fuel side via [searchStateProvider], mapping
///     [FuelStationResult]s through [StationAsRefuelOption] using the
///     currently selected fuel from [selectedFuelTypeProvider];
///   - the EV side via [eVSearchStateProvider], mapping every
///     [ChargingStation] through [ChargingStationAsRefuelOption].
///   The two lists are concatenated (fuel first, EV after) so the
///   downstream UI can apply its own sort/filter chips deterministically.
/// * Stations whose price for the active fuel is `null` are skipped on
///   the fuel side. The phase-2 [StationAsRefuelOption] returns a null
///   price for those stations, but the unified list is consumed by
///   price-driven UI (lowest-first sort, savings badges); a price-less
///   row would render as a placeholder for no useful reason. Callers
///   that need *every* station regardless of price should keep using
///   `searchStateProvider`.
/// * The provider NEVER throws. Loading and error states on either
///   upstream collapse to an empty contribution from that side; the
///   other side still surfaces. UI consumers treat an empty result
///   list as "no results yet" and rely on the upstream
///   [AsyncValue.isLoading] / `.hasError` flags for spinners + retry
///   affordances (phase 3b).
///
/// Note: this is a synchronous, non-keep-alive provider — Riverpod
/// re-derives it whenever any of the upstreams update, which is the
/// behaviour we want so the unified card list refreshes as the fuel +
/// EV searches land.
@riverpod
List<RefuelOption> unifiedSearchResults(Ref ref) {
  // Flag off → empty. Phase 3b/c will swap the fallback away.
  if (!ref.watch(unifiedSearchResultsEnabledProvider)) {
    return const <RefuelOption>[];
  }

  final fuelOptions = <RefuelOption>[];
  final evOptions = <RefuelOption>[];

  // Fuel side. The selected fuel drives `RefuelPrice` extraction
  // through [StationAsRefuelOption]; stations with no price for that
  // fuel are skipped (see provider doc).
  final fuelType = ref.watch(selectedFuelTypeProvider);
  final fuelState = ref.watch(searchStateProvider);
  final fuelData = fuelState.asData?.value.data;
  if (fuelData != null) {
    for (final item in fuelData) {
      if (item is FuelStationResult) {
        final adapter = StationAsRefuelOption(item.station, fuelType);
        if (adapter.price == null) continue;
        fuelOptions.add(adapter);
      }
    }
  }

  // EV side. The phase-2 adapter computes availability from connector
  // status internally, so we just wrap each charging station.
  final evState = ref.watch(eVSearchStateProvider);
  final evData = evState.asData?.value.data;
  if (evData != null) {
    for (final station in evData) {
      evOptions.add(ChargingStationAsRefuelOption(station));
    }
  }

  return [...fuelOptions, ...evOptions];
}
