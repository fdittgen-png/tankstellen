import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'shell_nav_item.dart';

/// Index of the Consumption branch in the StatefulShellRoute (see
/// `router.dart`). Public so the shell's "snap selection back to
/// Search when the consumption features are disabled" branch can refer
/// to the hidden tab by name rather than a naked `3`.
const int kConsumptionBranchIndex = 3;

/// Resolved nav destinations for the current shell render.
///
/// [items] is the list the bottom-bar / rail iterates over, **in
/// visual order** — Search sits in the centre slot (#1874). [branchForSlot]
/// maps each visible slot back to its router-branch index, so a tap on
/// slot N routes to `branchForSlot[N]`.
class ShellDestinations {
  final List<ShellNavItem> items;
  final List<int> branchForSlot;

  const ShellDestinations({
    required this.items,
    required this.branchForSlot,
  });
}

/// Build the visible nav destinations, hiding the Conso slot when
/// [showConsumption] is false.
///
/// ## Layout (#1874)
///
/// Search — the app's core action — is the centre, raised button; the
/// other destinations flank it:
///
///   * Conso shown:  `Map · Favorites · [Search] · Consumption`
///   * Conso hidden: `Map · [Search] · Favorites`
///
/// Settings is **not** a tab — it lives in the top-right app bar
/// (`SettingsAppBarAction`), reached via router branch 4 (`/profile`).
///
/// ## Conso gate
///
/// The #893 gate hid Conso "when no vehicle is configured", a catch-22
/// for the Medium use-mode profile (#1517) — the consumption screen is
/// where users add their first vehicle. The gate is now driven by
/// `isConsumptionTabReachable(manifest, enabledFlags)`: true when the
/// user has either `manualConsumption` OR `obd2TripRecording`
/// effectively enabled (Medium / Full profiles, not Basic).
///
/// Pure function — no Flutter state, no Riverpod — kept lean so the
/// shell can re-resolve on every build without paying provider-read
/// overhead.
ShellDestinations resolveShellDestinations({
  required AppLocalizations? l10n,
  required bool showConsumption,
}) {
  // Branch indices in `router.dart`: Search=0, Map=1, Favorites=2,
  // Consumption=3, Settings=4. The visual slot order below differs so
  // Search lands in the centre.
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
  final consumption = ShellNavItem(
    Icons.local_gas_station_outlined,
    Icons.local_gas_station,
    l10n?.navConsumption ?? 'Consumption',
  );

  if (showConsumption) {
    return ShellDestinations(
      items: [map, favorites, search, consumption],
      branchForSlot: const [1, 2, 0, 3],
    );
  }
  return ShellDestinations(
    items: [map, search, favorites],
    branchForSlot: const [1, 0, 2],
  );
}
