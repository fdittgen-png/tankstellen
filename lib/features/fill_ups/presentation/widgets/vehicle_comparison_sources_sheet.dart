// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The #4365 summary→source drilldown: which records a displayed
/// figure was computed from.
///
/// It lists identities, not copies. The records live in their own
/// repositories; a comparison that forked them would drift from the
/// history the user can actually edit.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/vehicle_comparison_facts.dart';

/// Show the records behind one figure.
Future<void> showVehicleComparisonSources(
  BuildContext context, {
  required String vehicleName,
  required FigureSources sources,
}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => VehicleComparisonSourcesSheet(
          vehicleName: vehicleName, sources: sources),
    );

/// The sheet body — separated so a widget test can pump it directly.
class VehicleComparisonSourcesSheet extends StatelessWidget {
  const VehicleComparisonSourcesSheet({
    super.key,
    required this.vehicleName,
    required this.sources,
  });

  final String vehicleName;
  final FigureSources sources;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: Spacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.vehCompareSourcesTitle, style: AppText.title(context)),
            const SizedBox(height: Spacing.sm),
            Text(vehicleName, style: theme.textTheme.bodySmall),
            const SizedBox(height: Spacing.md),
            Text(l.vehCompareSourcesWindows(sources.windowIds.length)),
            Text(l.vehCompareSourcesFills(sources.fillIds.length)),
            if (sources.tripIds.isNotEmpty)
              Text(l.vehCompareSourcesTrips(sources.tripIds.length)),
            const SizedBox(height: Spacing.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final id in sources.windowIds)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.local_gas_station_outlined),
                      title: Text(id),
                    ),
                  for (final id in sources.fillIds)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(id),
                    ),
                  for (final id in sources.tripIds)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.route_outlined),
                      title: Text(id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
