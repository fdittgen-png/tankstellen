import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/brand_registry.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import '../../../../core/utils/station_extensions.dart';
import 'price_tile.dart';

/// "Prices" header + per-fuel [PriceTile] rows + "Log fill-up" CTA.
///
/// Extracted from [StationDetailScreen] so the screen stays under the
/// 300-LOC cap (#563). Public behaviour is unchanged — same fuel
/// ordering, same optional-tile gating, same localisation lookups.
class StationPricesSection extends StatelessWidget {
  final Station station;

  const StationPricesSection({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n?.prices ?? 'Prices',
              style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 6),
        PriceTile(label: 'Super E5', price: station.e5, fuelType: FuelType.e5),
        PriceTile(label: 'Super E10', price: station.e10, fuelType: FuelType.e10),
        PriceTile(label: 'Diesel', price: station.diesel, fuelType: FuelType.diesel),
        if (station.e98 != null)
          PriceTile(label: 'Super 98', price: station.e98, fuelType: FuelType.e98),
        if (station.e85 != null)
          PriceTile(label: 'E85', price: station.e85, fuelType: FuelType.e85),
        if (station.lpg != null)
          PriceTile(label: 'LPG', price: station.lpg, fuelType: FuelType.lpg),
        if (station.cng != null)
          PriceTile(label: 'CNG', price: station.cng, fuelType: FuelType.cng),
        const SizedBox(height: 12),
        LogFillUpButton(station: station),
      ],
    );
  }
}

/// "Log fill-up here" button. Reads the active profile's preferred fuel
/// type and the station's current price for that fuel, then navigates to
/// `/consumption/add` with both pre-filled so the user only needs to
/// type liters and odometer.
class LogFillUpButton extends ConsumerWidget {
  final Station station;

  const LogFillUpButton({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final preferredFuel = profile?.preferredFuelType;
    // Fall back to any fuel the station reports if the profile fuel isn't
    // available at this station (e.g. diesel-preferring user at a petrol-only
    // bio station).
    final pricedFuel = preferredFuel != null &&
            station.priceFor(preferredFuel) != null
        ? preferredFuel
        : _firstAvailableFuel(station);
    final pricePerLiter =
        pricedFuel != null ? station.priceFor(pricedFuel) : null;
    final stationName = station.brand.isNotEmpty &&
            station.brand != 'Station' &&
            station.brand != BrandRegistry.independentLabel
        ? station.brand
        : station.street;

    return OutlinedButton.icon(
      onPressed: () {
        final extra = <String, Object>{
          'stationId': station.id,
          'stationName': stationName,
        };
        if (pricedFuel != null) extra['fuelType'] = pricedFuel;
        if (pricePerLiter != null) extra['pricePerLiter'] = pricePerLiter;
        context.push('/consumption/add', extra: extra);
      },
      icon: const Icon(Icons.local_gas_station_outlined),
      label: Text(
        AppLocalizations.of(context)?.addFillUp ?? 'Log fill-up here',
      ),
    );
  }

  /// Returns the first fuel type for which this station has a price, in a
  /// predictable priority order. Used when the profile fuel isn't available
  /// at the station, so the button can still pre-fill a reasonable default.
  static FuelType? _firstAvailableFuel(Station s) {
    const order = [
      FuelType.e10,
      FuelType.e5,
      FuelType.diesel,
      FuelType.e98,
      FuelType.e85,
      FuelType.lpg,
      FuelType.cng,
    ];
    for (final f in order) {
      if (s.priceFor(f) != null) return f;
    }
    return null;
  }
}
