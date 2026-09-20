// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/refuel_comparison_selection.dart';
import 'package:tankstellen/core/domain/station.dart';

/// #4363 — the selection is only a selection: it remembers what the
/// driver picked and nothing else, so it can survive every recompute.
void main() {
  Station station(String id) => Station(
        id: id,
        name: id,
        brand: 'B',
        street: 'R',
        postCode: '1',
        place: 'P',
        lat: 52,
        lng: 13,
        e10: 1.8,
      );

  late ProviderContainer container;
  late RefuelComparisonSelection selection;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    selection = container.read(refuelComparisonSelectionProvider.notifier);
  });

  test('starts empty and toggles in insertion order', () {
    expect(container.read(refuelComparisonSelectionProvider), isEmpty);
    expect(selection.toggle(station('b')), isTrue);
    expect(selection.toggle(station('a')), isTrue);
    expect(
      container.read(refuelComparisonSelectionProvider).map((s) => s.id),
      ['b', 'a'],
      reason: 'the order the driver built it in, not alphabetical',
    );
  });

  test('toggling a selected station removes it', () {
    selection.toggle(station('a'));
    expect(selection.contains('a'), isTrue);
    expect(selection.toggle(station('a')), isFalse);
    expect(selection.contains('a'), isFalse);
  });

  test('a pick past the cap is refused, never silently dropping another',
      () {
    for (var i = 0; i < kRefuelComparisonMaxStations; i++) {
      expect(selection.toggle(station('s$i')), isTrue);
    }
    expect(selection.toggle(station('one-too-many')), isFalse);
    expect(container.read(refuelComparisonSelectionProvider),
        hasLength(kRefuelComparisonMaxStations));
    expect(selection.contains('s0'), isTrue, reason: 'the oldest survives');
  });

  test('remove and clear', () {
    selection.toggle(station('a'));
    selection.toggle(station('b'));
    selection.remove('a');
    expect(
        container.read(refuelComparisonSelectionProvider).map((s) => s.id),
        ['b']);
    selection.clear();
    expect(container.read(refuelComparisonSelectionProvider), isEmpty);
  });
}
