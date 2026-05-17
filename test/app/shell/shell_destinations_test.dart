import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_destinations.dart';

/// Pure-function tests for the destination-resolution helper.
///
/// History:
/// - #893 hid the Conso slot when no vehicle was configured.
/// - #conso-coherence re-introduced a gate driven by
///   `isConsumptionTabReachable` — true for Medium + Full profiles.
/// - #1874 (these tests) — Settings left the bottom bar for the
///   top-right app bar, and Search became the centre, raised slot:
///   `Map · Favorites · [Search] · Consumption`.
void main() {
  group('resolveShellDestinations', () {
    test(
      'showConsumption: true → Map · Favorites · [Search] · Consumption',
      () {
        final result =
            resolveShellDestinations(l10n: null, showConsumption: true);

        expect(result.items, hasLength(4));
        // Visual slots map back to router branches Search=0, Map=1,
        // Favorites=2, Consumption=3.
        expect(result.branchForSlot, [1, 2, 0, 3]);
        expect(result.items.map((i) => i.label).toList(),
            ['Map', 'Favorites', 'Search', 'Consumption']);

        // Conso item carries the fuel-station icon.
        expect(result.items[3].outlinedIcon,
            Icons.local_gas_station_outlined);
        expect(result.items[3].filledIcon, Icons.local_gas_station);
      },
    );

    test(
      'showConsumption: false → Map · [Search] · Favorites (Conso dropped)',
      () {
        final result =
            resolveShellDestinations(l10n: null, showConsumption: false);

        expect(result.items, hasLength(3));
        expect(result.branchForSlot, [1, 0, 2]);
        expect(result.items.map((i) => i.label).toList(),
            ['Map', 'Search', 'Favorites']);

        // No fuel-station icon in the visible items list.
        for (final item in result.items) {
          expect(item.outlinedIcon,
              isNot(Icons.local_gas_station_outlined));
        }
      },
    );

    test('Search is the only primary (raised, centre) item', () {
      for (final showConso in [true, false]) {
        final result = resolveShellDestinations(
            l10n: null, showConsumption: showConso);
        final primaries = result.items.where((i) => i.isPrimary).toList();
        expect(primaries, hasLength(1));
        expect(primaries.single.label, 'Search');
        // The primary sits in the centre slot.
        final primarySlot = result.items.indexWhere((i) => i.isPrimary);
        expect(primarySlot, result.items.length ~/ 2);
      }
    });

    test('Settings is never a bottom-bar destination (#1874)', () {
      for (final showConso in [true, false]) {
        final result = resolveShellDestinations(
            l10n: null, showConsumption: showConso);
        expect(result.items.map((i) => i.label), isNot(contains('Settings')));
        expect(result.items.map((i) => i.outlinedIcon),
            isNot(contains(Icons.settings_outlined)));
        // Branch 4 (the Settings/profile branch) is never a slot.
        expect(result.branchForSlot, isNot(contains(4)));
      }
    });

    test('falls back to English labels when l10n is null', () {
      final result =
          resolveShellDestinations(l10n: null, showConsumption: true);
      expect(result.items.map((i) => i.label).toList(),
          ['Map', 'Favorites', 'Search', 'Consumption']);
    });

    test('the Conso slot routes to kConsumptionBranchIndex', () {
      final result =
          resolveShellDestinations(l10n: null, showConsumption: true);
      final consoSlot = result.items
          .indexWhere((i) => i.outlinedIcon == Icons.local_gas_station_outlined);
      expect(consoSlot, isNonNegative);
      expect(result.branchForSlot[consoSlot], kConsumptionBranchIndex);
    });
  });
}
