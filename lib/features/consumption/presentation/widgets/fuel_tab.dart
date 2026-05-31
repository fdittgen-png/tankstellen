// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/responsive_search_layout.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../achievements/presentation/widgets/badge_shelf.dart';
import '../../../profile/providers/gamification_enabled_provider.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/entities/consumption_stats.dart';
import '../../domain/entities/fill_up.dart';
import '../../providers/consumption_providers.dart';
import 'consumption_stats_card.dart';
import 'edit_correction_fill_up_sheet.dart';
import 'fill_up_card.dart';
import 'tank_level_card.dart';

/// Body of the Fuel tab on the Consumption screen.
///
/// Renders the existing fill-up list, the per-period stats card and
/// the help banner. Identical shape to the pre-extraction inline body
/// so the widget/export tests pass with zero assertion churn.
class FuelTab extends ConsumerWidget {
  final List<FillUp> fillUps;
  final ConsumptionStats stats;
  final AppLocalizations? l;

  const FuelTab({
    super.key,
    required this.fillUps,
    required this.stats,
    required this.l,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fillUps.isEmpty) {
      return EmptyState(
        icon: Icons.local_gas_station_outlined,
        title: l?.noFillUpsTitle ?? 'No fill-ups yet',
        subtitle: l?.noFillUpsSubtitle ??
            'Log your first fill-up to start tracking consumption.',
        topBiased: true,
      );
    }
    final showGamification = ref.watch(gamificationEnabledProvider);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    // #2494 — clears the floating add-fill-up FAB hosted by PageScaffold.
    // The Scaffold lifts the FAB clear of the system inset, so we must NOT
    // add `viewPadding.bottom` on top of the shared clearance constant.
    const bottomInset = kFabScrollClearance;

    final headerChildren = <Widget>[
      HelpBanner(
        storageKey: StorageKeys.helpBannerConsumption,
        icon: Icons.tips_and_updates_outlined,
        message: l?.helpBannerConsumption ??
            'Log every fill-up to track your real-world '
                'consumption and CO₂ footprint. Swipe left '
                'to delete an entry.',
      ),
      if (showGamification) const BadgeShelf(),
      const TankLevelCard(),
      ConsumptionStatsCard(
        stats: stats,
        volumetricEfficiency: activeVehicle?.volumetricEfficiency,
        volumetricEfficiencySamples:
            activeVehicle?.volumetricEfficiencySamples,
      ),
    ];

    Widget buildFillUpRow(int index) {
      final fillUp = fillUps[index];
      return Dismissible(
        key: ValueKey(fillUp.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: DarkModeColors.error(context),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) {
          ref.read(fillUpListProvider.notifier).remove(fillUp.id);
        },
        child: FillUpCard(
          fillUp: fillUp,
          ecoScore: ref.watch(ecoScoreForFillUpProvider(fillUp.id)),
          rawLPer100Km:
              ref.watch(litersPer100KmForFillUpProvider(fillUp.id)),
          onTap: fillUp.isCorrection
              ? () => _openCorrectionEditor(context, fillUp)
              : null,
        ),
      );
    }

    // #2018 — landscape / tablet split: left = tank level + stats
    // header, right = fill-ups list. Mirrors the search-results
    // wide-screen pattern via `isWideScreen(context)` (≥ 600dp).
    if (isWideScreen(context)) {
      // 2:3 flex on landscape so the Pleins list (the dense data the
      // user scrolls) gets more width than the mostly-static stats
      // header. Prior 1:1 split wasted half the screen on the sparse
      // left column per the 2026-05-24 screenshots.
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: headerChildren,
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: bottomInset),
              itemCount: fillUps.length,
              itemBuilder: (context, index) => buildFillUpRow(index),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: bottomInset),
      itemCount: fillUps.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: headerChildren,
          );
        }
        return buildFillUpRow(index - 1);
      },
    );
  }

  void _openCorrectionEditor(BuildContext context, FillUp fillUp) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditCorrectionFillUpSheet(fillUp: fillUp),
    );
  }
}
