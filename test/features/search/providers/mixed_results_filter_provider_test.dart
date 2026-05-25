// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/providers/mixed_results_filter_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

/// Pins the mixed fuel + EV results filter notifiers (#1784).
void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('ResultKindFilter', () {
    test('defaults to both — the unified list shows the mixed feed', () {
      expect(container().read(resultKindFilterProvider), ResultKind.both);
    });

    test('set narrows the kind', () {
      final c = container();
      c.read(resultKindFilterProvider.notifier).set(ResultKind.ev);
      expect(c.read(resultKindFilterProvider), ResultKind.ev);
    });
  });

  group('EvConnectorFilter', () {
    test('defaults to empty (no-op)', () {
      expect(container().read(evConnectorFilterProvider), isEmpty);
    });

    test('toggle adds then removes a connector type', () {
      final c = container();
      final notifier = c.read(evConnectorFilterProvider.notifier);

      notifier.toggle(ConnectorType.ccs);
      expect(c.read(evConnectorFilterProvider), {ConnectorType.ccs});

      notifier.toggle(ConnectorType.chademo);
      expect(c.read(evConnectorFilterProvider),
          {ConnectorType.ccs, ConnectorType.chademo});

      notifier.toggle(ConnectorType.ccs);
      expect(c.read(evConnectorFilterProvider), {ConnectorType.chademo});
    });

    test('clear empties the set', () {
      final c = container();
      final notifier = c.read(evConnectorFilterProvider.notifier);
      notifier.toggle(ConnectorType.ccs);
      notifier.clear();
      expect(c.read(evConnectorFilterProvider), isEmpty);
    });
  });

  group('EvMinPowerFilter', () {
    test('defaults to 0 (no minimum)', () {
      expect(container().read(evMinPowerFilterProvider), 0);
    });

    test('set updates the threshold', () {
      final c = container();
      c.read(evMinPowerFilterProvider.notifier).set(150);
      expect(c.read(evMinPowerFilterProvider), 150);
    });

    test('set clamps to the 0–350 kW envelope', () {
      final c = container();
      final notifier = c.read(evMinPowerFilterProvider.notifier);
      notifier.set(999);
      expect(c.read(evMinPowerFilterProvider), 350);
      notifier.set(-10);
      expect(c.read(evMinPowerFilterProvider), 0);
    });
  });
}
