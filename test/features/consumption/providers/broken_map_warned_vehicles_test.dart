// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/providers/broken_map_warned_vehicles_provider.dart';

/// Unit tests for [BrokenMapWarnedVehicles] (#1423 phase 5).
///
/// The session-scoped warned-vehicles set is the guard that keeps the
/// snackbar from re-firing when the belief jitters within the 0.7-0.9
/// band. The tests below verify the contract the trip-recording
/// listener relies on:
///
///   * `markIfFirst` returns `true` exactly once per vehicle id
///   * `clear` resets the guard so a subsequent crossing fires again
///   * separate vehicle ids are tracked independently
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('markIfFirst returns true the first time, false thereafter', () {
    final notifier =
        container.read(brokenMapWarnedVehiclesProvider.notifier);
    expect(notifier.markIfFirst('veh-a'), isTrue);
    expect(notifier.markIfFirst('veh-a'), isFalse);
    expect(notifier.markIfFirst('veh-a'), isFalse);
  });

  test('separate vehicle ids are tracked independently', () {
    final notifier =
        container.read(brokenMapWarnedVehiclesProvider.notifier);
    expect(notifier.markIfFirst('veh-a'), isTrue);
    expect(notifier.markIfFirst('veh-b'), isTrue);
    expect(notifier.markIfFirst('veh-a'), isFalse);
    expect(notifier.markIfFirst('veh-b'), isFalse);
  });

  test('clear resets the guard so markIfFirst returns true again', () {
    final notifier =
        container.read(brokenMapWarnedVehiclesProvider.notifier);
    expect(notifier.markIfFirst('veh-a'), isTrue);
    notifier.clear('veh-a');
    expect(notifier.markIfFirst('veh-a'), isTrue);
  });

  test('clear on an unwarned vehicle is a no-op', () {
    final notifier =
        container.read(brokenMapWarnedVehiclesProvider.notifier);
    notifier.clear('veh-a'); // never warned, should not throw
    expect(notifier.markIfFirst('veh-a'), isTrue);
  });
}
