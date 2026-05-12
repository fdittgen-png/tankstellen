import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_destinations.dart';

/// Pure-function tests for the destination-resolution helper extracted
/// from `shell_screen.dart` during the #563 refactor.
///
/// History note: #893 originally dropped the Conso slot when no
/// vehicle was configured. That gate was removed (#conso-coherence)
/// because the Medium use-mode profile (#1517) needs the Conso tab
/// reachable BEFORE a vehicle exists — the vehicle-add affordance
/// lives inside the consumption screen, so hiding the tab created a
/// catch-22. Conso is now always present; the empty-state inside the
/// consumption screen owns the no-vehicle / no-fill-up affordances.
void main() {
  group('resolveShellDestinations', () {
    test(
      'always returns 5 destinations with identity slot mapping',
      () {
        final result = resolveShellDestinations(l10n: null);

        expect(result.items, hasLength(5));
        expect(result.branchForSlot, [0, 1, 2, 3, 4]);

        // The Conso item carries the fuel-station icon — sanity-check
        // ordering hasn't drifted.
        expect(result.items[3].outlinedIcon, Icons.local_gas_station_outlined);
        expect(result.items[3].filledIcon, Icons.local_gas_station);
      },
    );

    test('falls back to English labels when l10n is null', () {
      final result = resolveShellDestinations(l10n: null);

      expect(result.items.map((i) => i.label).toList(), [
        'Search',
        'Map',
        'Favorites',
        'Consumption',
        'Settings',
      ]);
    });

    test('Settings always sits at the rightmost visible slot', () {
      final result = resolveShellDestinations(l10n: null);

      expect(result.items.last.label, 'Settings');
    });

    test('kConsumptionBranchIndex matches the position of the Conso '
        'router branch in the canonical destination list', () {
      // If router.dart ever reorders branches, this test fires before
      // the routing logic silently goes wrong.
      final result = resolveShellDestinations(l10n: null);
      expect(
        result.items[kConsumptionBranchIndex].outlinedIcon,
        Icons.local_gas_station_outlined,
      );
    });
  });
}
