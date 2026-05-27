// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Shows the user's known position and allows updating it.
///
/// #2111 — when [routeMode] is true the bar swaps its label to a
/// route-context message so the user reads the results screen as a
/// trajet view, not a point + radius. The position-update affordance
/// is suppressed in route mode because the user's GPS is not the
/// search anchor — the route corridor is.
class UserPositionBar extends ConsumerWidget {
  final VoidCallback onUpdatePosition;

  /// #2111 — flip the bar's content to a route-mode indicator.
  /// Defaults to false so every existing call site behaves identically.
  final bool routeMode;

  const UserPositionBar({
    super.key,
    required this.onUpdatePosition,
    this.routeMode = false,
  });

  String _formatAge(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return '< 1 min';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPos = ref.watch(userPositionProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final posLabel = l10n?.yourPosition ?? 'Your position';
    final unknownLabel = l10n?.positionUnknown ?? 'Position unknown';
    final distFromSearchLabel =
        l10n?.distancesFromCenter ?? 'Distances from search center';

    // #2111 — in route mode, replace the position readout with a
    // route-mode label so the user understands the results are
    // along a corridor, not nearby a point. The route summary chip
    // (km · min · station-count) lives separately in the results
    // header — this bar just sets context.
    if (routeMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        child: Row(
          children: [
            Icon(Icons.route,
                size: 16, color: theme.colorScheme.tertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n?.routeModeBannerLabel ??
                    'Route mode — distances are along the corridor',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (userPos != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Row(
          children: [
            Icon(Icons.my_location,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$posLabel: ${userPos.source} (${_formatAge(userPos.updatedAt)})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: onUpdatePosition,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Icon(Icons.refresh,
                    size: 18, color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(Icons.location_off,
              size: 16, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$unknownLabel \u2014 $distFromSearchLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: onUpdatePosition,
            icon: Icon(Icons.my_location,
                size: 14, color: theme.colorScheme.primary),
            label: Text('GPS',
                style:
                    TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
