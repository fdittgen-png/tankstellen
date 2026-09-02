// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import 'pick_station_candidates.dart';

/// #3906 — section header of the station picker ("Last station",
/// "Favorites", "Nearby").
class PickStationSectionHeader extends StatelessWidget {
  final String text;

  const PickStationSectionHeader({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// One-line muted hint under a section that has nothing to list.
class PickStationSectionHint extends StatelessWidget {
  final String text;

  const PickStationSectionHint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A pickable station row. The subtitle is the address (and, for the
/// last-station row, the fill-up date); the trailing slot carries the
/// distance when one is known.
class PickStationEntryTile extends StatelessWidget {
  final PickStationEntry entry;
  final VoidCallback onTap;

  /// Leading glyph — a history icon for the last-station row, a pump
  /// otherwise.
  final IconData icon;

  const PickStationEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.icon = Icons.local_gas_station,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lines = <String>[];
    final address = entry.address;
    if (address != null && address.isNotEmpty) lines.add(address);
    final lastAt = entry.lastFillUpDate;
    if (lastAt != null) {
      lines.add(l.pickStationLastFillUpAt(UnitFormatter.formatMediumDate(
        lastAt,
        locale: Localizations.localeOf(context).toString(),
      )));
    }
    final distance = entry.distanceKm;
    return ListTile(
      key: Key('pick_station_tile_${entry.id}'),
      leading: Icon(icon),
      title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: lines.isEmpty
          ? null
          : Text(lines.join('\n'), maxLines: 3, overflow: TextOverflow.ellipsis),
      isThreeLine: lines.length > 1,
      trailing: distance == null
          ? const Icon(Icons.chevron_right)
          : Text(
              UnitFormatter.formatDistance(distance),
              key: Key('pick_station_distance_${entry.id}'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      onTap: onTap,
    );
  }
}
