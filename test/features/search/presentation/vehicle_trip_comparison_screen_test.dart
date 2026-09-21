// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4367 — the same-trip comparison surface. Structural only: no golden
/// PNG, because a macOS-baselined image fails Linux CI and proves
/// nothing about the rules these tests exist to pin.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/vehicle_comparison_key.dart';
import 'package:tankstellen/core/domain/vehicle_trip_providers.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/presentation/screens/vehicle_trip_comparison_screen.dart';
import 'package:tankstellen/features/search/providers/ignored_stations_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_applier.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';
import 'package:tankstellen/features/search/providers/vehicle_trip_comparison_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

final _now = DateTime.utc(2026, 9, 20, 8);

final _geometry = [
  for (var i = 0; i <= 40; i++) LatLng(44.0 + i / 10, 5.0),
];

Station _station(String id, double lat, {double? e10, double? diesel}) =>
    Station(
      id: id,
      name: 'Station $id',
      brand: 'TOTAL',
      street: 'R',
      postCode: '1',
      place: 'P',
      lat: lat,
      lng: 5.0,
      e10: e10,
      diesel: diesel,
    );

RouteSearchResult _route(List<Station> stations) => RouteSearchResult(
      route: RouteInfo(
        geometry: _geometry,
        distanceKm: 444,
        durationMinutes: 300,
        samplePoints: const [LatLng(45, 5)],
      ),
      stations: [for (final s in stations) FuelStationResult(s)],
    );

VehicleTripBasis _basis(
  String id,
  String name, {
  required double? consumption,
  double? capacity = 50,
  double? start = 20,
  FuelType? fuel = FuelType.e10,
}) =>
    VehicleTripBasis(
      vehicleId: id,
      vehicleName: name,
      fuel: fuel,
      capacityL: capacity,
      startLitres: start,
      consumptionLPer100km: consumption,
      consumptionSource: TripInputSource.measured,
      levelSource: TripInputSource.measured,
    );

