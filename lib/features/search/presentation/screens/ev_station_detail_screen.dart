// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/widgets/star_rating.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/presentation/screens/add_charging_log_screen.dart';
import '../../../../core/domain/ev/charging_station.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../providers/ev_charging_service_provider.dart';
import '../../providers/ev_search_provider.dart';
import '../../providers/station_rating_provider.dart';
import '../widgets/ev_station_header_card.dart';
import '../widgets/ev_station_info_cards.dart';

/// Detail screen for an EV charging station.
class EVStationDetailScreen extends ConsumerStatefulWidget {
  final ChargingStation station;

  const EVStationDetailScreen({super.key, required this.station});

  @override
  ConsumerState<EVStationDetailScreen> createState() => _EVStationDetailScreenState();
}

class _EVStationDetailScreenState extends ConsumerState<EVStationDetailScreen> {
  late ChargingStation _station;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Render the station as passed immediately (no spinner regression),
    // then layer on any country-authoritative price/access signal (#2632).
    // The IRVE enricher only fires on FR coordinates and is otherwise a
    // no-op, so this is free off-France. It runs on EVERY open path —
    // map-marker, favorite rehydrate, deep-link — not just the search-list
    // tap (the only seam that was enriched before #2632), so the free /
    // paid badge surfaces wherever the detail screen is opened.
    _station = widget.station;
    unawaited(_enrichOnOpen());
  }

  /// One-shot enrich of the opened station with the country-authoritative
  /// price/access signal (#2632). Best-effort: the enricher never throws,
  /// but we degrade defensively to the passed station on any failure so a
  /// transient IRVE outage can never blank the detail screen.
  Future<void> _enrichOnOpen() async {
    try {
      final enricher = ref.read(evPriceEnricherProvider);
      final enriched = (await enricher.enrich([widget.station])).first;
      if (mounted) setState(() => _station = enriched);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'EVStationDetailScreen: enrich on open',
      }));
    }
  }

  Future<void> _refreshStation() async {
    setState(() => _isRefreshing = true);
    try {
      final service = ref.read(evChargingServiceProvider);
      if (service == null) {
        if (mounted) {
          setState(() => _isRefreshing = false);
        }
        return;
      }
      final result = await service.searchStations(
        lat: _station.lat,
        lng: _station.lng,
        radiusKm: 0.5,
        maxResults: 10,
      );
      final ocmId = _station.id.replaceFirst('ocm-', '');
      final refreshed = result.data.where((s) => s.id == _station.id || s.id == 'ocm-$ocmId').firstOrNull;
      if (refreshed != null && mounted) {
        // Re-apply the same country-authoritative enrich the open path uses
        // (#2632). The raw OCM re-fetch carries null UsageType / no IRVE
        // flag, so a plain `_station = refreshed` here STRIPPED the badge
        // a search-list open had shown. Inside the try/catch, so an IRVE
        // outage degrades to the raw refreshed station rather than blanking.
        final enriched =
            (await ref.read(evPriceEnricherProvider).enrich([refreshed])).first;
        if (!mounted) return;
        setState(() => _station = enriched);
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showSuccess(context, l10n?.evStatusUpdated ?? 'Status updated');
      } else if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showError(context, l10n?.evStationNotFound ?? 'Could not refresh — station not found nearby');
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'EVStationDetailScreen._refreshStation: refresh failed',
      }));
      if (mounted) {
        SnackBarHelper.showError(context, AppLocalizations.of(context)?.refreshFailed ?? 'Refresh failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _navigateToStation() {
    unawaited(NavigationUtils.openInMaps(_station.lat, _station.lng,
        label: _station.name));
  }

  /// Open the add-charging-log form pre-filled with this station
  /// (#582 phase 3). The form itself auto-selects the active vehicle;
  /// we supply the station id + display name so the log attributes
  /// back to the charger the user is standing at.
  Future<void> _logCharging() async {
    final displayName = _station.name.trim().isNotEmpty
        ? _station.name
        : (_station.operator ?? '');
    await Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        builder: (_) => AddChargingLogScreen(
          chargingStationId: _station.id,
          stationName: displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final evColor = FuelColors.forType(FuelType.electric);
    final station = _station;

    final operatorName = station.operator ?? '';
    return PageScaffold(
      title: operatorName.isNotEmpty ? operatorName : station.name,
      bodyPadding: EdgeInsets.zero,
      actions: [
        Consumer(builder: (context, ref, _) {
          final isFav = ref.watch(isFavoriteProvider(station.id));
          return IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_outline,
              color: isFav ? Colors.amber : Colors.white70,
              size: 26,
            ),
            tooltip: isFav ? (l10n?.removeFavorite ?? 'Remove from favorites') : (l10n?.addFavorite ?? 'Add to favorites'),
            onPressed: () async {
              // Await the toggle so the snackbar fires AFTER persistence
              // and the isFavoriteProvider has flipped. Otherwise a quick
              // back-navigation can cancel the in-flight Hive write and
              // leave the favorite half-persisted (#566).
              // Persist the ALREADY-ENRICHED `_station` (not the raw
              // `widget.station`) so a later rehydrate of the favorite keeps
              // the IRVE free/paid signal that initState enriched in (#2632).
              await ref.read(favoritesProvider.notifier).toggle(
                    station.id,
                    rawJson: _station.toJson(),
                  );
              if (!context.mounted) return;
              // Temporary diagnostic: surface live storage counts in the
              // snackbar so a user on an APK without logcat can verify
              // the favorite actually persisted.
              final storage = ref.read(storageRepositoryProvider);
              final evIds = storage.getEvFavoriteIds();
              final savedCount = evIds
                  .where((id) => storage.getEvFavoriteStationData(id) != null)
                  .length;
              final base = isFav
                  ? (l10n?.removedFromFavorites ?? 'Removed from favorites')
                  : (l10n?.addedToFavorites ?? 'Added to favorites');
              SnackBarHelper.show(
                context,
                '$base (EV: ${evIds.length} ids / $savedCount saved)',
                duration: const Duration(seconds: 3),
              );
            },
          );
        }),
        IconButton(
          icon: _isRefreshing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
              : const Icon(Icons.refresh),
          tooltip: l10n?.evRefreshStatus ?? 'Refresh status',
          onPressed: _isRefreshing ? null : _refreshStation,
        ),
        IconButton(
          icon: const Icon(Icons.navigation),
          tooltip: l10n?.navigate ?? 'Navigate',
          onPressed: _navigateToStation,
        ),
      ],
      // #2532 — on medium / expanded screens the single column just stretches
      // the portrait layout, wasting the width. The two-pane Row puts the
      // header + address on the LEFT and the connectors / pricing / rating /
      // actions on the RIGHT, each pane self-scrolling. Compact is unchanged.
      body: screenSizeOf(context) != ScreenSize.compact
          ? _wideBody(context, theme, l10n, station, evColor)
          : _compactBody(context, theme, l10n, station, evColor),
    );
  }

  /// The portrait single-column body — byte-for-byte the pre-#2532 layout.
  Widget _compactBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    ChargingStation station,
    Color evColor,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom + 24),
      children: [
        ..._headerSections(station, evColor),
        const SizedBox(height: 8),
        ..._detailSections(context, theme, l10n, station, evColor),
      ],
    );
  }

  /// The medium / expanded two-pane body (#2532). LEFT (flex 2) = the header
  /// + address cards; RIGHT (flex 3) = connectors, pricing, last-updated,
  /// rating and the log / navigate actions. The SAME section widgets are
  /// reused — only the container changes (mirrors the #2531 fuel pattern).
  Widget _wideBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    ChargingStation station,
    Color evColor,
  ) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
            children: _headerSections(station, evColor),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: ListView(
            padding:
                EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 24),
            children: _detailSections(context, theme, l10n, station, evColor),
          ),
        ),
      ],
    );
  }

  /// LEFT-pane sections — the station header + address. Shared by both
  /// layouts.
  List<Widget> _headerSections(ChargingStation station, Color evColor) {
    return [
      EVStationHeaderCard(station: station, evColor: evColor),
      const SizedBox(height: 8),
      EVAddressCard(station: station),
    ];
  }

  /// RIGHT-pane sections — connectors, pricing, last-updated, the rating
  /// card and the log / navigate action buttons. Shared by both layouts.
  List<Widget> _detailSections(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    ChargingStation station,
    Color evColor,
  ) {
    return [
      EVConnectorsCard(station: station, evColor: evColor),
      const SizedBox(height: 8),
      EVPricingCard(station: station, evColor: evColor),
      const SizedBox(height: 8),
      EVLastUpdatedCard(station: station),
      const SizedBox(height: 8),

      // Rating
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.yourRating ?? 'Your rating',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Consumer(builder: (context, ref, _) {
                final rating = ref.watch(stationRatingProvider(station.id));
                return Row(
                  children: [
                    StarRating(
                      rating: rating,
                      onRatingChanged: (stars) {
                        unawaited(ref
                            .read(stationRatingsProvider.notifier)
                            .rate(station.id, stars));
                      },
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 12),
                      Text('$rating/5', style: theme.textTheme.bodyMedium),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Log-charging button — primary wheel-lens action (#582 phase 3).
      FilledButton.icon(
        key: const Key('ev_log_charging_button'),
        onPressed: _logCharging,
        icon: const Icon(Icons.ev_station),
        label: Text(l10n?.chargingLogButtonLabel ?? 'Log charging'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: evColor,
        ),
      ),
      const SizedBox(height: 8),

      // Navigate button
      FilledButton.icon(
        onPressed: _navigateToStation,
        icon: const Icon(Icons.navigation),
        label: Text(l10n?.evNavigateToStation ?? 'Navigate to station'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: evColor.withValues(alpha: 0.85),
        ),
      ),
    ];
  }
}
