// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/fleet_kpis.dart';
import '../../providers/fleet_manager_providers.dart';
import '../widgets/fleet_figure.dart';
import '../widgets/fleet_kpi_tile.dart';

/// One company vehicle's period figures (#4216).
///
/// **There are no journey traces on this page, and that is the
/// design.** #4216 puts them outside the default detail view and ADR
/// 0025 D5.1 removes the possibility entirely: there is no manager
/// read policy on `trip_summaries`, `trip_details` or
/// `obd2_baselines`, so this screen could not draw a route if it
/// wanted to. The notice at the bottom says so out loud, because a
/// manager who cannot find the map should learn that it does not
/// exist rather than assume it is broken.
///
/// A one-employee fleet reaches this page like any other — and gets
/// the same suppressed row the overview showed, because the threshold
/// is applied on the server, not by the screen that renders it.
class FleetVehicleDetailScreen extends ConsumerWidget {
  const FleetVehicleDetailScreen({super.key, required this.fleetVehicleId});

  /// The company asset. The payload is an id, not a record, so a
  /// correction made elsewhere cannot be rendered stale here.
  final String fleetVehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final row = ref.watch(fleetVehicleRowByIdProvider(fleetVehicleId));
    final metrics = ref.watch(fleetVehicleMetricsByIdProvider(fleetVehicleId));
    final name = row?.displayName ??
        (fleetVehicleId.isEmpty
            ? l.fleetManagerVehicleTitle
            : l.fleetManagerVehicleUnnamed(fleetVehicleId));
    return PageScaffold(
      title: name,
      bodyPadding: EdgeInsets.zero,
      body: metrics == null
          ? EmptyState(
              icon: Icons.inbox_outlined,
              title: l.fleetManagerVehicleNotInPeriod,
              subtitle: l.fleetManagerNoJourneys,
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                shellScrollClearance(context),
              ),
              children: [
                if (metrics.suppressed)
                  _SuppressedCard(threshold:
                      ref.watch(fleetAggregationMinSamplesProvider))
                else
                  _Figures(metrics: metrics),
                const SizedBox(height: Spacing.lg),
                _NoJourneysNotice(),
              ],
            ),
    );
  }
}

/// What a suppressed vehicle shows: the threshold that hid it, and
/// nothing else (ADR 0025 D5.3, UI wording rule 4).
class _SuppressedCard extends StatelessWidget {
  const _SuppressedCard({required this.threshold});

  final int threshold;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      leadingIcon: Icons.shield_outlined,
      title: l.fleetManagerNotCalculated,
      child: Text(l.fleetManagerVehicleSuppressed(threshold)),
    );
  }
}

/// The vehicle's own KPI tiles — the same figures as the fleet card,
/// each carrying its claim class and evidence count.
class _Figures extends StatelessWidget {
  const _Figures({required this.metrics});

  final FleetVehicleMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = metrics.currency;
    final tiles = <Widget>[
      FleetKpiTile(
        label: l.fleetManagerKpiSpend,
        value: fleetFigure(
            l, metrics.spend, (v) => FleetFormats.money(v, currency)),
        claim: metrics.spend.claim,
        caveat: fleetCaveat(l, metrics.spend),
        samples: metrics.sampleCount,
      ),
      FleetKpiTile(
        label: l.fleetManagerKpiCostPerKm,
        value: fleetFigure(l, metrics.costPerKm,
            (v) => FleetFormats.costPerKm(v, currency)),
        claim: metrics.costPerKm.claim,
        caveat: fleetCaveat(l, metrics.costPerKm),
      ),
      FleetKpiTile(
        label: l.fleetManagerKpiLitres,
        value: fleetFigure(l, metrics.litres, FleetFormats.litres),
        claim: metrics.litres.claim,
        caveat: fleetCaveat(l, metrics.litres),
      ),
      FleetKpiTile(
        label: l.fleetManagerKpiDistance,
        value: fleetFigure(l, metrics.km, FleetFormats.distance),
        claim: metrics.km.claim,
        caveat: fleetCaveat(l, metrics.km),
      ),
      FleetKpiTile(
        label: l.fleetManagerKpiConsumption,
        value: fleetFigure(l, metrics.lPer100Km, FleetFormats.consumption),
        claim: metrics.lPer100Km.claim,
        caveat: fleetCaveat(l, metrics.lPer100Km),
      ),
      FleetKpiTile(
        label: l.fleetManagerKpiMeasuredCoverage,
        value: fleetFigure(l, metrics.measuredShare, FleetFormats.share),
        claim: metrics.measuredShare.claim,
        caveat: fleetCaveat(l, metrics.measuredShare),
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            // IntrinsicHeight, not `CrossAxisAlignment.stretch`: a Row
            // inside a ListView has unbounded height, and stretching
            // into it is an infinite-constraint crash. The pair still
            // reads as one band because they share the taller height.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: i + 1 < tiles.length
                        ? tiles[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The page states what it deliberately does not contain.
class _NoJourneysNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Text(
            l.fleetManagerNoJourneys,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
