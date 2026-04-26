import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_destinations.dart';

/// Pure-function tests for the destination-resolution helper extracted
/// from `shell_screen.dart` during the #563 refactor. Verifies that:
/// - The 5-item canonical order (Search, Map, Favorites, Conso,
///   Settings) is preserved when a vehicle is configured.
/// - The Conso slot is dropped (not stubbed, not reordered) when no
///   vehicle is configured (#893) — and the remaining slots still map
///   to their original router-branch indices so Settings still routes
///   to branch 4.
void main() {
  group('resolveShellDestinations', () {
    test('returns 5 destinations and identity slot mapping when vehicle '
        'is configured', () {
      final result =
          resolveShellDestinations(l10n: null, hasVehicle: true);

      expect(result.items, hasLength(5));
      expect(result.branchForSlot, [0, 1, 2, 3, 4]);

      // The Conso item carries the fuel-station icon — sanity-check
      // ordering hasn't drifted.
      expect(result.items[3].outlinedIcon, Icons.local_gas_station_outlined);
      expect(result.items[3].filledIcon, Icons.local_gas_station);
    });

    test('drops the Conso slot when no vehicle is configured (#893)', () {
      final result =
          resolveShellDestinations(l10n: null, hasVehicle: false);

      expect(result.items, hasLength(4));
      // The Conso slot (router-branch 3) is gone, but branchForSlot
      // still preserves the original branch indices so Settings (now
      // at display-slot 3) routes to branch 4.
      expect(result.branchForSlot, [0, 1, 2, 4]);

      // No fuel-station icon should appear in the visible items list.
      for (final item in result.items) {
        expect(item.outlinedIcon, isNot(Icons.local_gas_station_outlined));
        expect(item.filledIcon, isNot(Icons.local_gas_station));
      }
    });

    test('falls back to English labels when l10n is null', () {
      final result =
          resolveShellDestinations(l10n: null, hasVehicle: true);

      expect(result.items.map((i) => i.label).toList(), [
        'Search',
        'Map',
        'Favorites',
        'Consumption',
        'Settings',
      ]);
    });

    test('Settings always sits at the rightmost visible slot', () {
      final withConso =
          resolveShellDestinations(l10n: null, hasVehicle: true);
      final withoutConso =
          resolveShellDestinations(l10n: null, hasVehicle: false);

      expect(withConso.items.last.label, 'Settings');
      expect(withoutConso.items.last.label, 'Settings');
    });

    test('kConsumptionBranchIndex matches the position of the Conso '
        'router branch in the canonical destination list', () {
      // If router.dart ever reorders branches, this test fires before
      // the gating logic silently goes wrong.
      final result =
          resolveShellDestinations(l10n: null, hasVehicle: true);
      expect(
        result.items[kConsumptionBranchIndex].outlinedIcon,
        Icons.local_gas_station_outlined,
      );
    });
  });
}
