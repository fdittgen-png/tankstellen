// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/approach_detector.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approach/providers/effective_approach_state_provider.dart';
import '../../../approach/providers/nearest_station_radar_provider.dart';
import '../../../profile/providers/effective_fuel_type_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';

/// "Closest station" radar card pinned to the TOP of the active
/// trip-recording column (#2380).
///
/// Surfaces the nearest / approaching fuel station and its price for
/// the driver's effective fuel type, updating as the driver moves.
/// Two data sources, in priority order:
///
/// 1. **Approach detector** ([effectiveApproachStateProvider]) — once
///    the driver is inside the configured geo-fence the state is
///    [ApproachInRadius] (or [ApproachLeaving] during the exit grace).
///    The card renders that target station + distance, mirroring the
///    huge-price PiP layout in `trip_recording_pip_view.dart`.
/// 2. **Nearest-station fallback** ([nearestStationRadarProvider]) —
///    while still approaching ([ApproachPolling]) the detector carries
///    the live GPS fix; the fallback reuses it to query the search
///    chain for the single nearest station so the card isn't empty
///    before the geo-fence is crossed.
///
/// When neither yields a station ([ApproachIdle] / null, no GPS fix, or
/// nothing in range) the card shows a graceful placeholder rather than
/// collapsing — the driver always sees the section is live.
///
/// Prices route through [PriceFormatter] (no hard-coded currency);
/// station / brand names are data, not localised strings.
class TripRadarCard extends ConsumerWidget {
  const TripRadarCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Guard both watches: under tests / first-run that don't bootstrap
    // the chain these can raise; the card degrades to its placeholder
    // rather than crashing the recording screen.
    ApproachState? approach;
    var fuel = FuelType.e10;
    try {
      approach = ref.watch(effectiveApproachStateProvider);
    } on Object {
      approach = null;
    }
    try {
      fuel = ref.watch(effectiveFuelTypeProvider);
    } on Object {
      fuel = FuelType.e10;
    }

    // 1. Approach-radius hit wins — render the targeted station.
    final Station? inRadiusStation = switch (approach) {
      ApproachInRadius(:final station) => station,
      ApproachLeaving(:final lastStation) => lastStation,
      _ => null,
    };
    final double? distanceMeters =
        approach is ApproachInRadius ? approach.distanceMeters : null;

    if (inRadiusStation != null) {
      return _RadarCard(
        title: l?.tripRadarClosestStation ?? 'Closest station',
        station: inRadiusStation,
        fuel: fuel,
        distanceMeters: distanceMeters,
        live: true,
      );
    }

    // 2. Fallback — nearest station off the live polling GPS.
    final fallback = ref.watch(nearestStationRadarProvider);
    return fallback.when(
      data: (station) {
        if (station == null) {
          return _RadarPlaceholder(
            title: l?.tripRadarClosestStation ?? 'Closest station',
            message: l?.tripRadarNoStationNearby ?? 'No station nearby',
          );
        }
        return _RadarCard(
          title: l?.tripRadarClosestStation ?? 'Closest station',
          station: station,
          fuel: fuel,
          // The search chain ships a great-circle distance in `dist`
          // (km); surface it when present so the row matches the
          // in-radius layout's "… m away" caption.
          distanceMeters: station.dist > 0 ? station.dist * 1000.0 : null,
          live: false,
        );
      },
      loading: () => _RadarPlaceholder(
        title: l?.tripRadarClosestStation ?? 'Closest station',
        message: l?.tripRadarScanning ?? 'Scanning for nearby stations',
      ),
      error: (_, _) => _RadarPlaceholder(
        title: l?.tripRadarClosestStation ?? 'Closest station',
        message: l?.tripRadarNoStationNearby ?? 'No station nearby',
      ),
    );
  }
}

/// Station + price row. Mirrors the PiP approach layout's station/price
/// resolution (`station.priceFor(fuel)` → [PriceFormatter.formatPrice],
/// name fallback to brand) in the trip screen's card idiom.
class _RadarCard extends StatelessWidget {
  final String title;
  final Station station;
  final FuelType fuel;
  final double? distanceMeters;

  /// True when the station comes from an in-radius approach hit (vs the
  /// nearest-station fallback) — drives the leading icon emphasis.
  final bool live;

  const _RadarCard({
    required this.title,
    required this.station,
    required this.fuel,
    required this.distanceMeters,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final price = station.priceFor(fuel);
    final priceText =
        price != null ? PriceFormatter.formatPrice(price) : '--';
    final name =
        station.name.isNotEmpty ? station.name : station.brand;

    final subtitleParts = <String>[
      fuel.displayName,
      if (distanceMeters != null)
        l?.approachStationDistance(distanceMeters!.toStringAsFixed(0)) ??
            '${distanceMeters!.toStringAsFixed(0)} m',
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          live ? Icons.my_location : Icons.local_gas_station,
          size: 28,
          color: live ? theme.colorScheme.primary : null,
        ),
        // Overline carries the localised card title; the prominent line
        // is the (data, not ARB) station name + the fuel/distance row.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.bodySmall),
            Text(
              name.isNotEmpty ? name : title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Text(
          subtitleParts.join(' · '),
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          priceText,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Graceful "scanning" / "no station nearby" placeholder. Keeps the
/// top slot occupied so the section never flickers in and out.
class _RadarPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  const _RadarPlaceholder({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.radar, size: 28),
        title: Text(title, style: theme.textTheme.bodySmall),
        subtitle: Text(message, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}
