// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/usual_station_store.dart';
import '../../domain/opportunity.dart';
import '../../providers/opportunity_watch_provider.dart';
import '../../providers/usual_station_provider.dart';
import '../../../../core/widgets/section_card.dart';
import '../opportunity_kind_text.dart';

/// "What to watch for" (#4154) — which kinds of finding may interrupt.
///
/// Rendered by Settings → Prices & alerts, not by the Opportunities
/// screen. Inlining it there was tried and reverted: a permanently
/// visible seven-switch block above the station and zone lists pushed
/// them out of the viewport entirely (ten tests could no longer find the
/// zone section at all), which is the same burial `alerts_body.dart`
/// already guards against by rendering the feed only when it has rows.
/// Configuration belongs where the app keeps configuration.
///
/// The switches decide INTERRUPTION, never discovery: every finding
/// still reaches the feed, and `OpportunityBudget` refuses an unwatched
/// kind with [BudgetRefusal.notWatched] while still recording it. That is
/// the #4149 rule — a migration that loses somebody's alerts is worse
/// than the model it replaced — so an unwatched kind goes quiet, not
/// missing.
class OpportunityWatchSection extends ConsumerWidget {
  const OpportunityWatchSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final watched = ref.watch(opportunityWatchProvider);
    final usual = ref.watch(usualStationSettingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.lg, 0, Spacing.lg, Spacing.sm),
          child: Text(
            l10n.opportunitiesWatchHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            for (final kind in OpportunityKind.values)
                SwitchListTile(
                  key: Key('opportunityWatch_${kind.name}'),
                  dense: true,
                  title: Text(opportunityKindText(l10n, kind)),
                  value: watched.contains(kind),
                  onChanged: (on) => ref
                      .read(opportunityWatchProvider.notifier)
                      .setWatched(kind, watched: on),
                ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, 0),
          child: Text(
            l10n.usualStationTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SectionCard(
          padding: EdgeInsets.zero,
          child: _usualStationRow(context, ref, l10n, usual),
        ),
      ],
    );
  }

  /// Three states, and the middle one is the point: a suggestion is
  /// OFFERED with its evidence ("station — 5 fill-ups") and applies only
  /// when the user confirms it.
  Widget _usualStationRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    UsualStation? usual,
  ) {
    if (usual != null) {
      return ListTile(
        key: const Key('usualStationRow'),
        dense: true,
        leading: const Icon(Icons.local_gas_station),
        title: Text(usual.stationName ?? usual.stationId),
        trailing: TextButton(
          key: const Key('usualStationClear'),
          onPressed: () =>
              ref.read(usualStationSettingProvider.notifier).clear(),
          child: Text(l10n.usualStationClear),
        ),
      );
    }

    final suggestion = ref.watch(usualStationSuggestionProvider);
    if (suggestion == null) {
      return ListTile(
        key: const Key('usualStationRow'),
        dense: true,
        leading: const Icon(Icons.local_gas_station_outlined),
        title: Text(l10n.usualStationNone),
      );
    }
    return ListTile(
      key: const Key('usualStationRow'),
      dense: true,
      leading: const Icon(Icons.local_gas_station_outlined),
      title: Text(l10n.usualStationCandidate(
        suggestion.fills,
        suggestion.stationName ?? suggestion.stationId,
      )),
      trailing: TextButton(
        key: const Key('usualStationConfirm'),
        onPressed: () => ref
            .read(usualStationSettingProvider.notifier)
            .confirm(suggestion),
        child: Text(l10n.usualStationConfirm),
      ),
    );
  }
}