List<Override> _overrides({
  RouteSearchResult? route,
  required List<VehicleTripBasis> bases,
  RefuelPlanLauncher? launcher,
}) =>
    [
      appClockProvider.overrideWithValue(FixedClock(_now)),
      routeSearchStateProvider.overrideWith(() => _FixedRoute(route)),
      selectedFuelTypeProvider.overrideWith(_FixedFuel.new),
      ignoredStationsProvider.overrideWith(() => _FixedIgnored(const [])),
      comparedVehicleBasesProvider.overrideWithValue(ComparedVehicleBases(
        key: VehicleComparisonKey(
            vehicleIds: [for (final b in bases) b.vehicleId]),
        bases: bases,
        referenceVehicleId: bases.isEmpty ? null : bases.first.vehicleId,
      )),
      travelEstimateFetcherProvider
          .overrideWithValue((context, stops) async => const []),
      if (launcher != null)
        refuelPlanLauncherProvider.overrideWithValue(launcher),
    ];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required List<Override> overrides,
  Size size = const Size(400, 6000),
  double textScale = 1.0,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
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
      home: const VehicleTripComparisonScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('a valid comparison', () {
    List<Override> valid() => _overrides(
          route: _route([_station('mid', 45.0, e10: 1.80)]),
          bases: [
            _basis('a', 'Clio', consumption: 6),
            _basis('b', 'Kangoo', consumption: 8),
          ],
        );

    testWidgets('renders one column per vehicle', (tester) async {
      await _pump(tester, overrides: valid());
      expect(find.byKey(const Key('veh_trip_column_a')), findsOneWidget);
      expect(find.byKey(const Key('veh_trip_column_b')), findsOneWidget);
      expect(find.text('Clio'), findsWidgets);
      expect(find.text('Kangoo'), findsWidgets);
    });

    testWidgets('cost to drive and cash at the pump are separate rows, each '
        'with its own sentence', (tester) async {
      await _pump(tester, overrides: valid());
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.vehTripCostToDriveLabel), findsNWidgets(2));
      expect(find.text(l.vehTripCashRequiredLabel), findsNWidgets(2));
      expect(find.textContaining('does not change with what is already'),
          findsNWidgets(2));
      expect(find.textContaining('cheaper to refuel, not cheaper to drive'),
          findsNWidgets(2));
    });

    testWidgets('the forecast and the ownership-cost boundary are stated',
        (tester) async {
      await _pump(tester, overrides: valid());
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.vehTripForecastNote), findsOneWidget);
      expect(find.text(l.vehTripScopeNote), findsOneWidget);
    });

    testWidgets('the cheaper journey is named, not the cheaper pump price',
        (tester) async {
      await _pump(
        tester,
        overrides: _overrides(
          route: _route([_station('mid', 45.0, e10: 1.80)]),
          bases: [
            _basis('a', 'Clio', consumption: 6),
            _basis('b', 'Kangoo', consumption: 8),
          ],
        ),
      );
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.vehTripWinnerCost('Clio')), findsOneWidget);
    });

    testWidgets('it survives a narrow screen at large text', (tester) async {
      await _pump(tester,
          overrides: valid(),
          size: const Size(360, 12000),
          textScale: 2.0);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('veh_trip_column_a')), findsOneWidget);
    });
  });

  group('a partial comparison', () {
    testWidgets('a vehicle nothing on the route can fuel says why, and the '
        'other column keeps its figures', (tester) async {
      await _pump(
        tester,
        overrides: _overrides(
          route: _route([_station('mid', 45.0, e10: 1.80)]),
          bases: [
            _basis('a', 'Clio', consumption: 6),
            // Its own tank covers the whole journey, so the plan is
            // real; what is missing is a price for ITS grade.
            _basis('d', 'Partner',
                consumption: 5, start: 50, fuel: FuelType.diesel),
          ],
        ),
      );
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      // Not a dash, and not a zero: the reason, in journey terms.
      expect(find.text(l.vehTripNoPriceForFuel), findsWidgets);
      expect(find.text(l.vehTripWinnerWithheld), findsWidgets);
      expect(find.byKey(const Key('veh_trip_column_a')), findsOneWidget);
    });
  });

  group('a cross-border comparison', () {
    testWidgets('each column plans its own stops from its own fuel',
        (tester) async {
      // The same two forecourts sell both grades at different prices;
      // each car is priced at the grade it actually takes.
      await _pump(
        tester,
        overrides: _overrides(
          route: _route([
            _station('bridge', 44.6, e10: 2.00, diesel: 1.95),
            _station('beyond', 45.6, e10: 1.50, diesel: 1.40),
          ]),
          bases: [
            _basis('a', 'Clio', consumption: 10, capacity: 40, start: 10),
            _basis('d', 'Partner',
                consumption: 5,
                capacity: 50,
                start: 20,
                fuel: FuelType.diesel),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      // Both plans name real stations rather than ids.
      expect(find.textContaining('Station beyond'), findsWidgets);
    });
  });

  group('invalid input', () {
    testWidgets('a vehicle with no consumption is explained, never guessed',
        (tester) async {
      await _pump(
        tester,
        overrides: _overrides(
          route: _route([_station('mid', 45.0, e10: 1.80)]),
          bases: [
            _basis('a', 'Clio', consumption: 6),
            _basis('x', 'Twingo', consumption: null),
          ],
        ),
      );
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.textContaining(l.vehCompareReasonNoEvidence), findsWidgets);
      expect(find.text(l.vehTripUnavailableShort), findsWidgets);
    });

    testWidgets('there is no route to compare over', (tester) async {
      await _pump(
        tester,
        overrides: _overrides(route: null, bases: [
          _basis('a', 'Clio', consumption: 6),
          _basis('b', 'Kangoo', consumption: 8),
        ]),
      );
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.vehTripNoRoute), findsOneWidget);
    });

    testWidgets('fewer than two vehicles are selected', (tester) async {
      await _pump(
        tester,
        overrides: _overrides(
          route: _route([_station('mid', 45.0, e10: 1.80)]),
          bases: [_basis('a', 'Clio', consumption: 6)],
        ),
      );
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.vehTripNotEnoughVehicles), findsOneWidget);
    });
  });

  group('the driver acts', () {
    testWidgets('a typed consumption changes only its own column',
        (tester) async {
      final container = await _pump(
        tester,
        overrides: _overrides(
          route: _route([_station('mid', 45.0, e10: 1.80)]),
          bases: [
            _basis('a', 'Clio', consumption: 6),
            _basis('b', 'Kangoo', consumption: 8),
          ],
        ),
      );
      final before = container
          .read(vehicleTripComparisonProvider)
          .comparison!
          .columnFor('b')!
          .fuelUsedLitres
          .valueOrNull;

      container
          .read(vehicleTripAssumptionsProvider.notifier)
          .setConsumption('a', 12);
      await tester.pumpAndSettle();

      final after = container.read(vehicleTripComparisonProvider).comparison!;
      expect(after.columnFor('a')!.basis.consumptionLPer100km, 12);
      expect(after.columnFor('a')!.basis.consumptionSource,
          TripInputSource.manual);
      expect(after.columnFor('b')!.basis.consumptionLPer100km, 8,
          reason: 'the other column is untouched');
      expect(after.columnFor('b')!.fuelUsedLitres.valueOrNull, before);

      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.vehTripSourceManual), findsOneWidget);
    });

    testWidgets('applying a plan hands the real vehicle and its ordered '
        'stations to the route boundary', (tester) async {
      RefuelPlanLaunch? launched;
      await _pump(
        tester,
        overrides: _overrides(
          route: _route([_station('mid', 45.0, e10: 1.80)]),
          bases: [
            _basis('a', 'Clio', consumption: 10, start: 20),
            _basis('b', 'Kangoo', consumption: 12, start: 20),
          ],
          launcher: (launch) async {
            launched = launch;
            return true;
          },
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('veh_trip_apply_a')));
      await tester.tap(find.byKey(const Key('veh_trip_apply_a')));
      await tester.pumpAndSettle();

      expect(launched, isNotNull);
      expect([for (final w in launched!.planStops) w.stationId], ['mid']);
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.vehTripApplied('Clio')), findsOneWidget);
    });
  });

  group('localisation', () {
    testWidgets('the screen speaks French', (tester) async {
      await _pump(
        tester,
        locale: const Locale('fr'),
        overrides: _overrides(
          route: _route([_station('mid', 45.0, e10: 1.80)]),
          bases: [
            _basis('a', 'Clio', consumption: 6),
            _basis('b', 'Kangoo', consumption: 8),
          ],
        ),
      );
      final l = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(l.vehTripTitle, 'Comparer ce trajet');
      expect(find.text(l.vehTripCostToDriveLabel), findsNWidgets(2));
      expect(find.text(l.vehTripForecastNote), findsOneWidget);
    });
  });
}

class _FixedFuel extends SelectedFuelType {
  @override
  FuelType build() => FuelType.e10;
}

class _FixedIgnored extends IgnoredStations {
  _FixedIgnored(this._ids);
  final List<String> _ids;

  @override
  List<String> build() => _ids;
}

class _FixedRoute extends RouteSearchState {
  _FixedRoute(this._result);
  final RouteSearchResult? _result;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(_result);
}
