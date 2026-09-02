// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_config.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/brand_registry.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/utils/station_extensions.dart';
import 'price_tile.dart';

/// "Prices" header + per-fuel [PriceTile] rows + "Log fill-up" CTA.
///
/// Extracted from [StationDetailScreen] so the screen stays under the
/// 300-LOC cap (#563). Same fuel ordering, same localisation lookups.
///
/// #923 phase 3f — the raw `Text(…, titleMedium)` + plain Column
/// wrapper is replaced by the canonical [SectionCard] so the Prices
/// block shares the design-system surface tint, radius, padding, and
/// header role (`SectionHeader`) with every other section on the
/// station-detail screen.
///
/// #3902 — a fuel the station does not sell used to render as a grey
/// `"Super E5  --"` row, which reads like a missing price rather than a
/// missing pump. Unpriced fuels are hidden from the list; the base fuels
/// among them (the ones every station is EXPECTED to carry) are named once
/// in a muted "Not sold here: …" footnote so the absence is explicit. The
/// optional fuels (98 / E85 / LPG / CNG) were never listed when absent and
/// still are not — listing them as "not sold" on every forecourt would be
/// noise.
class StationPricesSection extends StatelessWidget {
  final Station station;

  const StationPricesSection({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // #2717 — Mexican (mx-) stations show PEMEX grade names (Magna for the
    // e5-family regular, Premium for the e98-family). Every other country
    // keeps its existing European "Super E5"/"Super 98" labels untouched.
    final cc = Countries.countryCodeForStationId(station.id);
    final isMx = cc == 'MX';

    final rows = <_FuelRow>[
      _FuelRow(
        label: isMx
            ? fuelDisplayLabel(FuelType.e5, countryCode: cc)
            : 'Super E5', // i18n-ignore: language-neutral fuel code
        price: station.e5,
        fuelType: FuelType.e5,
        expected: true,
      ),
      _FuelRow(
        label: 'Super E10',
        price: station.e10,
        fuelType: FuelType.e10,
        expected: true,
      ),
      _FuelRow(
        label: 'Diesel',
        price: station.diesel,
        fuelType: FuelType.diesel,
        expected: true,
      ),
      _FuelRow(
        label: isMx
            ? fuelDisplayLabel(FuelType.e98, countryCode: cc)
            : 'Super 98', // i18n-ignore: language-neutral fuel code
        price: station.e98,
        fuelType: FuelType.e98,
      ),
      _FuelRow(label: 'E85', price: station.e85, fuelType: FuelType.e85),
      _FuelRow(label: 'LPG', price: station.lpg, fuelType: FuelType.lpg),
      _FuelRow(label: 'CNG', price: station.cng, fuelType: FuelType.cng),
    ];
    final notSold = [
      for (final r in rows)
        if (r.expected && r.price == null) r.label,
    ];

    return SectionCard(
      title: l10n.prices,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in rows)
            if (r.price != null)
              PriceTile(label: r.label, price: r.price, fuelType: r.fuelType),
          if (notSold.isNotEmpty)
            _NotSoldHereLine(fuels: notSold.join(', ')),
          const SizedBox(height: 12),
          LogFillUpButton(station: station),
        ],
      ),
    );
  }
}

/// One candidate price row; [expected] marks the base fuels whose absence is
/// worth naming in the "Not sold here" footnote.
class _FuelRow {
  final String label;
  final double? price;
  final FuelType fuelType;
  final bool expected;

  const _FuelRow({
    required this.label,
    required this.price,
    required this.fuelType,
    this.expected = false,
  });
}

/// The muted single-line "Not sold here: Super E5" footnote (#3902).
class _NotSoldHereLine extends StatelessWidget {
  final String fuels;

  const _NotSoldHereLine({required this.fuels});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      key: const ValueKey('prices-not-sold-here'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.remove_circle_outline, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).pricesNotSoldHere(fuels),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
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
    final pricedFuel =
        preferredFuel != null && station.priceFor(preferredFuel) != null
        ? preferredFuel
        : _firstAvailableFuel(station);
    final pricePerLiter = pricedFuel != null
        ? station.priceFor(pricedFuel)
        : null;
    final stationName =
        station.brand.isNotEmpty &&
            station.brand != 'Station' &&
            station.brand != BrandRegistry.independentLabel
        ? station.brand
        : station.street;

    return OutlinedButton.icon(
      onPressed: () {
        // #3135 — the pre-fill crosses as a typed AddFillUpRoute instead
        // of a stringly-keyed Map.
        unawaited(AddFillUpRoute(
          stationId: station.id,
          stationName: stationName,
          fuelType: pricedFuel,
          pricePerLiter: pricePerLiter,
        ).push<void>(context));
      },
      icon: const Icon(Icons.local_gas_station_outlined),
      label: Text(AppLocalizations.of(context).addFillUp),
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
