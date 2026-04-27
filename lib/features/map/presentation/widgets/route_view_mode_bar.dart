import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'route_view_mode_chip.dart';

/// Top bar for the route map: hosts the "All stations" / "Best stops" mode
/// chips plus the selection-count + open-in-maps shortcut on the trailing
/// edge.
///
/// Extracted from [RouteMapView] so the parent stays under the 300-line
/// per-file budget. Stateless: the parent owns the selected mode and the
/// set of selected station ids and just hands the relevant fragments down.
class RouteViewModeBar extends StatelessWidget {
  final bool allStationsSelected;
  final bool bestStopsSelected;
  final int selectedCount;
  final VoidCallback onTapAllStations;
  final VoidCallback onTapBestStops;
  final VoidCallback onOpenSelectedInMaps;

  const RouteViewModeBar({
    super.key,
    required this.allStationsSelected,
    required this.bestStopsSelected,
    required this.selectedCount,
    required this.onTapAllStations,
    required this.onTapBestStops,
    required this.onOpenSelectedInMaps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          RouteViewModeChip(
            label: l10n?.allStations ?? 'All stations',
            icon: Icons.local_gas_station,
            selected: allStationsSelected,
            onTap: onTapAllStations,
          ),
          const SizedBox(width: 8),
          RouteViewModeChip(
            label: l10n?.bestStops ?? 'Best stops',
            icon: Icons.star,
            selected: bestStopsSelected,
            onTap: onTapBestStops,
          ),
          const Spacer(),
          if (selectedCount > 0) ...[
            Text(
              '$selectedCount',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.navigation,
                  size: 18, color: theme.colorScheme.primary),
              tooltip: l10n?.openInMaps ?? 'Open in Maps',
              onPressed: onOpenSelectedInMaps,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}
