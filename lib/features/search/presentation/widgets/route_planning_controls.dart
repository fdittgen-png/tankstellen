// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../route_search/providers/route_search_params_provider.dart';

/// Route-planning controls for the criteria screen in route mode (#2592).
///
/// The radius is meaningless along a route — instead the criteria screen
/// surfaces the three params that actually drive route planning: the
/// route-segment spacing, the maximum detour budget (#1602) and the
/// minimum-saving floor (#1872). The sliders are copied in structure from
/// the profile-edit sheet's `_RouteSegmentSection`, but they read/write the
/// per-search override notifiers (defaulted from the profile) rather than the
/// local profile-edit state, so the criteria screen can tweak a single
/// search without mutating the saved profile.
class RoutePlanningControls extends ConsumerWidget {
  const RoutePlanningControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final segment = ref.watch(routeSegmentSearchParamProvider);
    final detour = ref.watch(routeDetourSearchParamProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${l10n?.routeSegment ?? "Route segment"}:'),
            Expanded(
              child: Slider(
                value: segment,
                min: 50,
                max: 1000,
                divisions: 19,
                label: '${segment.round()} km',
                onChanged: (v) =>
                    ref.read(routeSegmentSearchParamProvider.notifier).set(v),
              ),
            ),
            Text('${segment.round()} km'),
          ],
        ),
        Text(
          l10n?.showCheapestEveryNKm(segment.round()) ??
              'Show cheapest station every ${segment.round()} km along route',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          children: [
            Text('${l10n?.routeDetourBudget ?? "Maximum detour"}:'),
            Expanded(
              child: Slider(
                value: detour,
                min: 2,
                max: 25,
                divisions: 23,
                label: '${detour.round()} km',
                onChanged: (v) =>
                    ref.read(routeDetourSearchParamProvider.notifier).set(v),
              ),
            ),
            Text('${detour.round()} km'),
          ],
        ),
        Text(
          l10n?.routeDetourBudgetCaption(detour.round()) ??
              'Surface stations up to ${detour.round()} '
                  'km off your direct route',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        _buildMinSavingRow(context, ref, theme, l10n),
      ],
    );
  }

  /// Minimum-saving slider (#1872). `0.0` is shown as "Off" — every station
  /// along the route is surfaced; a positive value keeps only stations
  /// priced within that band of the route's cheapest.
  Widget _buildMinSavingRow(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    final saving = ref.watch(minRouteSavingSearchParamProvider);
    final off = saving <= 0;
    // i18n-ignore: language-neutral currency-per-litre unit mask.
    final amount = '${saving.toStringAsFixed(2)} €/L';
    final valueLabel = off ? (l10n?.routeMinSavingOff ?? 'Off') : amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${l10n?.routeMinSaving ?? "Minimum saving"}:'),
            Expanded(
              child: Slider(
                value: saving,
                max: 0.30,
                divisions: 30,
                label: valueLabel,
                onChanged: (v) => ref
                    .read(minRouteSavingSearchParamProvider.notifier)
                    .set(v),
              ),
            ),
            Text(valueLabel),
          ],
        ),
        Text(
          off
              ? (l10n?.routeMinSavingOffCaption ??
                  'Showing every station found along the route')
              : (l10n?.routeMinSavingCaption(amount) ??
                  "Only stations within $amount of the route's cheapest"),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
