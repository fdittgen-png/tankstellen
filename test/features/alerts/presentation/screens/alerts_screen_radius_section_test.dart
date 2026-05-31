// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('AlertsScreen radius section (#578 phase 2)', () {
    testWidgets('renders section header with count and add button',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      final fake = _FakeRadiusAlerts([
        _sampleAlert(id: 'r1', label: 'Home diesel'),
        _sampleAlert(id: 'r2', label: 'Work e10', fuelType: 'e10'),
      ]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
          radiusAlertsProvider.overrideWith(() => fake),
        ],
      );

      expect(find.text('Radius alerts (2)'), findsOneWidget);
      expect(find.byTooltip('Add radius alert'), findsOneWidget);
      expect(find.text('Home diesel'), findsOneWidget);
      expect(find.text('Work e10'), findsOneWidget);
    });

    testWidgets('toggle switch calls RadiusAlerts.toggle(id)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      final fake = _FakeRadiusAlerts([
        _sampleAlert(id: 'r1', label: 'Home diesel', enabled: true),
      ]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
          radiusAlertsProvider.overrideWith(() => fake),
        ],
      );

      // Two switches may be present (stats + list). Filter by position
      // near the radius label.
      final switches = find.byType(Switch);
      expect(switches, findsAtLeast(1));
      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      expect(fake.toggledIds, ['r1']);
    });

    testWidgets('swipe-dismiss calls RadiusAlerts.remove(id)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      final fake = _FakeRadiusAlerts([
        _sampleAlert(id: 'r1', label: 'Home diesel'),
      ]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
          radiusAlertsProvider.overrideWith(() => fake),
        ],
      );

      await tester.drag(
        find.text('Home diesel'),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();

      expect(fake.removedIds, ['r1']);
    });

    // #2494 — the post-deletion snackbar is PAST-TENSE with an Undo action,
    // mirroring the per-station tile. The old interrogative "Delete radius
    // alert?" copy (shown AFTER the deletion already happened) must be gone.
    testWidgets('swipe-dismiss shows a past-tense undo snackbar (not the '
        'interrogative confirm)', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      final fake = _FakeRadiusAlerts([
        _sampleAlert(id: 'r1', label: 'Home diesel'),
      ]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
          radiusAlertsProvider.overrideWith(() => fake),
        ],
      );

      await tester.drag(find.text('Home diesel'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      // Past-tense deletion copy with the alert's label.
      expect(find.text('Radius alert "Home diesel" deleted'), findsOneWidget);
      // Undo action button is present.
      expect(find.text('Undo'), findsOneWidget);
      // The old interrogative copy must not appear.
      expect(find.text('Delete radius alert?'), findsNothing);
    });

    testWidgets('tapping Undo re-inserts the deleted alert via add()',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      final fake = _FakeRadiusAlerts([
        _sampleAlert(id: 'r1', label: 'Home diesel'),
      ]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
          radiusAlertsProvider.overrideWith(() => fake),
        ],
      );

      await tester.drag(find.text('Home diesel'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(fake.removedIds, ['r1']);
      expect(fake.addedAlerts, isEmpty);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // The same alert (id + label) is re-inserted through the provider's
      // add() path — not a partial reconstruction.
      expect(fake.addedAlerts.map((a) => a.id), ['r1']);
      expect(fake.addedAlerts.single.label, 'Home diesel');
    });
  });
}

RadiusAlert _sampleAlert({
  required String id,
  required String label,
  String fuelType = 'diesel',
  double threshold = 1.50,
  double centerLat = 48.8566,
  double centerLng = 2.3522,
  double radiusKm = 10,
  bool enabled = true,
}) {
  return RadiusAlert(
    id: id,
    fuelType: fuelType,
    threshold: threshold,
    centerLat: centerLat,
    centerLng: centerLng,
    radiusKm: radiusKm,
    label: label,
    createdAt: DateTime(2026, 1, 1),
    enabled: enabled,
  );
}

class _EmptyAlerts extends AlertNotifier {
  @override
  List<PriceAlert> build() => const [];
}

class _FakeRadiusAlerts extends RadiusAlerts {
  final List<RadiusAlert> _initial;
  // Mutable working copy so add/remove compose correctly (the real store
  // upserts by id — a re-added alert must not duplicate its ValueKey).
  late final List<RadiusAlert> _current = [..._initial];
  final List<String> toggledIds = [];
  final List<String> removedIds = [];
  final List<RadiusAlert> addedAlerts = [];

  _FakeRadiusAlerts(this._initial);

  @override
  Future<List<RadiusAlert>> build() async => _current;

  @override
  Future<void> add(RadiusAlert alert) async {
    addedAlerts.add(alert);
    _current
      ..removeWhere((a) => a.id == alert.id)
      ..add(alert);
    state = AsyncValue.data([..._current]);
  }

  @override
  Future<void> remove(String id) async {
    removedIds.add(id);
    _current.removeWhere((a) => a.id == id);
    state = AsyncValue.data([..._current]);
  }

  @override
  Future<void> toggle(String id) async {
    toggledIds.add(id);
    for (var i = 0; i < _current.length; i++) {
      if (_current[i].id == id) {
        _current[i] = _current[i].copyWith(enabled: !_current[i].enabled);
      }
    }
    state = AsyncValue.data([..._current]);
  }
}
