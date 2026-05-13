import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'shell_nav_item.dart';

/// Index of the Consumption branch in the StatefulShellRoute (see
/// `router.dart`). Public so the shell's "snap selection back to
/// Search when the last vehicle is removed" branch can refer to the
/// hidden tab by name rather than a naked `3`.
const int kConsumptionBranchIndex = 3;

/// Resolved nav destinations for the current shell render.
///
/// [items] is the list the bottom-bar / rail should iterate over.
/// [branchForSlot] maps each visible slot back to its router-branch
/// index. When Conso is hidden, Settings still routes to branch 4
/// even though it renders at display-slot 3 — same contract the #893
/// gate had.
class ShellDestinations {
  final List<ShellNavItem> items;
  final List<int> branchForSlot;

  const ShellDestinations({
    required this.items,
    required this.branchForSlot,
  });
}

/// Build the canonical 5-item nav list, hiding the Conso slot when
/// [showConsumption] is false.
///
/// The original #893 gate hid Conso "when no vehicle is configured",
/// which created a catch-22 for the Medium use-mode profile (#1517)
/// — the consumption screen is where users add their first vehicle,
/// but it was hidden until a vehicle existed. The gate is now driven
/// by `isConsumptionTabReachable(manifest, enabledFlags)` instead:
/// true when the user has either `manualConsumption` OR
/// `obd2TripRecording` effectively enabled. That's true for Medium /
/// Full profiles and false for Basic — matching the user-mode bundle
/// the wizard sells.
///
/// Pure function — no Flutter state, no Riverpod — kept lean so the
/// shell can re-resolve on every build without paying provider-read
/// overhead.
ShellDestinations resolveShellDestinations({
  required AppLocalizations? l10n,
  required bool showConsumption,
}) {
  // Kept in router-branch order so the index handed to
  // `navigationShell.goBranch()` lines up directly: Search=0, Map=1,
  // Favorites=2, Consumption=3, Settings=4.
  final allDestinations = <ShellNavItem>[
    ShellNavItem(
      Icons.search_outlined,
      Icons.search,
      l10n?.search ?? 'Search',
    ),
    ShellNavItem(Icons.map_outlined, Icons.map, l10n?.map ?? 'Map'),
    ShellNavItem(
      Icons.star_outline,
      Icons.star,
      l10n?.favorites ?? 'Favorites',
    ),
    ShellNavItem(
      Icons.local_gas_station_outlined,
      Icons.local_gas_station,
      l10n?.navConsumption ?? 'Consumption',
    ),
    ShellNavItem(
      Icons.settings_outlined,
      Icons.settings,
      l10n?.settings ?? 'Settings',
    ),
  ];

  final visibleItems = <ShellNavItem>[];
  final branchForSlot = <int>[];
  for (var i = 0; i < allDestinations.length; i++) {
    if (i == kConsumptionBranchIndex && !showConsumption) continue;
    visibleItems.add(allDestinations[i]);
    branchForSlot.add(i);
  }
  return ShellDestinations(
    items: visibleItems,
    branchForSlot: branchForSlot,
  );
}
