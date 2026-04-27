import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_detail_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// #890 — the Trajets detail screen renders the full recording
/// profile (speed / fuel-rate / RPM) plus a summary card, share +
/// delete actions. These tests seed the screen with a known trip and
/// a 100-sample profile and assert on the rendered widgets.

class _FixedTripHistoryList extends TripHistoryList {
  final List<TripHistoryEntry> _value;
  int deleteCallCount = 0;
  String? lastDeletedId;

  _FixedTripHistoryList(this._value);

  @override
  List<TripHistoryEntry> build() => _value;

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    lastDeletedId = id;
  }
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  final VehicleProfile? _value;
  _FixedActiveVehicle(this._value);

  @override
  VehicleProfile? build() => _value;
}

class _FixedVehicleProfileList extends VehicleProfileList {
  final List<VehicleProfile> _value;
  _FixedVehicleProfileList(this._value);

  @override
  List<VehicleProfile> build() => _value;
}

/// Seeded trip with 100 samples spanning 1 hour: speed ramp 0→99
/// km/h, fuel rate modulated between 3–7 L/h, RPM 700–3500.
List<TripDetailSample> _seedSamples({int count = 100}) {
  final base = DateTime.utc(2026, 4, 22, 10, 0);
  final samples = <TripDetailSample>[];
  for (var i = 0; i < count; i++) {
    samples.add(
      TripDetailSample(
        timestamp: base.add(Duration(seconds: i * 36)),
        speedKmh: i.toDouble(),
        rpm: 700 + (i * 28.0),
        fuelRateLPerHour: 3 + (i % 5),
      ),
    );
  }
  return samples;
}

TripHistoryEntry _seedEntry({
  String id = 'trip-1',
  String? vehicleId = 'v1',
  DateTime? startedAt,
  Duration duration = const Duration(hours: 1),
  double distanceKm = 52.5,
  double? avgLPer100Km = 6.4,
  double? fuelLitersConsumed = 3.36,
  double maxRpm = 3500,
}) {
  final start = startedAt ?? DateTime.utc(2026, 4, 22, 10, 0);
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: TripSummary(
      distanceKm: distanceKm,
      maxRpm: maxRpm,
      highRpmSeconds: 120,
      idleSeconds: 30,
      harshBrakes: 1,
      harshAccelerations: 2,
      avgLPer100Km: avgLPer100Km,
      fuelLitersConsumed: fuelLitersConsumed,
      startedAt: start,
      endedAt: start.add(duration),
    ),
  );
}

