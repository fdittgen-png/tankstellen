// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/sync/price_history_sync.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../price_history/api.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import 'price_history_stats_row.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/panel_card.dart';
import '../../../price_history/presentation/widgets/fill_up_guidance_card.dart';

/// Price history block of the station-detail screen — records the
/// current price on init, then renders one of THREE honest states
/// (#3928, epic #3925).
///
/// It used to always draw the chart, "even with a single data point":
/// a first visit produced one orange dot floating in an empty plot with
/// `Min 2,329 € · Max 2,329 € · Avg 2,329 € · Actuel 2,329 €` under it,
/// Min in green and Max in red. Every figure was the same number and
/// none of them was a statistic. The states now are:
///
///  * **no observation** — the chart's own empty message, unchanged;
///  * **exactly one** — no chart and no stats row, just when the price
///    was first seen and what it is right now;
///  * **two or more** — chart + [PriceHistoryStatsRow], whose Min/Max
///    only carry colour when they differ and whose current price shows
///    an explicit delta against the oldest point of the window.
class PriceHistorySection extends ConsumerStatefulWidget {
  final String stationId;
  final Station station;

  const PriceHistorySection({
    super.key,
    required this.stationId,
    required this.station,
  });

  @override
  ConsumerState<PriceHistorySection> createState() =>
      _PriceHistorySectionState();
}

class _PriceHistorySectionState extends ConsumerState<PriceHistorySection> {
  bool _recorded = false;

  /// #3990 — "Show all fuel types" used to push a whole second screen that
  /// duplicated this one. It expands here instead.
  bool _showAllFuels = false;
  bool _fetchedFromDb = false;

  @override
  void initState() {
    super.initState();
    unawaited(_recordAndLoad());
  }

  Future<void> _recordAndLoad() async {
    final repo = ref.read(priceHistoryRepositoryProvider);
    final station = widget.station;

    await repo.recordPrice(
      PriceRecord(
        stationId: widget.stationId,
        recordedAt: DateTime.now(),
        e5: station.e5,
        e10: station.e10,
        e98: station.e98,
        diesel: station.diesel,
        e85: station.e85,
        lpg: station.lpg,
        cng: station.cng,
      ),
    );

    // Guard before touching ref after the await — leaving the screen during
    // recordPrice disposes the widget and Riverpod 3's WidgetRef throws
    // StateError if invalidate runs on a dead ref (#2298).
    if (!mounted) return;
    ref.invalidate(priceHistoryProvider(widget.stationId));
    if (mounted) setState(() => _recorded = true);
    await _fetchFromDatabaseIfNeeded();
  }

