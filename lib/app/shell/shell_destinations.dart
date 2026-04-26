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
/// index — when Conso is hidden (#893), Settings still routes to
/// branch 4 even though it sits at display-slot 3.
class ShellDestinations {
  final List<ShellNavItem> items;
  final List<int> branchForSlot;

  const ShellDestinations({
    required this.items,
    required this.branchForSlot,
  });
}

/// Build the canonical 5-item nav list, then strip the Conso slot
/// when no vehicle is configured. Pure function — no Flutter state,
/// no Riverpod — the shell decides _when_ to call it (every build)
/// and what `hasVehicle` evaluates to.
ShellDestinations resolveShellDestinations({
  required AppLocalizations? l10n,
  required bool hasVehicle,
}) {
  // Kept in router-branch order so the index handed to
  // `navigationShell.goBranch()` still lines up: Search=0, Map=1,
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

  // Visible items + the router-branch index each one maps to. When
  // Conso is hidden, Settings still routes to branch 4 even though
  // it renders at display-slot 3.
  final visibleDestinations = <ShellNavItem>[];
  final branchForSlot = <int>[];
  for (var i = 0; i < allDestinations.length; i++) {
    if (i == kConsumptionBranchIndex && !hasVehicle) continue;
    visibleDestinations.add(allDestinations[i]);
    branchForSlot.add(i);
  }
  return ShellDestinations(
    items: visibleDestinations,
    branchForSlot: branchForSlot,
  );
}