Future<({_FixedTripHistoryList tripsNotifier})> _pumpDetail(
  WidgetTester tester, {
  required TripHistoryEntry entry,
  VehicleProfile? activeVehicle,
  List<VehicleProfile> vehicles = const [],
  List<TripDetailSample> samples = const [],
}) async {
  final tripsNotifier = _FixedTripHistoryList([entry]);
  final router = GoRouter(
    // Start on a stub route and push the detail screen on top so
    // `context.pop()` inside the screen has something to pop back to
    // (mimics the real nav stack: Trajets tab → Trip detail).
    initialLocation: '/trajets-stub',
    routes: [
      GoRoute(
        path: '/trajets-stub',
        builder: (_, _) => const Scaffold(
          key: Key('trajets-stub'),
          body: Text('TrajetsStub'),
        ),
      ),
      GoRoute(
        path: '/trip/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return TripDetailScreen(tripId: id, samples: samples);
        },
      ),
    ],
  );
  await pumpApp(
    tester,
    MaterialApp.router(routerConfig: router),
    overrides: [
      tripHistoryListProvider.overrideWith(() => tripsNotifier),
      activeVehicleProfileProvider
          .overrideWith(() => _FixedActiveVehicle(activeVehicle)),
      vehicleProfileListProvider
          .overrideWith(() => _FixedVehicleProfileList(vehicles)),
      // #1194 — TripDetailBody now reads gamificationEnabledProvider;
      // override here so it doesn't fall through to the (Hive-backed)
      // active profile lookup that these tests don't seed.
      gamificationEnabledProvider.overrideWith((ref) => true),
    ],
  );
  // Push the detail route on top of the stub so `context.pop()` in
  // the screen has a parent to pop back to. This mirrors the real
  // flow where the user lands on Trajets and taps a row to push the
  // detail.
  unawaited(router.push('/trip/${entry.id}'));
  await tester.pumpAndSettle();
  return (tripsNotifier: tripsNotifier);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vehicle = VehicleProfile(
    id: 'v1',
    name: 'Peugeot 308',
    type: VehicleType.combustion,
  );

  group('TripDetailScreen summary card (#890)', () {
    testWidgets('renders all 8 summary fields for a seeded trip', (tester) async {
      final samples = _seedSamples();
      final entry = _seedEntry();
      await _pumpDetail(
        tester,
        entry: entry,
        activeVehicle: vehicle,
        vehicles: const [vehicle],
        samples: samples,
      );
      await tester.pumpAndSettle();

      // Each of the 8 summary fields renders its label exactly once
      // inside the summary card.
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Vehicle'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Avg consumption'), findsOneWidget);
      expect(find.text('Fuel used'), findsOneWidget);
      expect(find.text('Avg speed'), findsOneWidget);
      expect(find.text('Max speed'), findsOneWidget);

      // A handful of value strings — sanity check that the formatters
      // actually wire up to the summary and samples.
      expect(find.text('Peugeot 308'), findsOneWidget);
      expect(find.text('52.5 km'), findsOneWidget);
      expect(find.text('1h 0m'), findsOneWidget);
      expect(find.text('6.4 L/100 km'), findsOneWidget);
      expect(find.text('3.36 L'), findsOneWidget);
      // Avg speed of 0..99 => 49.5 km/h; max speed => 99.0 km/h.
      expect(find.text('49.5 km/h'), findsOneWidget);
      expect(find.text('99.0 km/h'), findsOneWidget);
    });
  });

  group('TripDetailScreen charts (#890)', () {
    testWidgets(
      'speed chart present and no exceptions when rpm samples empty',
      (tester) async {
        // 100 samples with rpm=null on every one — the speed chart
        // still renders, the RPM chart is hidden.
        final samples = [
          for (var i = 0; i < 100; i++)
            TripDetailSample(
              timestamp: DateTime.utc(2026, 4, 22, 10).add(
                Duration(seconds: i),
              ),
              speedKmh: i.toDouble(),
              fuelRateLPerHour: 4.5,
            ),
        ];
        await _pumpDetail(
          tester,
          entry: _seedEntry(),
          activeVehicle: vehicle,
          vehicles: const [vehicle],
          samples: samples,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byType(TripDetailSpeedChart, skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.byType(TripDetailFuelRateChart, skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.byType(TripDetailRpmChart, skipOffstage: false),
          findsNothing,
        );
      },
    );

    testWidgets(
      'RPM chart hidden when every sample carries a null RPM',
      (tester) async {
        final samples = [
          for (var i = 0; i < 5; i++)
            TripDetailSample(
              timestamp: DateTime.utc(2026, 4, 22, 10).add(
                Duration(seconds: i),
              ),
              speedKmh: 40 + i.toDouble(),
            ),
        ];
        await _pumpDetail(
          tester,
          entry: _seedEntry(),
          activeVehicle: vehicle,
          vehicles: const [vehicle],
          samples: samples,
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(TripDetailRpmChart, skipOffstage: false),
          findsNothing,
        );
      },
    );

    testWidgets(
      'RPM chart appears when at least one sample carries a non-null RPM',
      (tester) async {
        final samples = [
          TripDetailSample(
            timestamp: DateTime.utc(2026, 4, 22, 10),
            speedKmh: 20,
            rpm: 1500,
          ),
          TripDetailSample(
            timestamp: DateTime.utc(2026, 4, 22, 10, 0, 1),
            speedKmh: 22,
            rpm: 1700,
          ),
        ];
        await _pumpDetail(
          tester,
          entry: _seedEntry(),
          activeVehicle: vehicle,
          vehicles: const [vehicle],
          samples: samples,
        );
        await tester.pumpAndSettle();
        // The RPM chart is the third section in the ListView; on the
        // default 600-px test surface it may not yet be laid out.
        // `skipOffstage: false` walks the full element tree so we can
        // assert on widgets that exist-but-are-below-the-fold.
        expect(
          find.byType(TripDetailRpmChart, skipOffstage: false),
          findsOneWidget,
        );
      },
    );
  });

  group('TripDetailScreen Share action (#890)', () {
    testWidgets('Share copies JSON+CSV payload to clipboard', (tester) async {
      String? captured;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            captured =
                (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      final samples = _seedSamples();
      await _pumpDetail(
        tester,
        entry: _seedEntry(),
        activeVehicle: vehicle,
        vehicles: const [vehicle],
        samples: samples,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trip_detail_share_button')));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      // JSON summary + CSV block with one row per sample (+1 header).
      expect(captured, contains('"id": "trip-1"'));
      expect(captured, contains('timestamp,speedKmh,rpm,fuelRateLPerHour'));
      // CSV block starts at the header line and contains one row per
      // sample; split on the header to isolate the sample block so
      // the JSON-summary commas don't inflate the count.
      final csvBlock =
          captured!.split('timestamp,speedKmh,rpm,fuelRateLPerHour\n').last;
      final csvDataRows = csvBlock
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .length;
      expect(csvDataRows, 100);
      // Snackbar confirmation.
      expect(find.text('Copied to clipboard'), findsOneWidget);
    });
  });

  group('TripDetailScreen Delete action (#890)', () {
    testWidgets('confirm → delete called + pops back', (tester) async {
      final handles = await _pumpDetail(
        tester,
        entry: _seedEntry(),
        activeVehicle: vehicle,
        vehicles: const [vehicle],
        samples: _seedSamples(),
      );
      await tester.pumpAndSettle();

      // Tap delete → confirm.
      await tester.tap(find.byKey(const Key('trip_detail_delete_button')));
      await tester.pumpAndSettle();
      expect(find.text('Delete this trip?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('trip_detail_delete_confirm')));
      await tester.pumpAndSettle();

      expect(handles.tripsNotifier.deleteCallCount, 1);
      expect(handles.tripsNotifier.lastDeletedId, 'trip-1');
      // Screen popped back to the Trajets stub — the stub text is
      // visible and the detail screen's AppBar is gone.
      expect(find.text('TrajetsStub'), findsOneWidget);
      expect(
        find.byKey(const Key('trip_detail_delete_button')),
        findsNothing,
      );
    });

    testWidgets('cancel → delete NOT called', (tester) async {
      final handles = await _pumpDetail(
        tester,
        entry: _seedEntry(),
        activeVehicle: vehicle,
        vehicles: const [vehicle],
        samples: const [],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trip_detail_delete_button')));
      await tester.pumpAndSettle();
      // Dismiss via Cancel button.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(handles.tripsNotifier.deleteCallCount, 0);
      // Still on the detail screen — delete didn't fire and the
      // router wasn't popped.
      expect(
        find.byKey(const Key('trip_detail_delete_button')),
        findsOneWidget,
      );
    });
  });
}
