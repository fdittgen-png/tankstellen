import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/search/domain/entities/station.dart';
import 'refuel_availability.dart';
import 'refuel_option.dart';
import 'refuel_price.dart';
import 'refuel_provider.dart';

/// [RefuelOption] adapter that wraps a fuel-pump [Station].
///
/// Phase 2 of the fuel/EV unification (#1116). The abstract [RefuelOption]
/// contract from phase 1 stays decoupled from the concrete station model;
/// this adapter does the field-by-field mapping so the unified search list
/// and downstream UI (phase 3) can treat fuel pumps and EV chargers
/// uniformly.
///
/// The adapter is `const` whenever the underlying [Station] is `const`,
/// so it adds no allocation overhead in hot paths.
class StationAsRefuelOption extends RefuelOption {
  /// Wrapped petrol station.
  final Station station;

  /// Which fuel field on [station] should drive [price]. Defaults to
  /// [FuelType.e10] because it is the most widely available pump fuel
  /// in EU markets (and the default the search providers ship with).
  final FuelType fuelType;

  const StationAsRefuelOption(this.station, [this.fuelType = FuelType.e10]);

  @override
  ({double lat, double lng}) get coordinates =>
      (lat: station.lat, lng: station.lng);

  @override
  String get id => 'fuel:${station.id}';

  @override
  RefuelProvider get provider {
    if (station.brand.isEmpty) {
      return RefuelProvider.unknown;
    }
    return RefuelProvider(
      name: station.brand,
      kind: RefuelProviderKind.fuel,
    );
  }

  @override
  RefuelAvailability get availability {
    if (station.is24h || station.isOpen) {
      return RefuelAvailability.open;
    }
    // [Station.isOpen] is currently a non-null `bool`, so reaching
    // here means the upstream API explicitly reported the station as
    // closed. The unknown branch is intentionally absent today; if
    // the model becomes nullable in a future migration the adapter
    // tests will catch the resulting behavior change.
    return RefuelAvailability.closed();
  }

  @override
  RefuelPrice? get price {
    final eur = _eurValueFor(fuelType);
    if (eur == null) return null;
    // Convert EUR/L (or EUR/kg for CNG; see note below) to cents.
    // EU pumps display 0.1-cent precision (e.g. €1.749 → 174.9¢), so
    // we round to one decimal to strip the IEEE-754 float drift
    // (1.749 * 100 == 174.90000000000003) without losing the
    // milli-cent the user actually sees on the totem.
    final cents = double.parse((eur * 100).toStringAsFixed(1));
    return RefuelPrice(
      value: cents,
      // NOTE: `FuelType.cng` advertises `unit: 'EUR/kg'`, but the
      // upstream [Station.cng] field carries an EUR-per-pump-unit value
      // consistent with the other fuel fields (i.e. the country API
      // already returns cost-per-dispensed-unit). We therefore tag CNG
      // as [centsPerLiter] here as well; phase 3 may introduce a
      // dedicated `centsPerKg` unit if a UI consumer needs to
      // distinguish them.
      unit: RefuelPriceUnit.centsPerLiter,
      lastUpdated: _lastUpdated,
    );
  }

  /// Resolve the EUR/L (or EUR/kg) value for [fuel] from [station].
  ///
  /// Returns `null` for fuel types the [Station] model does not
  /// represent ([FuelType.electric], [FuelType.hydrogen],
  /// [FuelType.all]) and for cases where the chosen field is itself
  /// `null` on this station.
  double? _eurValueFor(FuelType fuel) {
    return switch (fuel) {
      FuelTypeE5() => station.e5,
      FuelTypeE10() => station.e10,
      FuelTypeE98() => station.e98,
      FuelTypeDiesel() => station.diesel,
      FuelTypeDieselPremium() => station.dieselPremium,
      FuelTypeE85() => station.e85,
      FuelTypeLpg() => station.lpg,
      FuelTypeCng() => station.cng,
      FuelTypeElectric() || FuelTypeHydrogen() || FuelTypeAll() => null,
    };
  }

  /// Best-effort parse of [Station.updatedAt] (ISO-8601 string) into a
  /// [DateTime]. Returns `null` when the field is absent or malformed
  /// — the [RefuelPrice.lastUpdated] field accepts null and the UI
  /// falls back to the surrounding `ServiceResult.fetchedAt`.
  DateTime? get _lastUpdated {
    final raw = station.updatedAt;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
