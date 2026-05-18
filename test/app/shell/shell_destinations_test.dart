import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_destinations.dart';

/// Pure-function tests for the destination-resolution helper.
///
/// History:
/// - #893 hid the Conso slot when no vehicle was configured.
/// - #conso-coherence re-introduced a gate driven by
///   `isConsumptionTabReachable` — true for Medium + Full profiles.
/// - #1874 — Settings left the bottom bar for the top-right app bar,
///   and Search became the centre, raised slot.
/// - #1901 (these tests) — Consumption split into two destinations,
///   Carburant and Trajets. `resolveShellDestinations` now takes a
///   `showTrajets` flag covering three visibility states:
///     conso off:           `Map · [Search] · Favorites`
///     fuel-only:           `Map · Favorites · [Search] · Carburant`
///     fuel + trips:        `Map · Favorites · [Search] · Carburant · Trajets`
void main() {
  group('resolveShellDestinations', () {
    test(
      'conso off → Map · [Search] · Favorites (Carburant + Trajets dropped)',
      () {
        final result = resolveShellDestinations(
          l10n: null,
          showConsumption: false,
          showTrajets: false,
        );

        expect(result.items, hasLength(3));
        expect(result.branchForSlot, [1, 0, 2]);
        expect(result.items.map((i) => i.label).toList(),
            ['Map', 'Search', 'Favorites']);

        // No fuel-station / route icon in the visible items list.
        for (final item in result.items) {
          expect(item.outlinedIcon, isNot(Icons.local_gas_station_outlined));
          expect(item.outlinedIcon, isNot(Icons.route_outlined));
        }
      },
    );

    test(
      'fuel-only mode → Map · Favorites · [Search] · Carburant '
      '(#1901: Trajets hidden)',
      () {
        final result = resolveShellDestinations(
          l10n: null,
          showConsumption: true,
          showTrajets: false,
        );

        expect(result.items, hasLength(4));
        // Visual slots map back to router branches Search=0, Map=1,
        // Favorites=2, Carburant=3.
        expect(result.branchForSlot, [1, 2, 0, 3]);
        expect(result.items.map((i) => i.label).toList(),
            ['Map', 'Favorites', 'Search', 'Fuel']);

        // Carburant item carries the fuel-station icon.
        expect(result.items[3].outlinedIcon, Icons.local_gas_station_outlined);
        expect(result.items[3].filledIcon, Icons.local_gas_station);

        // No Trajets destination in fuel-only mode.
        for (final item in result.items) {
          expect(item.outlinedIcon, isNot(Icons.route_outlined));
        }
      },
    );

    test(
      'fuel + trips mode → Map · Favorites · [Search] · Carburant · Trajets '
      '(#1901)',
      () {
        final result = resolveShellDestinations(
          l10n: null,
          showConsumption: true,
          showTrajets: true,
        );

        expect(result.items, hasLength(5));
        // Search=0, Map=1, Favorites=2, Carburant=3, Trajets=5.
        expect(result.branchForSlot, [1, 2, 0, 3, kTrajetsBranchIndex]);
        expect(result.items.map((i) => i.label).toList(),
            ['Map', 'Favorites', 'Search', 'Fuel', 'Trips']);

        // Carburant carries the fuel-station icon, Trajets the route icon.
        expect(result.items[3].outlinedIcon, Icons.local_gas_station_outlined);
        expect(result.items[3].filledIcon, Icons.local_gas_station);
        expect(result.items[4].outlinedIcon, Icons.route_outlined);
        expect(result.items[4].filledIcon, Icons.route);
      },
    );

    test('Search is the only primary (raised, centre) item', () {
      // #1901 — fuel + trips mode has an even item count (5 is odd, so
      // the centre is well-defined); cover all three visibility states.
      for (final state in const [
        (false, false),
        (true, false),
        (true, true),
      ]) {
        final result = resolveShellDestinations(
          l10n: null,
          showConsumption: state.$1,
          showTrajets: state.$2,
        );
        final primaries = result.items.where((i) => i.isPrimary).toList();
        expect(primaries, hasLength(1));
        expect(primaries.single.label, 'Search');
        // The primary sits in the centre slot.
        final primarySlot = result.items.indexWhere((i) => i.isPrimary);
        expect(primarySlot, result.items.length ~/ 2);
      }
    });

    test('Settings is never a bottom-bar destination (#1874)', () {
      for (final state in const [
        (false, false),
        (true, false),
        (true, true),
      ]) {
        final result = resolveShellDestinations(
          l10n: null,
          showConsumption: state.$1,
          showTrajets: state.$2,
        );
        expect(result.items.map((i) => i.label), isNot(contains('Settings')));
        expect(result.items.map((i) => i.outlinedIcon),
            isNot(contains(Icons.settings_outlined)));
        // Branch 4 (the Settings/profile branch) is never a slot.
        expect(result.branchForSlot, isNot(contains(4)));
      }
    });

    test('falls back to English labels when l10n is null', () {
      final result = resolveShellDestinations(
        l10n: null,
        showConsumption: true,
        showTrajets: true,
      );
      expect(result.items.map((i) => i.label).toList(),
          ['Map', 'Favorites', 'Search', 'Fuel', 'Trips']);
    });

    test('the Carburant slot routes to kConsumptionBranchIndex', () {
      final result = resolveShellDestinations(
        l10n: null,
        showConsumption: true,
        showTrajets: false,
      );
      final consoSlot = result.items
          .indexWhere((i) => i.outlinedIcon == Icons.local_gas_station_outlined);
      expect(consoSlot, isNonNegative);
      expect(result.branchForSlot[consoSlot], kConsumptionBranchIndex);
    });

    test('the Trajets slot routes to kTrajetsBranchIndex (#1901)', () {
      final result = resolveShellDestinations(
        l10n: null,
        showConsumption: true,
        showTrajets: true,
      );
      final trajetsSlot =
          result.items.indexWhere((i) => i.outlinedIcon == Icons.route_outlined);
      expect(trajetsSlot, isNonNegative);
      expect(result.branchForSlot[trajetsSlot], kTrajetsBranchIndex);
    });
  });
}