  Future<void> _fetchFromDatabaseIfNeeded() async {
    if (_fetchedFromDb) return;
    final syncState = ref.read(syncStateProvider);
    if (!syncState.enabled) {
      if (mounted) setState(() => _fetchedFromDb = true);
      return;
    }

    final history = ref.read(priceHistoryProvider(widget.stationId));
    if (history.length >= 3) {
      if (mounted) setState(() => _fetchedFromDb = true);
      return;
    }

    try {
      final rows = await PriceHistorySync.fetch(widget.stationId);
      if (rows.isNotEmpty && mounted) {
        final storageMgmt = ref.read(storageManagementProvider);
        final records = rows
            .map(
              (r) => {
                'stationId': r['station_id'],
                'recordedAt': r['recorded_at'],
                'e5': r['e5'],
                'e10': r['e10'],
                'diesel': r['diesel'],
                'e98': r['e98'],
                'e85': r['e85'],
                'lpg': r['lpg'],
                'cng': r['cng'],
              },
            )
            .toList();
        await storageMgmt.savePriceRecords(widget.stationId, records);
        // #3159 — same #2298 guard as _recordAndLoad: the save above can
        // outlive the widget, and invalidating a dead WidgetRef throws.
        if (mounted) {
          ref.invalidate(priceHistoryProvider(widget.stationId));
        }
      }
    } catch (e, st) {
      logFailure(e, st, where: 'PriceHistory DB fetch failed');
    }
    if (mounted) setState(() => _fetchedFromDb = true);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(priceHistoryProvider(widget.stationId));

    if (!_recorded && history.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final defaultFuel = _pickFuelType(history);
    // Only the records that actually carry the selected fuel can be
    // plotted — two visits where the second dropped the diesel column
    // are ONE point, not two, and must not draw a "trend".
    final plottable = history
        .where((r) => _priceOf(r, defaultFuel) != null)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plottable.length == 1)
          _SinglePoint(record: plottable.first, fuelType: defaultFuel)
        else
          ..._chartAndStats(context, history, plottable, defaultFuel),
        if (_showAllFuels) ..._allFuelPanels(context),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            key: const Key('price_history_toggle_all_fuels'),
            onPressed: () =>
                setState(() => _showAllFuels = !_showAllFuels),
            child: Text(_showAllFuels
                ? AppLocalizations.of(context).showFewerFuelTypes
                : AppLocalizations.of(context).showAllFuelTypes),
          ),
        ),
      ],
    );
  }

  /// The >= 2 points branch (and the empty one, which falls through to
  /// the chart's own "no price history" message).
  List<Widget> _chartAndStats(
    BuildContext context,
    List<PriceRecord> history,
    List<PriceRecord> plottable,
    FuelType fuelType,
  ) {
    final stats = ref.watch(priceStatsProvider(widget.stationId, fuelType));
    // `history` is newest-first, so the LAST plottable record is the
    // oldest point in the window the chart draws — the reference the
    // delta is measured against.
    final oldest = plottable.isEmpty ? null : plottable.last;
    return [
      PriceChart(records: history, fuelType: fuelType),
      const SizedBox(height: 8),
      if (stats.current != null) ...[
        PriceHistoryStatsRow(
          stats: stats,
          windowStartPrice: oldest == null ? null : _priceOf(oldest, fuelType),
          windowStartAt: oldest?.recordedAt,
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  /// Every fuel type this station has ever recorded a price for, each on
  /// its own panel: the chart, the honest stats row and the fill-up
  /// guidance the deleted screen used to carry (#3990).
  ///
  /// The fuels with no data render nothing — [PriceStats] comes back empty
  /// and the panel is skipped, exactly as the old screen's section did.
  List<Widget> _allFuelPanels(BuildContext context) {
    final history = ref.watch(priceHistoryProvider(widget.stationId));
    final panels = <Widget>[];
    for (final fuel in kPriceHistoryFuelTypes) {
      final stats = ref.watch(priceStatsProvider(widget.stationId, fuel));
      if (stats.current == null && stats.min == null) continue;
      final plottable = history
          .where((r) => _priceOf(r, fuel) != null)
          .toList(growable: false);
      final oldest = plottable.isEmpty ? null : plottable.last;
      panels.add(PanelCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fuel.displayName, style: AppText.title(context)),
            const SizedBox(height: 12),
            PriceChart(records: history, fuelType: fuel),
            const SizedBox(height: 8),
            PriceHistoryStatsRow(
              stats: stats,
              windowStartPrice:
                  oldest == null ? null : _priceOf(oldest, fuel),
              windowStartAt: oldest?.recordedAt,
            ),
            const SizedBox(height: 8),
            // On-device "best time to fill up?" heuristic (#1543). Renders
            // nothing when the gate is off or the data is too thin.
            FillUpGuidanceCard(
                stationId: widget.stationId, fuelType: fuel),
          ],
        ),
      ));
    }
    return panels;
  }


  FuelType _pickFuelType(List<PriceRecord> history) {
    if (history.isEmpty) return FuelType.diesel;
    final first = history.first;
    if (first.diesel != null) return FuelType.diesel;
    if (first.e10 != null) return FuelType.e10;
    if (first.e5 != null) return FuelType.e5;
    if (first.e98 != null) return FuelType.e98;
    if (first.e85 != null) return FuelType.e85;
    if (first.lpg != null) return FuelType.lpg;
    if (first.cng != null) return FuelType.cng;
    return FuelType.diesel;
  }
}

/// The one-observation state: no chart, no stats row — a single dot in
/// an empty plot and four identical "statistics" were the #3928 report.
/// It says when the price was first seen and what it is now, nothing it
/// cannot back up.
class _SinglePoint extends StatelessWidget {
  final PriceRecord record;
  final FuelType fuelType;

  const _SinglePoint({required this.record, required this.fuelType});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = UnitFormatter.formatMediumDate(
      record.recordedAt,
      locale: Localizations.localeOf(context).toString(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.priceHistoryFirstSeen(date),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.priceHistoryCurrentPriceLine(
            PriceFormatter.formatPrice(_priceOf(record, fuelType)),
          ),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Price of [fuelType] in [record], or null when that visit carried no
/// figure for it. The price-history feature keeps the same switch
/// private to its repository; station_detail needs it to count the
/// points it is about to draw.
double? _priceOf(PriceRecord record, FuelType fuelType) => switch (fuelType) {
      FuelTypeE5() => record.e5,
      FuelTypeE10() => record.e10,
      FuelTypeE98() => record.e98,
      FuelTypeDiesel() => record.diesel,
      FuelTypeDieselPremium() => record.dieselPremium,
      FuelTypeE85() => record.e85,
      FuelTypeLpg() => record.lpg,
      FuelTypeCng() => record.cng,
      FuelTypeHydrogen() || FuelTypeElectric() || FuelTypeAll() => null,
    };

/// The fuel types the history is broken down by — shared by the section
/// and the foldable's collapsed header (#4076).
const kPriceHistoryFuelTypes = [
    FuelType.e5,
    FuelType.e10,
    FuelType.diesel,
    FuelType.e98,
    FuelType.e85,
    FuelType.lpg,
    FuelType.cng,
  ];

/// #4076 — the foldable's collapsed header: the stats row for the first
/// fuel type with a current price, or nothing (the header stays a plain
/// title when there is no history). Lives here, next to the section that
/// already owns the price-history provider import, so the foldable adds no
/// cross-feature edge (feature_boundary ratchet).
class PriceHistoryCollapsedStats extends ConsumerWidget {
  final String stationId;
  const PriceHistoryCollapsedStats({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    for (final fuel in kPriceHistoryFuelTypes) {
      final stats = ref.watch(priceStatsProvider(stationId, fuel));
      if (stats.current == null) continue;
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: PriceHistoryStatsRow(stats: stats),
      );
    }
    return const SizedBox.shrink();
  }
}
