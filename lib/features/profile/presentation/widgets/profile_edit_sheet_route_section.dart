// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'profile_edit_sheet.dart';

// #3884 — move-only part split (file-length cap): the Route planning card
// of the profile edit sheet, extracted verbatim from
// profile_edit_sheet_parts.dart after the criterion + top-N controls
// pushed that file past 400 lines. Behaviour preserved.

/// Route-planning preferences — route-segment spacing, the maximum
/// detour budget (#1602) and the minimum-saving filter (#1872). The
/// whole section is gated on `Feature.routePlanning` by the caller, so
/// it is only built when the "along the route" search mode is
/// reachable.
class _RouteSegmentSection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _RouteSegmentSection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${l10n.routeSegment}:'),
            Expanded(
              child: Slider(
                value: state.routeSegmentKm,
                min: 50,
                max: 1000,
                divisions: 19,
                label: '${state.routeSegmentKm.round()} km',
                onChanged: ctrl.setRouteSegmentKm,
              ),
            ),
            Text('${state.routeSegmentKm.round()} km'),
          ],
        ),
        Text(
          l10n.showCheapestEveryNKm(state.routeSegmentKm.round()),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          children: [
            Text('${l10n.routeDetourBudget}:'),
            Expanded(
              child: Slider(
                value: state.routeDetourBudgetKm,
                min: 2,
                max: 25,
                divisions: 23,
                label: '${state.routeDetourBudgetKm.round()} km',
                onChanged: ctrl.setRouteDetourBudgetKm,
              ),
            ),
            Text('${state.routeDetourBudgetKm.round()} km'),
          ],
        ),
        Text(
          l10n.routeDetourBudgetCaption(state.routeDetourBudgetKm.round()),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        _buildMinSavingRow(context, theme, l10n),
        const SizedBox(height: Spacing.md),
        _buildCriterionRow(theme, l10n),
        const SizedBox(height: Spacing.md),
        _buildTopNRow(theme, l10n),
      ],
    );
  }

  /// Station-choice criterion per route sample point (#3884 — surfaces
  /// the previously UI-less `UserProfile.routeSearchCriterion`): keep
  /// the cheapest stations, or the ones nearest to the route.
  Widget _buildCriterionRow(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.routeSearchCriterionLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Spacing.sm),
        SegmentedButton<RouteSearchCriterion>(
          key: const Key('routeSearchCriterionSegmented'),
          selected: {state.routeSearchCriterion},
          segments: [
            ButtonSegment(
              value: RouteSearchCriterion.cheapest,
              label: Text(l10n.routeSearchCriterionCheapest),
            ),
            ButtonSegment(
              value: RouteSearchCriterion.nearest,
              label: Text(l10n.routeSearchCriterionNearest),
            ),
          ],
          onSelectionChanged: (sel) => ctrl.setRouteSearchCriterion(sel.first),
        ),
      ],
    );
  }

  /// Candidates-per-sample-point slider, 3–20 (#3884 — surfaces the
  /// previously UI-less `UserProfile.routeSearchTopNPerSamplePoint`).
  Widget _buildTopNRow(ThemeData theme, AppLocalizations l10n) {
    final n = state.routeSearchTopNPerSamplePoint.clamp(3, 20);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${l10n.routeSearchTopNLabel}:'),
            Expanded(
              child: Slider(
                key: const Key('routeSearchTopNSlider'),
                value: n.toDouble(),
                min: 3,
                max: 20,
                divisions: 17,
                label: '$n',
                onChanged: (v) =>
                    ctrl.setRouteSearchTopNPerSamplePoint(v.round()),
              ),
            ),
            Text('$n'),
          ],
        ),
        Text(
          l10n.routeSearchTopNCaption(n),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Minimum-saving slider (#1872). `0.0` is shown as "Off" — every
  /// station along the route is surfaced; a positive value keeps only
  /// stations priced within that band of the route's cheapest.
  Widget _buildMinSavingRow(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final saving = state.minRouteSavingPerLiter;
    final off = saving <= 0;
    // i18n-ignore: language-neutral currency-per-litre unit mask.
    final amount = '${UnitFormatter.formatDecimal(saving, fractionDigits: 2)} €/L';
    final valueLabel = off ? (l10n.routeMinSavingOff) : amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${l10n.routeMinSaving}:'),
            Expanded(
              child: Slider(
                value: saving,
                max: 0.30,
                divisions: 30,
                label: valueLabel,
                onChanged: ctrl.setMinRouteSavingPerLiter,
              ),
            ),
            Text(valueLabel),
          ],
        ),
        Text(
          off
              ? (l10n.routeMinSavingOffCaption)
              : (l10n.routeMinSavingCaption(amount)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
