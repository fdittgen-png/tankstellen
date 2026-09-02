// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
// The profile barrel, not its internals: #3132's feature-boundary gate
// counts every non-`api.dart` cross-feature import.
import '../../../profile/api.dart';
import '../../../route_search/providers/route_search_params_provider.dart';
import '../../../../core/utils/unit_formatter.dart';
import 'criteria/criteria_option_row.dart';

/// Route-planning controls for the criteria screen in route mode (#2592).
///
/// The radius is meaningless along a route — instead the criteria screen
/// surfaces the three params that actually drive route planning: the
/// route-segment spacing, the maximum detour budget (#1602) and the
/// minimum-saving floor (#1872). They read/write the per-search override
/// notifiers (defaulted from the profile) rather than the local
/// profile-edit state, so the criteria screen can tweak a single search
/// without mutating the saved profile.
///
/// #3927 — the three controls used to be `Row(label, Expanded(Slider),
/// value)` triples whose tracks each started at a different x, stacked
/// open above the fold. They are now aligned [CriteriaOptionRow]s inside a
/// collapsible "Route options" section that carries a one-line summary and
/// opens only when something differs from the defaults. The minimum saving
/// became preset chips: a slider with an off end was the only control on
/// the sheet whose zero meant "no filter".
class RoutePlanningControls extends ConsumerWidget {
  const RoutePlanningControls({super.key});

  /// Factory defaults, mirrored from `RouteSearchParams`' fallbacks — used
  /// to decide whether the section opens pre-expanded when no profile is
  /// active.
  static const double defaultSegmentKm = 50;
  static const double defaultDetourKm = 5;
  static const double defaultMinSaving = 0;

  /// The minimum-saving values offered as chips (€/L). `0` is "off".
  static const List<double> minSavingPresets = [0, 0.05, 0.10, 0.20];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final segment = ref.watch(routeSegmentSearchParamProvider);
    final detour = ref.watch(routeDetourSearchParamProvider);
    final saving = ref.watch(minRouteSavingSearchParamProvider);
    final profile = ref.watch(activeProfileProvider);

    final savingLabel = _savingLabel(l10n, saving);
    final touched =
        segment != (profile?.routeSegmentKm ?? defaultSegmentKm) ||
        detour != (profile?.routeDetourBudgetKm ?? defaultDetourKm) ||
        saving != (profile?.minRouteSavingPerLiter ?? defaultMinSaving);

    return ExpansionTile(
      key: const ValueKey('criteria-route-options'),
      initiallyExpanded: touched,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(l10n.criteriaRouteOptions, style: theme.textTheme.titleSmall),
      subtitle: Text(
        l10n.criteriaRouteOptionsSummary(
          segment.round(),
          detour.round(),
          savingLabel,
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        CriteriaOptionRow(
          label: l10n.routeSegment,
          value: '${segment.round()} km',
          caption: l10n.showCheapestEveryNKm(segment.round()),
          child: CriteriaOptionSlider(
            value: segment,
            min: 50,
            max: 1000,
            divisions: 19,
            label: '${segment.round()} km',
            onChanged: (v) =>
                ref.read(routeSegmentSearchParamProvider.notifier).set(v),
          ),
        ),
        CriteriaOptionRow(
          label: l10n.routeDetourBudget,
          value: '${detour.round()} km',
          caption: l10n.routeDetourBudgetCaption(detour.round()),
          child: CriteriaOptionSlider(
            value: detour,
            min: 2,
            max: 25,
            divisions: 23,
            label: '${detour.round()} km',
            onChanged: (v) =>
                ref.read(routeDetourSearchParamProvider.notifier).set(v),
          ),
        ),
        _MinSavingRow(saving: saving, savingLabel: savingLabel),
      ],
    );
  }

  /// `0` reads as "Off" — every station along the route is surfaced; a
  /// positive value is shown as its amount per litre.
  static String _savingLabel(AppLocalizations l10n, double saving) =>
      saving <= 0 ? l10n.routeMinSavingOff : _amount(saving);

  // i18n-ignore: language-neutral currency-per-litre unit mask.
  static String _amount(double saving) =>
      '${UnitFormatter.formatDecimal(saving, fractionDigits: 2)} €/L';
}

/// Minimum-saving row (#1872): preset chips instead of a slider whose
/// zero end silently meant "no filter". The chips write the SAME
/// `minRouteSavingSearchParamProvider` value the slider wrote (€/L, `0`
/// = off), so the filter semantics downstream are untouched. A value that
/// is not one of the presets (an older profile default) gets its own chip
/// so it is never silently dropped.
class _MinSavingRow extends ConsumerWidget {
  const _MinSavingRow({required this.saving, required this.savingLabel});

  final double saving;
  final String savingLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final values = <double>[
      ...RoutePlanningControls.minSavingPresets,
      if (!RoutePlanningControls.minSavingPresets.contains(saving)) saving,
    ]..sort();

    return CriteriaOptionRow(
      label: l10n.routeMinSaving,
      value: savingLabel,
      caption: saving <= 0
          ? l10n.routeMinSavingOffCaption
          : l10n.routeMinSavingCaption(RoutePlanningControls._amount(saving)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final value in values)
              ChoiceChip(
                key: ValueKey(
                  'criteria-min-saving-${(value * 100).round()}',
                ),
                label: Text(
                  RoutePlanningControls._savingLabel(l10n, value),
                ),
                selected: saving == value,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => ref
                    .read(minRouteSavingSearchParamProvider.notifier)
                    .set(value),
              ),
          ],
        ),
      ),
    );
  }
}
