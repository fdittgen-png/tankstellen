// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/radar_search_provider.dart';

/// #2682 — the Fuel Station Radar launch affordance on the search-results
/// screen, styled identically to the Trajets "Start recording" pill
/// (`TrajetsRecordFab`): a brand-tinted, rounded [FloatingActionButton.extended]
/// floating bottom-right, with a leading filled icon + a label.
///
/// Replaces the cramped header radar icon-button (#2675) — the launch
/// affordance only; all radar behaviour (cache-first fetch, results injection,
/// grey result-badge, PiP controls) is unchanged and still owned by
/// [RadarSearch] + `SearchResultsContent`.
///
/// Mirrors the trip pill's idle→active flip: idle launches the scan
/// ([RadarSearch.runRadar]); once the radar owns the results list it flips to
/// a stop treatment that hands the list back to the regular search
/// ([RadarSearch.dismiss]) — the same "one button, two states" pattern the
/// "Start recording" → "Resume recording" pill uses.
class RadarSearchFab extends ConsumerWidget {
  const RadarSearchFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(radarSearchProvider).active;

    final label = active
        ? (l10n?.stopRadar ?? 'Stop radar')
        : (l10n?.fuelStationRadarStart ?? 'Start fuel station radar');

    return FloatingActionButton.extended(
      key: const Key('radarSearchButton'),
      // While the radar owns the list, the pill stops the scan and hands the
      // results list back to the regular search; otherwise it launches a scan.
      onPressed: () {
        final notifier = ref.read(radarSearchProvider.notifier);
        if (active) {
          notifier.dismiss();
        } else {
          unawaited(notifier.runRadar());
        }
      },
      icon: Icon(active ? Icons.stop_circle : Icons.radar),
      label: Text(label),
    );
  }
}
