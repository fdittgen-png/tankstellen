// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The one control that puts a station into the driver's comparison
/// (#4363, Epic #4358).
///
/// Picking is one act with three doors — a list row, a station's detail
/// screen, a pin on the map — and all three write the SAME selection
/// (`refuelComparisonSelectionProvider`, core). Keeping the control here
/// rather than in the search feature is what lets the map and the detail
/// screen use it without importing search, and what guarantees the three
/// doors cannot drift: one icon, one tooltip, one refusal when the
/// comparison is full.
///
/// A reference price may be COMPARED — it is a real price. What it may
/// not do is pose as a place, and the comparison itself says so per row
/// (#4348); that judgement belongs to the surface that costs the trip,
/// not to this button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/refuel_comparison_selection.dart';
import '../domain/station.dart';
import '../../l10n/app_localizations.dart';
import 'snackbar_helper.dart';

/// Toggle [station] in the shared comparison, telling the driver when the
/// comparison is already full rather than silently dropping a pick.
void toggleRefuelComparison(
  BuildContext context,
  WidgetRef ref,
  Station station,
) {
  final notifier = ref.read(refuelComparisonSelectionProvider.notifier);
  final wasSelected = notifier.contains(station.id);
  if (!notifier.toggle(station) && !wasSelected) {
    SnackBarHelper.showError(
      context,
      AppLocalizations.of(context)
          .refuelCompareFull(kRefuelComparisonMaxStations),
    );
  }
}

/// Whether [stationId] is in the comparison, watched narrowly so a row
/// rebuilds only when its OWN membership changes.
bool isInRefuelComparison(WidgetRef ref, String stationId) => ref.watch(
    refuelComparisonSelectionProvider.select(
        (selection) => selection.any((s) => s.id == stationId)));

/// The icon-sized toggle, for a list row's headline and an app bar.
class RefuelCompareButton extends ConsumerWidget {
  const RefuelCompareButton({
    super.key,
    required this.station,
    this.compact = false,
  });

  final Station station;

  /// Squeeze into the 32×32 target a station row's headline uses; false
  /// gives the standard app-bar action size.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = isInRefuelComparison(ref, station.id);
    final button = IconButton(
      key: Key('compare-${station.id}'),
      padding: compact ? EdgeInsets.zero : null,
      constraints: compact ? const BoxConstraints() : null,
      icon: Icon(
        selected ? Icons.playlist_add_check : Icons.playlist_add,
        size: compact ? 22 : null,
      ),
      isSelected: selected,
      onPressed: () => toggleRefuelComparison(context, ref, station),
      tooltip: selected ? l10n.refuelCompareRemove : l10n.refuelCompareAdd,
    );
    return compact
        ? SizedBox(width: 32, height: 32, child: button)
        : button;
  }
}

/// The full-width labelled toggle, for a bottom sheet that has room for
/// words and no row of icons to sit in.
class RefuelCompareLabelledButton extends ConsumerWidget {
  const RefuelCompareLabelledButton({super.key, required this.station});

  final Station station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = isInRefuelComparison(ref, station.id);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const Key('map_sheet_compare'),
        onPressed: () => toggleRefuelComparison(context, ref, station),
        icon: Icon(selected ? Icons.playlist_add_check : Icons.playlist_add),
        label:
            Text(selected ? l10n.refuelCompareRemove : l10n.refuelCompareAdd),
      ),
    );
  }
}
