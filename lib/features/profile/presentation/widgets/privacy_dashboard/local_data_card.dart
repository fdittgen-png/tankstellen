// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../providers/privacy_data_provider.dart';
import '../storage_bar.dart';
import 'privacy_data_row.dart';

/// Card listing every category of data the app keeps on the device.
///
/// #1529 — defaults to hiding rows whose value is "0" / "No" so the
/// dashboard isn't padded with empty rows for users who haven't
/// touched a given category. A "Show all" toggle reveals the full
/// list. The estimated-storage line + non-zero rows always render.
class LocalDataCard extends StatefulWidget {
  final PrivacyDataSnapshot snapshot;

  const LocalDataCard({super.key, required this.snapshot});

  @override
  State<LocalDataCard> createState() => _LocalDataCardState();
}

class _LocalDataCardState extends State<LocalDataCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final s = widget.snapshot;

    // Build the row list once. Each entry knows whether it's zero/no
    // so the show-all toggle can filter without re-instantiating
    // PrivacyDataRow widgets.
    final entries = <_RowEntry>[
      _RowEntry(
        icon: Icons.favorite,
        label: l.favorites,
        value: '${s.favoritesCount}',
        isEmpty: s.favoritesCount == 0,
      ),
      _RowEntry(
        icon: Icons.visibility_off,
        label: l.privacyIgnoredStations,
        value: '${s.ignoredCount}',
        isEmpty: s.ignoredCount == 0,
      ),
      _RowEntry(
        icon: Icons.star,
        label: l.privacyRatings,
        value: '${s.ratingsCount}',
        isEmpty: s.ratingsCount == 0,
      ),
      _RowEntry(
        icon: Icons.notifications,
        label: l.priceAlerts,
        value: '${s.alertsCount}',
        isEmpty: s.alertsCount == 0,
      ),
      _RowEntry(
        icon: Icons.show_chart,
        label: l.privacyPriceHistory,
        value: '${s.priceHistoryStationCount}',
        isEmpty: s.priceHistoryStationCount == 0,
      ),
      _RowEntry(
        icon: Icons.person,
        label: l.privacyProfiles,
        value: '${s.profileCount}',
        isEmpty: s.profileCount == 0,
      ),
      _RowEntry(
        icon: Icons.route,
        label: l.privacyItineraries,
        value: '${s.itineraryCount}',
        isEmpty: s.itineraryCount == 0,
      ),
      _RowEntry(
        icon: Icons.cached,
        label: l.privacyCacheEntries,
        value: '${s.cacheEntryCount}',
        isEmpty: s.cacheEntryCount == 0,
      ),
      _RowEntry(
        icon: Icons.key,
        label: l.privacyApiKey,
        value: s.hasApiKey ? (l.yes) : (l.no),
        isEmpty: !s.hasApiKey,
      ),
      _RowEntry(
        icon: Icons.ev_station,
        label: l.privacyEvApiKey,
        value: s.hasEvApiKey ? (l.yes) : (l.no),
        isEmpty: !s.hasEvApiKey,
      ),
    ];

    final visible = _showAll
        ? entries
        : entries.where((e) => !e.isEmpty).toList(growable: false);
    final hiddenCount = entries.length - visible.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_android,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l.privacyLocalData,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (visible.isEmpty)
              // Pristine install: every row is zero. Surface a single
              // line so the card doesn't collapse to just "Estimated
              // storage: 0 KB" without context.
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l.privacyLocalDataEmpty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final e in visible)
                PrivacyDataRow(icon: e.icon, label: e.label, value: e.value),
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  key: const Key('privacyShowAllRowsToggle'),
                  onPressed: () => setState(() => _showAll = !_showAll),
                  icon: Icon(
                    _showAll ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    _showAll
                        ? (l.privacyHideEmptyRows)
                        : (l.privacyShowEmptyRows(hiddenCount)),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.privacyEstimatedSize,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatBytes(s.estimatedTotalBytes),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single row in the local-data list, paired with its empty-state
/// flag so the card can filter without inspecting widget internals.
class _RowEntry {
  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;

  const _RowEntry({
    required this.icon,
    required this.label,
    required this.value,
    required this.isEmpty,
  });
}
