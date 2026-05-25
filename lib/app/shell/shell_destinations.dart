// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'shell_nav_item.dart';

/// Router-branch index of the **Carburant** destination in the
/// StatefulShellRoute (see `shell_branches.dart`). Public so the
/// shell's "snap selection back to Search when consumption is
/// disabled" branch can refer to it by name rather than a naked `3`.
const int kConsumptionBranchIndex = 3;

/// Router-branch index of the **Trajets** destination (#1901). Trajets
/// is appended after Profile so Profile keeps index 4 — see
/// `shell_branches.dart`.
const int kTrajetsBranchIndex = 5;

/// Resolved nav destinations for the current shell render.
///
/// [items] is the list the bottom-bar / rail iterates over, **in
/// visual order** — Search sits in the centre slot (#1874).
/// [branchForSlot] maps each visible slot back to its router-branch
/// index, so a tap on slot N routes to `branchForSlot[N]`.
class ShellDestinations {
  final List<ShellNavItem> items;
  final List<int> branchForSlot;

  const ShellDestinations({
    required this.items,
    required this.branchForSlot,
  });
}

/// Build the visible nav destinations.
///
/// ## Layout (#1874 / #1901)
///
/// Search — the app's core action — is the centre, raised button; the
/// other destinations flank it. Consumption is now **two** separate
/// destinations, Carburant and Trajets (#1901):
///
///   * Conso off:            `Favorites · [Search] · Map`
///   * Fuel-only mode:       `Favorites · Map · [Search] · Carburant`
///   * Fuel + Trips mode:    `Favorites · Map · [Search] · Carburant · Trajets`
///
/// Settings is **not** a tab — it lives in the top-right app bar
/// (`SettingsAppBarAction`), reached via router branch 4 (`/profile`).
///
/// ## Conso gate
///
/// [showConsumption] gates the whole consumption surface (true for the
/// Medium / Full use-mode profiles, false for Basic — see
/// `isConsumptionTabReachable`). [showTrajets] additionally gates the
/// Trajets destination: it appears only in the fuel-and-trips ConsoMode
/// (Full profile). Fuel-only mode shows Carburant alone.
///
/// Pure function — no Flutter state, no Riverpod — kept lean so the
/// shell can re-resolve on every build without paying provider-read
/// overhead.
ShellDestinations resolveShellDestinations({
  required AppLocalizations? l10n,
  required bool showConsumption,
  required bool showTrajets,
}) {
  // Branch indices in `shell_branches.dart`: Search=0, Map=1,
  // Favorites=2, Carburant=3, Settings=4, Trajets=5. The visual slot
  // order below differs so Search lands in the centre.
  final search = ShellNavItem(
    Icons.search_outlined,
    Icons.search,
    l10n?.search ?? 'Search',
    isPrimary: true,
  );
  final map = ShellNavItem(Icons.map_outlined, Icons.map, l10n?.map ?? 'Map');
  final favorites = ShellNavItem(
    Icons.star_outline,
    Icons.star,
    l10n?.favorites ?? 'Favorites',
  );
  final carburant = ShellNavItem(
    Icons.local_gas_station_outlined,
    Icons.local_gas_station,
    l10n?.consumptionTabFuel ?? 'Fuel',
  );
  final trajets = ShellNavItem(
    Icons.route_outlined,
    Icons.route,
    l10n?.trajetsTabLabel ?? 'Trips',
  );

  if (!showConsumption) {
    return ShellDestinations(
      items: [favorites, search, map],
      branchForSlot: const [2, 0, 1],
    );
  }
  if (!showTrajets) {
    return ShellDestinations(
      items: [favorites, map, search, carburant],
      branchForSlot: const [2, 1, 0, 3],
    );
  }
  return ShellDestinations(
    items: [favorites, map, search, carburant, trajets],
    branchForSlot: const [2, 1, 0, 3, kTrajetsBranchIndex],
  );
}
