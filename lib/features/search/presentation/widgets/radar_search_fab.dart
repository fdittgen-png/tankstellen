// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/radar_search_provider.dart';

/// The Fuel Station Radar launch affordance on the search-results screen.
///
/// #2682 shipped it as a brand-tinted extended FAB floating bottom-right.
/// #3926 demotes it to a compact [ActionChip] on the results row: the
/// screen carried TWO floating buttons — the shell's docked search FAB and
/// this pill — and the pill covered the third station card. The shell's
/// search FAB is now the only FAB on the screen, and the list reserves
/// `kFabScrollClearance` so the last card clears it.
///
/// All radar behaviour (cache-first fetch, results injection, grey
/// result-badge, PiP controls) is unchanged and still owned by
/// [RadarSearch] + `SearchResultsContent`. The handler and the
/// `radarSearchButton` key are the same as the FAB's, so the idle → active
/// flip is preserved: idle launches the scan ([RadarSearch.runRadar]);
/// once the radar owns the results list the chip flips to a stop treatment
/// that hands the list back to the regular search ([RadarSearch.dismiss]).
class RadarSearchChip extends ConsumerWidget {
  const RadarSearchChip({super.key});

  /// Ceiling for the chip so an expanded translation ellipsises its label
  /// instead of pushing the results row into a horizontal overflow.
  static const double maxWidth = 150;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final radar = ref.watch(radarSearchProvider);
    final active = radar.active;

    // #3290 — while a run is initialising (acquiring the first GPS fix, or the
    // first station list is still loading) the chip shows a spinner + a
    // "Searching…" label so the user sees the radar is WORKING. Previously it
    // flipped straight from "Start" to "Stop radar" with no progress sign, so a
    // scan that takes a few seconds (cold GPS lock + first fetch) read as a
    // button that did nothing. The chip stays tappable throughout so the user
    // can still cancel mid-scan.
    final initializing = active && (radar.locating || radar.stations.isLoading);

    final String label;
    final Widget icon;
    if (!active) {
      label = l10n.fuelStationRadarStart;
      icon = const Icon(Icons.radar, size: 18);
    } else if (initializing) {
      label = l10n.radarSearching;
      icon = const SizedBox.square(
        dimension: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      label = l10n.stopRadar;
      icon = const Icon(Icons.stop_circle, size: 18);
    }

    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: ActionChip(
        key: const Key('radarSearchButton'),
        label: icon,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        tooltip: label,
        // While the radar owns the list, the chip stops the scan and hands the
        // results list back to the regular search; otherwise it launches a scan.
        onPressed: () {
          final notifier = ref.read(radarSearchProvider.notifier);
          if (active) {
            notifier.dismiss();
          } else {
            unawaited(notifier.runRadar());
          }
        },
      ),
    );
  }
}
