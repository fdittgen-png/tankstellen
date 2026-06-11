// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_detail_downloads.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_detail_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/providers/trip_fuel_cost_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import '../../../../helpers/silence_error_logger.dart';

import '../../../../helpers/pump_app.dart';

/// #890 — the Trajets detail screen renders the full recording
/// profile (speed / fuel-rate / RPM) plus a summary card, share +
/// delete actions. These tests seed the screen with a known trip and
/// a 100-sample profile and assert on the rendered widgets.

class _FixedTripHistoryList extends TripHistoryList {
  final List<TripHistoryEntry> _value;
  int deleteCallCount = 0;
  String? lastDeletedId;
  final List<TripHistoryEntry> saveCalls = [];

  _FixedTripHistoryList(this._value);

  @override
  List<TripHistoryEntry> build() => _value;

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    lastDeletedId = id;
  }

  @override
  Future<void> save(TripHistoryEntry entry) async {
    saveCalls.add(entry);
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
      // override here so it doesn't fall through to the central
      // featureFlagsProvider chain that these tests don't seed.
      gamificationEnabledProvider.overrideWithValue(true),
      // #1209 — TripSummaryCard now watches tripFuelCostProvider, which
      // composes fillUpListProvider (Hive-backed). These tests don't
      // seed Hive; return null so the cost row hides cleanly.
      tripFuelCostProvider(entry.id).overrideWith((ref) => null),
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
  silenceErrorLoggerSpool();
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

  group('TripDetailScreen Share action (#1189)', () {
    tearDown(() {
      debugTripDetailShareOverride = null;
    });

    testWidgets(
      'Share invokes the renderer with the boundary key + localised subject',
      (tester) async {
        GlobalKey? capturedKey;
        String? capturedSubject;
        String? capturedFileNameStem;
        debugTripDetailShareOverride = ({
          required GlobalKey boundaryKey,
          required String subject,
          required String fileNameStem,
        }) async {
          capturedKey = boundaryKey;
          capturedSubject = subject;
          capturedFileNameStem = fileNameStem;
        };

        final samples = _seedSamples();
        await _pumpDetail(
          tester,
          entry: _seedEntry(),
          activeVehicle: vehicle,
          vehicles: const [vehicle],
          samples: samples,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('trip_detail_share_menu')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('trip_detail_share_image_option')),
        );
        await tester.pumpAndSettle();

        expect(capturedKey, isNotNull,
            reason: 'share renderer was not invoked');
        expect(capturedKey!.currentContext, isNotNull,
            reason: 'boundary key must point at a mounted widget so the '
                'real renderer can rasterise it');
        // The subject template is "Sparkilo — trip on {date}" in
        // English (the trip's startedAt is 2026-04-22). Verify the
        // brand + the year ended up in the share subject.
        expect(capturedSubject, isNotNull);
        expect(capturedSubject, contains('Sparkilo'));
        expect(capturedSubject, contains('2026'));
        expect(capturedFileNameStem, 'tankstellen_trip_trip-1');
        // Should NOT be a clipboard snackbar — make sure no legacy
        // path leaked through.
        expect(find.text('Copied to clipboard'), findsNothing);
      },
    );

    testWidgets(
      'Share works with empty samples (no chart crash, still hands off PNG)',
      (tester) async {
        var rendererCalled = false;
        debugTripDetailShareOverride = ({
          required GlobalKey boundaryKey,
          required String subject,
          required String fileNameStem,
        }) async {
          rendererCalled = true;
          // The empty-samples body must still produce a render-target
          // boundary, otherwise the production renderer would throw.
          expect(boundaryKey.currentContext, isNotNull,
              reason: 'empty-samples body must mount the share boundary');
        };

        await _pumpDetail(
          tester,
          entry: _seedEntry(),
          activeVehicle: vehicle,
          vehicles: const [vehicle],
          samples: const [],
        );
        await tester.pumpAndSettle();

        // No exception during build with the empty-samples placeholder.
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('trip_detail_share_menu')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('trip_detail_share_image_option')),
        );
        await tester.pumpAndSettle();

        expect(rendererCalled, isTrue,
            reason: 'share renderer must run even when samples are empty');
      },
    );

    testWidgets(
      'Share surfaces a snackbar when the renderer throws',
      (tester) async {
        debugTripDetailShareOverride = ({
          required GlobalKey boundaryKey,
          required String subject,
          required String fileNameStem,
        }) async {
          throw StateError('boom');
        };

        await _pumpDetail(
          tester,
          entry: _seedEntry(),
          activeVehicle: vehicle,
          vehicles: const [vehicle],
          samples: _seedSamples(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('trip_detail_share_menu')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('trip_detail_share_image_option')),
        );
        await tester.pumpAndSettle();

        // The error snackbar surfaces — exact message is the EN
        // fallback because the test pumps the default locale.
        expect(
          find.text("Couldn't generate share image"),
          findsOneWidget,
        );
      },
    );
  });

  group('TripDetailScreen telemetry download (#2652)', () {
    tearDown(() {
      debugTripDetailDownloadOverride = null;
      debugPublicFileExporterOverride = null;
    });

    // An entry whose `entry.samples` is non-empty so the download
    // handler doesn't short-circuit on the empty-trip guard.
    TripHistoryEntry entryWithSamples() {
      final start = DateTime.utc(2026, 4, 22, 10, 0);
      return TripHistoryEntry(
        id: 'trip-1',
        vehicleId: 'v1',
        summary: TripSummary(
          distanceKm: 52.5,
          maxRpm: 3500,
          highRpmSeconds: 120,
          idleSeconds: 30,
          harshBrakes: 1,
          harshAccelerations: 2,
          avgLPer100Km: 6.4,
          fuelLitersConsumed: 3.36,
          startedAt: start,
          endedAt: start.add(const Duration(hours: 1)),
        ),
        samples: [
          TripSample(timestamp: start, speedKmh: 30, rpm: 1500),
          TripSample(
            timestamp: start.add(const Duration(seconds: 1)),
            speedKmh: 32,
            rpm: 1700,
          ),
        ],
      );
    }

    testWidgets('CSV item saves a .csv file with text/csv mime + success',
        (tester) async {
      String? capturedFileName;
      String? capturedMime;
      String? capturedText;
      debugTripDetailDownloadOverride = ({
        required String text,
        required String fileName,
        required String mimeType,
      }) async {
        capturedText = text;
        capturedFileName = fileName;
        capturedMime = mimeType;
      };

      await _pumpDetail(
        tester,
        entry: entryWithSamples(),
        activeVehicle: vehicle,
        vehicles: const [vehicle],
        samples: _seedSamples(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trip_detail_share_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('trip_detail_download_csv_option')));
      await tester.pumpAndSettle();

      // The test seam captures the save call (and returns before the
      // production snackbar, mirroring debugTripDetailGpxShareOverride).
      expect(capturedMime, 'text/csv');
      expect(capturedFileName, endsWith('.csv'));
      expect(capturedFileName, 'tankstellen-trajet-20260422T1000.csv');
      expect(capturedText, isNotNull);
      expect(capturedText, contains('timestamp_iso8601'));
    });

    testWidgets('JSON item saves a .json file with application/json mime',
        (tester) async {
      String? capturedFileName;
      String? capturedMime;
      String? capturedText;
      debugTripDetailDownloadOverride = ({
        required String text,
        required String fileName,
        required String mimeType,
      }) async {
        capturedText = text;
        capturedFileName = fileName;
        capturedMime = mimeType;
      };

      await _pumpDetail(
        tester,
        entry: entryWithSamples(),
        activeVehicle: vehicle,
        vehicles: const [vehicle],
        samples: _seedSamples(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trip_detail_share_menu')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('trip_detail_download_json_option')));
      await tester.pumpAndSettle();

      expect(capturedMime, 'application/json');
      expect(capturedFileName, endsWith('.json'));
      expect(capturedFileName, 'tankstellen-trajet-20260422T1000.json');
      expect(capturedText, contains('"samples"'));
    });

    testWidgets('successful save surfaces the Downloads-folder snackbar',
        (tester) async {
      // Drive the FULL handler (no high-level download override) through
      // the low-level PublicFileExporter seam so the success snackbar
      // fires — the path the high-level override returns before.
      debugPublicFileExporterOverride = ({
        required bytes,
        required fileName,
        required mimeType,
      }) async =>
          '/tmp/$fileName';

      await _pumpDetail(
        tester,
        entry: entryWithSamples(),
        activeVehicle: vehicle,
        vehicles: const [vehicle],
        samples: _seedSamples(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trip_detail_share_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('trip_detail_download_csv_option')));
      await tester.pumpAndSettle();

      expect(find.text('Saved to your Downloads folder'), findsOneWidget);
    });

    testWidgets('empty-samples trip short-circuits with the empty message',
        (tester) async {
      var saverCalled = false;
      debugTripDetailDownloadOverride = ({
        required String text,
        required String fileName,
        required String mimeType,
      }) async {
        saverCalled = true;
      };

      // _seedEntry has no entry.samples — the handler must not save.
      await _pumpDetail(
        tester,
        entry: _seedEntry(),
        activeVehicle: vehicle,
        vehicles: const [vehicle],
        samples: _seedSamples(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trip_detail_share_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('trip_detail_download_csv_option')));
      await tester.pumpAndSettle();

      expect(saverCalled, isFalse, reason: 'empty trip must not write a file');
      expect(find.text('No GPS samples in this trip'), findsOneWidget);
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

  group('TripDetailScreen lazy-fetch (#1541 phase 4)', () {
    tearDown(() {
      debugTripDetailFetchDetailsOverride = null;
    });

    testWidgets(
      'entry with empty samples triggers fetchDetails and saves the merged '
      'entry back to the history notifier',
      (tester) async {
        // Capture the trip-id the fetcher gets called with so we can
        // prove the screen wires the local entry's id (and not, say,
        // a constant) into the lazy fetch.
        String? fetchedTripId;
        debugTripDetailFetchDetailsOverride = (tripId) async {
          fetchedTripId = tripId;
          return {
            'samples': [
              {
                't': DateTime.utc(2026, 5, 11, 12).millisecondsSinceEpoch,
                's': 42.0,
                'r': 1200.0,
              },
            ],
            'gpsd': const <dynamic>[],
          };
        };

        final entry = _seedEntry(id: 'server-only-trip');
        // The entry comes from the merge pass — summary populated,
        // samples + gpsd empty (live in trip_details, not yet fetched).
        expect(entry.samples, isEmpty);
        expect(entry.gpsSampleDiagnostics, isEmpty);

        final handles = await _pumpDetail(
          tester,
          entry: entry,
          activeVehicle: vehicle,
          vehicles: const [vehicle],
        );
        // Drain the post-frame callback that schedules the lazy fetch.
        await tester.pumpAndSettle();

        expect(fetchedTripId, 'server-only-trip');
        expect(handles.tripsNotifier.saveCalls, hasLength(1));
        final saved = handles.tripsNotifier.saveCalls.single;
        expect(saved.id, entry.id);
        expect(saved.samples, hasLength(1),
            reason: 'merged entry must carry the fetched samples so a '
                'subsequent mount renders the charts from local cache');
        expect(saved.samples.single.speedKmh, 42.0);
      },
    );

    testWidgets(
      'entry that already has samples skips the lazy fetch '
      '(no wasted round-trip)',
      (tester) async {
        var fetchCalls = 0;
        debugTripDetailFetchDetailsOverride = (tripId) async {
          fetchCalls++;
          return null;
        };

        // Seed the entry with a non-empty samples list — mirrors the
        // happy path where the trip was recorded on this device and
        // the per-tick blob is already on disk.
        final start = DateTime.utc(2026, 5, 11, 12);
        final entry = TripHistoryEntry(
          id: 'local-trip',
          vehicleId: 'v1',
          summary: TripSummary(
            startedAt: start,
            endedAt: start.add(const Duration(minutes: 20)),
            distanceKm: 10,
            maxRpm: 2500,
            highRpmSeconds: 0,
            idleSeconds: 0,
            harshBrakes: 0,
            harshAccelerations: 0,
          ),
          samples: [
            TripSample(
              timestamp: start,
              speedKmh: 30,
              rpm: 1500,
            ),
          ],
        );

        final handles = await _pumpDetail(
          tester,
          entry: entry,
          activeVehicle: vehicle,
          vehicles: const [vehicle],
        );
        await tester.pumpAndSettle();

        expect(fetchCalls, 0,
            reason: 'an entry with local samples must short-circuit '
                'before the post-frame fetch fires');
        expect(handles.tripsNotifier.saveCalls, isEmpty);
      },
    );
  });
}
