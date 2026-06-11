// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2756 — the consumption app bar was crammed with 5–6 trailing actions
/// (OBD2 chip + export + restore + carbon[gated] + Settings, plus the
/// map on Trajets), so the title clipped to "Car…". These tests guard
/// the M3 restructure: 1–2 visible actions + one overflow kebab holding
/// everything else, identical across the Carburant and Trajets tabs.

class _FixedFillUpList extends FillUpList {
  @override
  List<FillUp> build() => const [];
}

class _FixedChargingLogs extends ChargingLogs {
  @override
  Future<List<ChargingLog>> build() async => const [];
}

/// An active vehicle with a paired OBD2 adapter MAC, so the title-bar
/// [Obd2StatusChip] self-hides (the "paired but disconnected" branch
/// renders a zero-size box, letting the global status dot carry the
/// signal). This keeps the trailing-action count deterministic — just
/// the overflow kebab.
class _PairedVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => const VehicleProfile(
    id: 'paired',
    name: 'Paired',
    type: VehicleType.combustion,
    obd2AdapterMac: 'AA:BB:CC:DD:EE:FF',
  );
}

class _EmptyVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

class _FixedTripHistoryList extends TripHistoryList {
  @override
  List<TripHistoryEntry> build() => const [];
}

/// Feature flags with the carbon dashboard ENABLED.
class _CarbonOnFlags extends FeatureFlags {
  @override
  Future<Set<Feature>> build() async => <Feature>{
    Feature.showConsumptionTab,
    Feature.carbonDashboard,
  };
}

/// Feature flags with the carbon dashboard DISABLED.
class _CarbonOffFlags extends FeatureFlags {
  @override
  Future<Set<Feature>> build() async => <Feature>{Feature.showConsumptionTab};
}

Future<void> _pump(
  WidgetTester tester, {
  required ConsumptionSection section,
  required FeatureFlags Function() flags,
}) async {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(
        path: '/screen',
        builder: (_, _) => ConsumptionScreen(section: section),
      ),
      GoRoute(path: '/carbon', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/vehicles', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: '/consumption/pick-station',
        builder: (_, _) => const SizedBox(),
      ),
    ],
  );

  await pumpApp(
    tester,
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList()),
      chargingLogsProvider.overrideWith(() => _FixedChargingLogs()),
      activeVehicleProfileProvider.overrideWith(() => _PairedVehicle()),
      vehicleProfileListProvider.overrideWith(() => _EmptyVehicleList()),
      tripHistoryListProvider.overrideWith(() => _FixedTripHistoryList()),
      featureFlagsProvider.overrideWith(flags),
      gamificationEnabledProvider.overrideWithValue(true),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumptionAppBarActions — title no longer truncates (#2756)', () {
    testWidgets('Carburant: full title, no visible IconButton but the kebab', (
      tester,
    ) async {
      await _pump(
        tester,
        section: ConsumptionSection.fuel,
        flags: () => _CarbonOnFlags(),
      );

      // The full "Fuel" title is rendered (no "Car…" truncation).
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Fuel')),
        findsOneWidget,
      );

      // Only the overflow kebab is a visible trailing IconButton (the
      // OBD2 chip self-hides for a paired-but-disconnected adapter; the
      // leading car icon is not a trailing action). No map on Carburant.
      expect(
        find.byKey(const Key('consumption_overflow_menu')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('trajets_view_all_on_map')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('consumption_overflow_menu')),
          matching: find.byIcon(Icons.more_vert),
        ),
        findsOneWidget,
      );

      // The overflow items are hidden until the menu opens.
      expect(find.byKey(const Key('export_backup')), findsNothing);
      expect(find.byKey(const Key('restore_backup')), findsNothing);

      // The AppBar carries just 2 IconButtons total — the leading car
      // icon + the trailing kebab; no stray trailing buttons remain.
      final appBarIconButtons = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      );
      expect(tester.widgetList(appBarIconButtons).length, 2);
    });

    testWidgets('Trajets: map shortcut + kebab are both visible, full title', (
      tester,
    ) async {
      await _pump(
        tester,
        section: ConsumptionSection.trajets,
        flags: () => _CarbonOnFlags(),
      );

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Trips')),
        findsOneWidget,
      );
      // The Trajets map shortcut is a visible primary action in the bar.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(const Key('trajets_view_all_on_map')),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('consumption_overflow_menu')),
        findsOneWidget,
      );
    });
  });

  group('ConsumptionAppBarActions — overflow kebab contents (#2756)', () {
    testWidgets('opens to export / restore / carbon / Settings (carbon on)', (
      tester,
    ) async {
      await _pump(
        tester,
        section: ConsumptionSection.fuel,
        flags: () => _CarbonOnFlags(),
      );

      await tester.tap(find.byKey(const Key('consumption_overflow_menu')));
      await tester.pumpAndSettle();

      // Every action that left the bar is reachable in the menu by key…
      expect(find.byKey(const Key('export_backup')), findsOneWidget);
      expect(find.byKey(const Key('restore_backup')), findsOneWidget);
      expect(find.byKey(const Key('open_carbon_dashboard')), findsOneWidget);
      // …and Settings sits below the divider.
      expect(find.byType(PopupMenuDivider), findsOneWidget);
      // …with visible labels.
      expect(find.text('Export backup'), findsOneWidget);
      expect(find.text('Restore backup'), findsOneWidget);
      expect(find.text('Carbon dashboard'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('hides the carbon item when the feature is disabled', (
      tester,
    ) async {
      await _pump(
        tester,
        section: ConsumptionSection.fuel,
        flags: () => _CarbonOffFlags(),
      );

      await tester.tap(find.byKey(const Key('consumption_overflow_menu')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('open_carbon_dashboard')), findsNothing);
      expect(find.text('Carbon dashboard'), findsNothing);
      // Export / restore / Settings are still present.
      expect(find.byKey(const Key('export_backup')), findsOneWidget);
      expect(find.byKey(const Key('restore_backup')), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('the kebab carries a "More" tooltip for a11y', (tester) async {
      await _pump(
        tester,
        section: ConsumptionSection.fuel,
        flags: () => _CarbonOnFlags(),
      );
      expect(find.byTooltip('More'), findsOneWidget);
    });

    testWidgets('choosing the carbon item routes to /carbon (gated)', (
      tester,
    ) async {
      await _pump(
        tester,
        section: ConsumptionSection.fuel,
        flags: () => _CarbonOnFlags(),
      );

      await tester.tap(find.byKey(const Key('consumption_overflow_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_carbon_dashboard')));
      await tester.pumpAndSettle();

      // The /carbon stub replaced the screen — the kebab is gone.
      expect(find.byKey(const Key('consumption_overflow_menu')), findsNothing);
    });

    testWidgets('choosing Settings routes to /profile', (tester) async {
      await _pump(
        tester,
        section: ConsumptionSection.fuel,
        flags: () => _CarbonOnFlags(),
      );

      await tester.tap(find.byKey(const Key('consumption_overflow_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consumption_overflow_menu')), findsNothing);
    });
  });
}
