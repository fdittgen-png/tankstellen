import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../achievements/presentation/widgets/badge_shelf.dart';
import '../../domain/entities/consumption_stats.dart';
import '../../domain/entities/fill_up.dart';
import '../../providers/consumption_providers.dart';
import 'consumption_stats_card.dart';
import 'fill_up_card.dart';

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
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 96 + MediaQuery.of(context).viewPadding.bottom,
      ),
      itemCount: fillUps.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HelpBanner(
                storageKey: StorageKeys.helpBannerConsumption,
                icon: Icons.tips_and_updates_outlined,
                message: l?.helpBannerConsumption ??
                    'Log every fill-up to track your real-world '
                        'consumption and CO₂ footprint. Swipe left '
                        'to delete an entry.',
              ),
              const BadgeShelf(),
              ConsumptionStatsCard(stats: stats),
            ],
          );
        }
        final fillUp = fillUps[index - 1];
        return Dismissible(
          key: ValueKey(fillUp.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(fillUpListProvider.notifier).remove(fillUp.id);
          },
          child: FillUpCard(
            fillUp: fillUp,
            ecoScore: ref.watch(ecoScoreForFillUpProvider(fillUp.id)),
          ),
        );
      },
    );
  }
}
