import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_destinations.dart';

/// Pure-function tests for the destination-resolution helper extracted
/// from `shell_screen.dart` during the #563 refactor.
///
/// History:
/// - #893 hid the Conso slot when no vehicle was configured.
/// - #conso-coherence-1 removed the gate entirely (`hasVehicle` was
///   the wrong signal — Medium use-mode users need Conso reachable
///   BEFORE the first vehicle exists).
/// - #conso-coherence-2 (these tests) re-introduces a gate driven by
///   `isConsumptionTabReachable(manifest, enabled)` — true for
///   Medium + Full profiles, false for Basic. Decoupled from
///   `hasVehicle` so the catch-22 is gone.
void main() {
  group('resolveShellDestinations', () {
    test(
      'showConsumption: true returns all 5 destinations with identity '
      'slot mapping',
      () {
        final result =
            resolveShellDestinations(l10n: null, showConsumption: true);

        expect(result.items, hasLength(5));
        expect(result.branchForSlot, [0, 1, 2, 3, 4]);

        // The Conso item carries the fuel-station icon — sanity-check
        // ordering hasn't drifted.
        expect(result.items[3].outlinedIcon,
            Icons.local_gas_station_outlined);
        expect(result.items[3].filledIcon, Icons.local_gas_station);
      },
    );

    test(
      'showConsumption: false drops the Conso slot — 4 items, '
      'branch indices keep pointing at the right router branches '
      '(Settings stays branch 4 even at display-slot 3)',
      () {
        final result =
            resolveShellDestinations(l10n: null, showConsumption: false);

        expect(result.items, hasLength(4));
        expect(result.branchForSlot, [0, 1, 2, 4]);

        // No fuel-station icon should appear in the visible items list.
        for (final item in result.items) {
          expect(item.outlinedIcon,
              isNot(Icons.local_gas_station_outlined));
          expect(item.filledIcon, isNot(Icons.local_gas_station));
        }
      },
    );

    test('falls back to English labels when l10n is null', () {
      final result =
          resolveShellDestinations(l10n: null, showConsumption: true);

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
          resolveShellDestinations(l10n: null, showConsumption: true);
      final withoutConso =
          resolveShellDestinations(l10n: null, showConsumption: false);
      expect(withConso.items.last.label, 'Settings');
      expect(withoutConso.items.last.label, 'Settings');
    });

    test('kConsumptionBranchIndex matches the position of the Conso '
        'router branch in the canonical destination list', () {
      final result =
          resolveShellDestinations(l10n: null, showConsumption: true);
      expect(
        result.items[kConsumptionBranchIndex].outlinedIcon,
        Icons.local_gas_station_outlined,
      );
    });
  });
}
