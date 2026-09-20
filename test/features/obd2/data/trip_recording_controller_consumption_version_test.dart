// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4330 (#4233 follow-up) — `_finaliseSummary` stamps the consumption
// model version. Every trip this method finalises — an OBD2 measured or
// estimated one, a grace-window expiry, a recovered snapshot, a paused
// recovery — used to persist `cmv: null`, so a figure the fuzzy stage
// produced arrived at the contract with no provenance at all.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/trip_consumption_provenance.dart';

import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();
  late Directory tmpDir;
  late Box<String> pausedBox;
  late Box<String> historyBox;
  late PausedTripRepository pausedRepo;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('cmv_finalise_');
    Hive.init(tmpDir.path);
    pausedBox = await Hive.openBox<String>('paused');
    historyBox = await Hive.openBox<String>('history');
    pausedRepo = PausedTripRepository(box: pausedBox);
    historyRepo = TripHistoryRepository(box: historyBox);
  });

  tearDown(() async {
    await pausedBox.deleteFromDisk();
    await historyBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  /// A bare ELM that answers the init handshake and nothing else — the
  /// samples come from `debugInjectSample`, deterministically.
  Map<String, String> initResponses() => {
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': 'NO DATA>',
      };

  Future<TripRecordingController> start() async {
    final transport = FakeObd2Transport(initResponses());
    await transport.connect();
    final ctl = TripRecordingController(
      service: Obd2Service(transport),
      pollInterval: const Duration(minutes: 1), // no background ticks
      vehicleId: 'v1',
      pausedRepo: pausedRepo,
      historyRepo: historyRepo,
    );
    await ctl.start();
    return ctl;
  }

  test('a trip with a fuel figure finalises WITH a version stamp',
      () async {
    final ctl = await start();
    final t0 = DateTime.utc(2026, 9, 18, 8);
    for (var i = 0; i < 20; i++) {
      ctl.debugInjectSample(
        speedKmh: 72,
        rpm: 2100,
        fuelRateLPerHour: 4.8,
        at: t0.add(Duration(seconds: i)),
      );
    }

    final summary = await ctl.stop();

    expect(summary.fuelLitersConsumed, isNotNull,
        reason: 'precondition: the recorder integrated a figure');
    expect(summary.consumptionVersion, isNotNull,
        reason: '#4330 — the figure carries the model it came out of');
    expect(summary.consumptionVersion, tripConsumptionVersion(),
        reason: 'the one production engine version, not a local literal');
  });

  test('a trip with no fuel figure at all stays unstamped', () async {
    final ctl = await start();
    final t0 = DateTime.utc(2026, 9, 18, 8);
    for (var i = 0; i < 20; i++) {
      ctl.debugInjectSample(
        speedKmh: 72,
        rpm: 2100,
        at: t0.add(Duration(seconds: i)),
      );
    }

    final summary = await ctl.stop();

    expect(summary.fuelLitersConsumed, isNull);
    expect(summary.avgLPer100Km, isNull);
    expect(summary.consumptionVersion, isNull,
        reason: 'a version on nothing would be provenance for nothing');
  });
}
