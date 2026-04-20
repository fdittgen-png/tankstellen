import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/search/domain/entities/fuel_type.dart';
import 'country_provider.dart';

part 'fuel_type_picker_provider.g.dart';

/// Single source of truth for every fuel-type dropdown in the app
/// (#703). Returns the active country's supportedFuelTypes, with
/// [FuelType.all] filtered out (it is a search-time wildcard, not a
/// real preference).
///
/// Consumers:
/// - FuelTypeDropdown (defaults to this when no `options` override)
/// - NullableFuelTypeDropdown (same)
/// - Future: profile-save validator that rejects a preferredFuelType
///   not in this list
///
/// Switching country invalidates every dependent picker through
/// Riverpod's normal dependency tracking — no manual wiring needed.
@riverpod
List<FuelType> fuelTypePicker(Ref ref) {
  final country = ref.watch(activeCountryProvider);
  return country.supportedFuelTypes
      .where((f) => f != FuelType.all)
      .toList();
}
