import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/search_result_item.dart';
import '../domain/entities/station.dart';
import 'search_provider.dart';

part 'search_filters_provider.g.dart';

/// Stores the resolved search location for display (ZIP + city).
@riverpod
class SearchLocation extends _$SearchLocation {
  @override
  String build() => '';

  void set(String location) => state = location;
}

@riverpod
class SelectedFuelType extends _$SelectedFuelType {
  @override
  FuelType build() {
    // Effective fuel (#704): when a profile is configured, the default
    // vehicle's fuel overrides the profile's own preferredFuelType so
    // the chips reflect "what does my car actually take" without the
    // user having to keep profile + vehicle manually in sync.
    //
    // No profile yet (fresh install, before the onboarding wizard) →
    // keep the historical "FuelType.all" wildcard so the first search
    // doesn't silently filter out non-E10 pumps.
    final profile = ref.watch(activeProfileProvider);
    if (profile == null) return FuelType.all;
    return ref.watch(effectiveFuelTypeProvider);
  }

  void select(FuelType type) {
    state = type;
  }
}

@riverpod
class SearchRadius extends _$SearchRadius {
  @override
  double build() {
    final profile = ref.watch(activeProfileProvider);
    return profile?.defaultSearchRadius ?? 10.0;
  }

  void set(double radius) {
    state = radius.clamp(1.0, 25.0);
  }
}

/// Extracts fuel [Station] objects from the unified search results.
///
/// Convenience for consumers that need [List<Station>] (cross-border
/// comparisons, driving mode, station detail lookup, brand filter chips).
@riverpod
List<Station> fuelStations(Ref ref) {
  final searchState = ref.watch(searchStateProvider);
  if (!searchState.hasValue) return const [];
  return searchState.value!.data
      .whereType<FuelStationResult>()
      .map((r) => r.station)
      .toList();
}
