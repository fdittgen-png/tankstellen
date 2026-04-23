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
  final List<String> toggledIds = [];
  final List<String> removedIds = [];
  final List<RadiusAlert> addedAlerts = [];

  _FakeRadiusAlerts(this._initial);

  @override
  Future<List<RadiusAlert>> build() async => _initial;

  @override
  Future<void> add(RadiusAlert alert) async {
    addedAlerts.add(alert);
    state = AsyncValue.data([..._initial, alert]);
  }

  @override
  Future<void> remove(String id) async {
    removedIds.add(id);
    state = AsyncValue.data(
      _initial.where((a) => a.id != id).toList(),
    );
  }

  @override
  Future<void> toggle(String id) async {
    toggledIds.add(id);
    state = AsyncValue.data(
      _initial
          .map((a) => a.id == id ? a.copyWith(enabled: !a.enabled) : a)
          .toList(),
    );
  }
}
