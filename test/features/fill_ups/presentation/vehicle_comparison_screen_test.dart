// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/vehicle_comparison_screen.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/vehicle_comparison_provider.dart';
import 'package:tankstellen/features/trips/api.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4365 — the personal-vehicle comparison surface. Structural only:
/// no golden PNG, because a macOS-baselined image fails Linux CI and
/// proves nothing about the rules these tests are here to pin.
class _StubVehicles extends VehicleProfileList {
  _StubVehicles(this._value);
  final List<VehicleProfile> _value;

  @override
  List<VehicleProfile> build() => _value;

  void replaceAll(List<VehicleProfile> next) => state = next;
}

class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

class _StubFills extends FillUpList {
  _StubFills(this._value);
  final List<FillUp> _value;

  @override
  List<FillUp> build() => _value;
}

class _StubTrips extends TripHistoryList {
  _StubTrips(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}

const _a = VehicleProfile(id: 'a', name: 'Clio', tankCapacityL: 50);
const _b = VehicleProfile(id: 'b', name: 'Kangoo', tankCapacityL: 50);

FillUp _fill(String id, String vehicleId, int day, double odo,
        {double litres = 40, double cost = 60, String? currency = 'EUR'}) =>
    FillUp(
      id: id,
      date: DateTime.utc(2026, 1, day),
      liters: litres,
      totalCost: cost,
      odometerKm: odo,
      fuelType: FuelType.e10,
      vehicleId: vehicleId,
      currency: currency,
      stationName: 'Total',
    );

List<FillUp> _history({String? currencyB = 'EUR'}) => [
      _fill('a0', 'a', 1, 0),
      _fill('a1', 'a', 10, 600, litres: 36, cost: 60),
      _fill('a2', 'a', 20, 1000, litres: 28, cost: 48),
      _fill('b0', 'b', 1, 5000, litres: 45, cost: 70, currency: currencyB),
      _fill('b1', 'b', 10, 5500, litres: 40, cost: 70, currency: currencyB),
      _fill('b2', 'b', 20, 6000, litres: 40, cost: 70, currency: currencyB),
    ];

List<Object> _overrides({
  List<VehicleProfile> vehicles = const [_a, _b],
  List<FillUp>? fills,
}) =>
    [
      vehicleProfileListProvider.overrideWith(() => _StubVehicles(vehicles)),
      activeVehicleProfileProvider.overrideWith(() => _StubActiveVehicle(_a)),
      fillUpListProvider.overrideWith(() => _StubFills(fills ?? _history())),
      tripHistoryListProvider.overrideWith(() => _StubTrips(const [])),
      appClockProvider
          .overrideWithValue(FixedClock(DateTime.utc(2026, 3, 11, 14, 30))),
    ];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<Object>? overrides,
  Size size = const Size(400, 14000),
  double textScale = 1.0,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: (overrides ?? _overrides()).cast());
  addTearDown(container.dispose);
  container
      .read(vehicleComparisonSelectorProvider.notifier)
      .select(const ['a', 'b']);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const VehicleComparisonScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('both selected vehicles render in one comparison (box 1)',
      (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('veh_compare_column_a')), findsOneWidget);
    expect(find.byKey(const Key('veh_compare_column_b')), findsOneWidget);
    expect(find.text('6.4 L/100 km'), findsOneWidget);
  });

  testWidgets('toggling a column never changes the active vehicle (box 1)',
      (tester) async {
    final container = await _pump(tester);
    expect(container.read(activeVehicleProfileProvider)?.id, 'a');

    await tester.tap(find.byKey(const Key('veh_compare_chip_b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('veh_compare_chip_b')));
    await tester.pumpAndSettle();

    expect(container.read(activeVehicleProfileProvider)?.id, 'a');
    expect(find.byKey(const Key('veh_compare_column_b')), findsOneWidget);
  });

  testWidgets('choosing a reference changes only the comparison',
      (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byKey(const Key('veh_compare_reference_b')));
    await tester.pumpAndSettle();

    expect(
        container.read(vehicleComparisonSelectorProvider).effectiveReferenceId,
        'b');
    expect(container.read(activeVehicleProfileProvider)?.id, 'a');
  });

  testWidgets('the honesty note states what the figures are not',
      (tester) async {
    await _pump(tester);
    final l = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l.vehCompareHonestyNote), findsOneWidget);
  });

  testWidgets('the boundary inclusion rule is shown, not implied',
      (tester) async {
    await _pump(tester);
    final l = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l.vehCompareBoundaryNote), findsOneWidget);
  });

  testWidgets('two currencies withhold the winner and say why (box 7)',
      (tester) async {
    await _pump(tester,
        overrides: _overrides(fills: _history(currencyB: 'DKK')));
    final l = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.byKey(const Key('veh_compare_winner_cost_withheld')),
        findsOneWidget);
    expect(
        find.text(l.vehCompareNoWinner(l.vehCompareReasonMixedCurrencies)),
        findsOneWidget);
    // The consumption observation still ships for both columns.
    expect(find.byKey(const Key('veh_compare_winner_consumption')),
        findsOneWidget);
  });

  testWidgets('an unavailable metric shows its reason, never a zero',
      (tester) async {
    await _pump(tester,
        overrides: _overrides(fills: _history(currencyB: null)));
    final l = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l.vehCompareReasonUnknownCurrency), findsWidgets);
    expect(find.text(l.vehCompareUnavailableShort), findsWidgets);
  });

  testWidgets('a deleted vehicle keeps a recoverable selection (box 8)',
      (tester) async {
    final container = await _pump(tester, overrides: _overrides());
    (container.read(vehicleProfileListProvider.notifier) as _StubVehicles)
        .replaceAll(const [_a]);
    await tester.pumpAndSettle();
    final l = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l.vehCompareMissingVehicle), findsOneWidget);
    expect(container.read(vehicleComparisonSelectorProvider).vehicleIds,
        ['a', 'b']);

    await tester.tap(find.byKey(const Key('veh_compare_remove_missing')));
    await tester.pumpAndSettle();

    expect(
        container.read(vehicleComparisonSelectorProvider).vehicleIds, ['a']);
  });

  testWidgets('a figure opens the records behind it (box 9)', (tester) async {
    await _pump(tester);
    final l = await AppLocalizations.delegate.load(const Locale('en'));

    await tester
        .tap(find.byKey(const Key('veh_compare_sources_a_consumption')));
    await tester.pumpAndSettle();

    expect(find.text(l.vehCompareSourcesTitle), findsOneWidget);
    expect(find.text('a1'), findsWidgets);
    expect(find.text('a2'), findsWidgets);
  });

  testWidgets('narrow, large-text and localized columns keep their vehicle '
      'identity and units (box 10)', (tester) async {
    await _pump(tester,
        size: const Size(340, 30000),
        textScale: 2.0,
        locale: const Locale('de'));
    final l = await AppLocalizations.delegate.load(const Locale('de'));

    // Column identity survives the stack: the screen-reader label names
    // the vehicle and its position, in the reader's language.
    expect(
      find.bySemanticsLabel(l.vehCompareSemanticsColumn('Clio', 1, 2)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(l.vehCompareSemanticsColumn('Kangoo', 2, 2)),
      findsOneWidget,
    );
    // Every figure repeats its vehicle, so two stacked columns never
    // blur into one, and the unit travels with the number.
    expect(
      find.bySemanticsLabel(l.vehCompareSemanticsMetric(
          l.vehCompareConsumptionTitle, '6.4 L/100 km', 'Clio')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
