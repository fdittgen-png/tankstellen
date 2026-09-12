// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/price_freshness.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/price_freshness_words.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/amenity_summary.dart';

/// The station sheet the map opens OVER itself (#4093, epic #4087).
///
/// Tapping a marker used to push the full detail screen, which answers a
/// different question. The map's question is "where are the good
/// options"; a marker tap asks "what about that one" — and answering it
/// by replacing the map loses the context that made the question worth
/// asking. The user then navigates back and has to find their place
/// again.
///
/// So the answer arrives over the map, at the size of the answer: price,
/// distance, how old the price is, what the forecourt has, and the one
/// action a driver wants from a map. Everything else is still one tap
/// away behind `View station details ›` — the map keeps the shallow
/// answer and the detail screen keeps the deep one, which is the split
/// that was missing.
class StationMapSheet extends ConsumerWidget {
  const StationMapSheet({
    super.key,
    required this.station,
    required this.fuelType,
  });

  final Station station;
  final FuelType fuelType;

  /// Show the sheet over the current route. Returns when it closes.
  static Future<void> show(
    BuildContext context, {
    required Station station,
    required FuelType fuelType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Over the map, not instead of it: the barrier stays translucent so
      // the markers the user was comparing are still visible behind.
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => StationMapSheet(station: station, fuelType: fuelType),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final price = station.priceFor(fuelType);
    final band = priceFreshness(
      station.updatedAt,
      now: ref.watch(appClockProvider).now(),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, 0, Spacing.lg, Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.displayName,
                        style: AppText.title(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (station.place.isNotEmpty) station.place,
                          PriceFormatter.formatDistance(station.dist),
                        ].join(' · '),
                        style: AppText.body(context).copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.md),
                // The number the user tapped the marker for.
                Text(
                  // `formatPrice` already answers the language-neutral
                  // "--" for a station with no price for this fuel, so
                  // there is no literal here to exempt from l10n.
                  PriceFormatter.formatPrice(price),
                  // The display role: the sheet exists for this number.
                  style: AppText.display(context),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            // #4092 — price age in words, kept separate from availability.
            Row(
              children: [
                Icon(
                  band == PriceFreshness.stale
                      ? Icons.history_toggle_off
                      : Icons.schedule,
                  size: 14,
                  color: priceFreshnessColor(band, context),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  priceFreshnessWord(band, l10n),
                  style: AppText.label(context)
                      .copyWith(color: priceFreshnessColor(band, context)),
                ),
              ],
            ),
            if (station.amenities.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              AmenitySummary(amenities: station.amenities, maxNamed: 3),
            ],
            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _navigate(context),
                icon: const Icon(Icons.navigation_outlined),
                label: Text(l10n.navigate),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            // The deep answer, still one tap away.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(
                      StationDetailRoute(station.id).push<void>(context));
                },
                child: Text(l10n.mapSheetViewDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    final uri = Uri.parse(
      'geo:${station.lat},${station.lng}'
      '?q=${station.lat},${station.lng}'
      '(${Uri.encodeComponent(station.displayName)})',
    );
    unawaited(launchUrl(uri));
    if (context.mounted) Navigator.of(context).pop();
  }
}
