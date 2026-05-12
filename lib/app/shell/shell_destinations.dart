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
/// index. The list is kept stable across renders so destinations
/// don't reorder — every slot index always points at the same
/// router branch.
class ShellDestinations {
  final List<ShellNavItem> items;
  final List<int> branchForSlot;

  const ShellDestinations({
    required this.items,
    required this.branchForSlot,
  });
}

/// Build the canonical 5-item nav list.
///
/// History: #893 hid the Conso slot when no vehicle was configured.
/// That created a catch-22 for the Medium use-mode profile (#1517) —
/// the user couldn't reach the consumption screen to add their first
/// fill-up + vehicle because the tab was hidden until a vehicle
/// existed. The gate was removed so the Conso tab is always visible;
/// the empty-state inside the consumption screen owns the "no vehicle
/// yet" affordance now.
///
/// Pure function — no Flutter state, no Riverpod — kept lean so the
/// shell can re-resolve on every build without paying provider-read
/// overhead.
ShellDestinations resolveShellDestinations({
  required AppLocalizations? l10n,
}) {
  // Kept in router-branch order so the index handed to
  // `navigationShell.goBranch()` lines up directly: Search=0, Map=1,
  // Favorites=2, Consumption=3, Settings=4.
  final destinations = <ShellNavItem>[
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

  return ShellDestinations(
    items: destinations,
    branchForSlot: List<int>.generate(destinations.length, (i) => i),
  );
}
