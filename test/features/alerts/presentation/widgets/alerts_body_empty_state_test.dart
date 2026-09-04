// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/core/widgets/help_banner.dart';
import 'package:tankstellen/core/widgets/panel_card.dart';
import 'package:tankstellen/core/widgets/shimmer_placeholder.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alert_statistics_card.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alerts_body.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alerts_last_checked_footer.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/radius_alert_create_sheet.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// #3951 (Epic #3947) — the alerts empty state collapses the chrome.
///
/// Zero alerts of either kind: NO 0·0·0 stats strip, NO "(0)" section
/// headers, NO help banner — exactly ONE [EmptyState] with ONE primary
/// [FilledButton] (the station-alert picker) and the zone-alert entry as
/// a secondary text button. The strip and headers return as soon as one
/// alert of either kind exists, and the zone list's first load shows the
/// shimmer — never a flash of the empty state.
PriceAlert _alert({String id = 'a1'}) => PriceAlert(
      id: id,
      stationId: 'station-1',
      stationName: 'Shell Berlin',
      fuelType: FuelType.e10,
      targetPrice: 1.50,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );

RadiusAlert _radius({String id = 'r1'}) => RadiusAlert(
      id: id,
      fuelType: 'diesel',
      threshold: 1.50,
      centerLat: 48.8566,
      centerLng: 2.3522,
      radiusKm: 10,
      label: 'Home diesel',
      createdAt: DateTime(2026, 1, 1),
      enabled: true,
    );

List<Object> _overrides(
  ({List<Object> overrides, MockStorageRepository mockStorage}) test, {
  required List<PriceAlert> alerts,
  required RadiusAlerts Function() radius,
}) {
  when(() => test.mockStorage.getSetting(any())).thenReturn(null);
  when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
  when(() => test.mockStorage.getAlerts()).thenReturn([]);
  when(() => test.mockStorage.getFavoriteIds()).thenReturn(<String>[]);
  return [
    ...test.overrides,
    alertProvider.overrideWith(() => _FixedAlerts(alerts)),
    radiusAlertsProvider.overrideWith(radius),
  ];
}

void main() {
  group('AlertsBody — zero alerts collapse the chrome (#3951)', () {
    testWidgets(
        'exactly one EmptyState + one FilledButton; no stats strip, no "(0)" '
        'headers, no help banner', (tester) async {
      final test = standardTestOverrides();
      await pumpApp(
        tester,
        const AlertsBody(),
        overrides: _overrides(
          test,
          alerts: const [],
          radius: _EmptyRadiusAlerts.new,
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('No price alerts yet'), findsOneWidget);
      expect(find.byType(AlertStatisticsCard), findsNothing);
      expect(find.byType(HelpBanner), findsNothing);
      expect(find.textContaining('(0)'), findsNothing);
      expect(find.text('Station alerts'), findsNothing);
      expect(find.text('Radius alerts'), findsNothing);
      // The zone entry stays reachable — as a secondary button, not a
      // second primary.
      expect(find.byKey(const Key('alerts_empty_add_radius')), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byKey(const Key('alerts_empty_add_radius')),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
      // The disclosures stay below — they are honesty, not chrome.
      expect(find.byType(AlertsLastCheckedFooter), findsOneWidget);
      // Still pull-to-refreshable.
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('the primary action opens the station picker',
        (tester) async {
      final test = standardTestOverrides();
      await pumpApp(
        tester,
        const AlertsBody(),
        overrides: _overrides(
          test,
          alerts: const [],
          radius: _EmptyRadiusAlerts.new,
        ),
      );

      await tester.tap(find.byKey(const Key('alerts_empty_add_station')));
      await tester.pumpAndSettle();

      expect(find.text('Pick a station'), findsOneWidget);
    });

    testWidgets('the secondary action opens the zone-alert sheet',
        (tester) async {
      final test = standardTestOverrides();
      await pumpApp(
        tester,
        const AlertsBody(),
        overrides: [
          ..._overrides(
            test,
            alerts: const [],
            radius: _EmptyRadiusAlerts.new,
          ),
          userPositionNullOverride(),
        ],
      );

      await tester.tap(find.byKey(const Key('alerts_empty_add_radius')));
      await tester.pumpAndSettle();

      expect(find.byType(RadiusAlertCreateSheet), findsOneWidget);
    });

    testWidgets('while the zone list is loading the shimmer shows, not the '
        'empty state', (tester) async {
      final test = standardTestOverrides();
      await pumpApp(
        tester,
        const AlertsBody(),
        overrides: _overrides(
          test,
          alerts: const [],
          radius: _NeverLoadsRadiusAlerts.new,
        ),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ShimmerStationList), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(AlertStatisticsCard), findsNothing);
    });
  });

  group('AlertsBody — one alert brings the chrome back (#3951)', () {
    testWidgets('one station alert: stats strip (a PanelCard) + both headers',
        (tester) async {
      final test = standardTestOverrides();
      await pumpApp(
        tester,
        const AlertsBody(),
        overrides: _overrides(
          test,
          alerts: [_alert()],
          radius: _EmptyRadiusAlerts.new,
        ),
      );

      expect(find.byType(AlertStatisticsCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertStatisticsCard),
          matching: find.byType(PanelCard),
        ),
        findsOneWidget,
      );
      expect(find.text('Station alerts (1)'), findsOneWidget);
      // The empty zone section keeps its header — without a "(0)".
      expect(find.text('Radius alerts'), findsOneWidget);
      expect(find.textContaining('(0)'), findsNothing);
      expect(find.text('Shell Berlin'), findsOneWidget);
      expect(find.text('No price alerts yet'), findsNothing);
    });

    testWidgets('one zone alert only: stats strip + both headers',
        (tester) async {
      final test = standardTestOverrides();
      await pumpApp(
        tester,
        const AlertsBody(),
        overrides: _overrides(
          test,
          alerts: const [],
          radius: () => _FixedRadiusAlerts([_radius()]),
        ),
      );

      expect(find.byType(AlertStatisticsCard), findsOneWidget);
      expect(find.text('Station alerts'), findsOneWidget);
      expect(find.text('Radius alerts (1)'), findsOneWidget);
      expect(find.text('Home diesel'), findsOneWidget);
      expect(find.text('No price alerts yet'), findsNothing);
    });
  });
}

class _FixedAlerts extends AlertNotifier {
  _FixedAlerts(this._alerts);
  final List<PriceAlert> _alerts;

  @override
  List<PriceAlert> build() => _alerts;
}

class _EmptyRadiusAlerts extends RadiusAlerts {
  @override
  Future<List<RadiusAlert>> build() async => const [];
}

class _FixedRadiusAlerts extends RadiusAlerts {
  _FixedRadiusAlerts(this._alerts);
  final List<RadiusAlert> _alerts;

  @override
  Future<List<RadiusAlert>> build() async => _alerts;
}

/// A first load that never completes — pins the "no flash" rule.
class _NeverLoadsRadiusAlerts extends RadiusAlerts {
  @override
  Future<List<RadiusAlert>> build() => Completer<List<RadiusAlert>>().future;
}
