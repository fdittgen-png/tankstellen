// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station.dart';
import '../../domain/entities/price_alert.dart';
import '../../providers/alert_provider.dart';
import 'create_alert_dialog.dart';

/// Bottom sheet that lets the user pick one of their favorite stations to
/// attach a price alert to (#2857).
///
/// Before this, the Station-alerts "+" on the redesigned alerts screen was a
/// dead-end: it only re-showed the "create from a station's detail page" hint.
/// Station alerts are created via [CreateAlertDialog], which needs a station —
/// previously only reachable from the station-detail app bar. This picker
/// reuses the same favorites-backed list as the consumption fill-up picker
/// ([PickStationForFillUpScreen]) and the existing `pickStation*` strings, but
/// — unlike that screen, which `pushReplacement`s into the fill-up form —
/// RETURNS the chosen [Station] via `Navigator.pop`, so the caller can hand it
/// straight to [CreateAlertDialog].
///
/// When the user has no favorites yet, the sheet shows the empty hint plus a
/// "Search" CTA that closes the sheet and navigates to the Search tab — the
/// sanctioned fallback so the user can reach a station's detail page (where
/// the create-alert action also lives).
class AlertStationPickerSheet extends ConsumerWidget {
  const AlertStationPickerSheet({super.key});

  /// Opens the picker and resolves to the selected [Station], or `null` if
  /// the user dismissed the sheet (or tapped the Search fallback, which
  /// pops + navigates away).
  static Future<Station?> show(BuildContext context) {
    return showModalBottomSheet<Station>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AlertStationPickerSheet(),
    );
  }

  /// The full Station-alert add flow (#2857): pick a favorite station, run the
  /// same [CreateAlertDialog] the station-detail app bar uses, and persist the
  /// result via [AlertNotifier.addAlert]. Mirrors
  /// `StationDetailAppBarActions._showCreateAlertDialog` so an alert created
  /// from the alerts screen is byte-identical to one created from detail.
  static Future<void> addStationAlert(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final station = await show(context);
    if (station == null || !context.mounted) return;

    final alert = await showDialog<PriceAlert>(
      context: context,
      builder: (_) => CreateAlertDialog(
        stationId: station.id,
        stationName: _stationLabel(station),
        currentPrice: station.diesel ?? station.e10 ?? station.e5,
      ),
    );
    if (alert == null || !context.mounted) return;

    await ref.read(alertProvider.notifier).addAlert(alert);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(context, l10n.alertCreated);
  }

  /// Brand → name → street fallback for the dialog title (#2161): French
  /// `prix-carburants` stations often carry no brand but a populated name.
  static String _stationLabel(Station s) {
    if (s.brand.isNotEmpty && s.brand != 'Station') return s.brand;
    final name = s.name.trim();
    if (name.isNotEmpty) return name;
    return s.street.isNotEmpty ? s.street : s.id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final storage = ref.watch(storageRepositoryProvider);

    final stations = <Station>[];
    for (final id in storage.getFavoriteIds()) {
      final raw = storage.getFavoriteStationData(id);
      if (raw == null) continue;
      try {
        stations.add(Station.fromJson(raw));
      } catch (e, st) {
        unawaited(
          errorLogger.log(
            ErrorLayer.ui,
            e,
            st,
            context: {
              'where': 'AlertStationPicker: skipping malformed fav $id',
            },
          ),
        );
      }
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.pickStationTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.pickStationHelper,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (stations.isEmpty)
            _PickerEmptyState(
              message: l10n.pickStationEmpty,
              searchLabel: l10n.search,
              onSearch: () {
                Navigator.of(context).pop();
                context.go(RoutePaths.search);
              },
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: stations.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final station = stations[index];
                  final title = station.brand.isNotEmpty
                      ? station.brand
                      : station.name;
                  final parts = <String>[];
                  if (station.street.isNotEmpty) parts.add(station.street);
                  if (station.place.isNotEmpty) parts.add(station.place);
                  return ListTile(
                    key: Key('alert_pick_station_tile_${station.id}'),
                    leading: const Icon(Icons.local_gas_station),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      parts.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(station),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Empty state shown inside the picker when the user has no favorites yet —
/// surfaces the hint plus a CTA that jumps to Search so they can reach a
/// station's detail page (the other create-alert entry point).
class _PickerEmptyState extends StatelessWidget {
  const _PickerEmptyState({
    required this.message,
    required this.searchLabel,
    required this.onSearch,
  });

  final String message;
  final String searchLabel;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_border,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            key: const Key('alert_pick_station_search'),
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: Text(searchLabel),
          ),
        ],
      ),
    );
  }
}
