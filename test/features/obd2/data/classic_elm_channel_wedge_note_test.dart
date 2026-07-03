// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/classic_connect_cooldown.dart';
import 'package:tankstellen/features/obd2/data/classic_elm_channel.dart';
import 'package:tankstellen/features/obd2/data/classic_method_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_wedge_detector.dart';

import '../../../helpers/silence_error_logger.dart';

/// Fake plugin scripted per-call: each `connectDetailed` pops the next
/// result, so a test drives exhausted → exhausted → exhausted → success
/// through the REAL channel funnel that feeds the wedge detector (#3422).
class _ScriptedPlugin extends Obd2ClassicMethodChannel {
  _ScriptedPlugin(this.results);

  final List<ClassicConnectResult> results;
  int _idx = 0;

  final StreamController<List<int>> incomingController =
      StreamController<List<int>>.broadcast();

  @override
  Future<ClassicConnectResult> connectDetailed({
    required String address,
    required String uuid,
    int? budgetMs,
  }) async {
    final i = _idx < results.length ? _idx : results.length - 1;
    _idx++;
    return results[i];
  }

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<List<int>> get incoming => incomingController.stream;

  Future<void> dispose() async {
    if (!incomingController.isClosed) await incomingController.close();
  }
}

void main() {
  silenceErrorLoggerSpool();

  final detector = Obd2WedgeDetector.instance;

  setUp(detector.resetForTest);
  tearDown(detector.resetForTest);

  ClassicElmChannel channel(_ScriptedPlugin plugin) => ClassicElmChannel(
        address: 'AA:BB',
        plugin: plugin,
        // Fake clock/wait so the per-mac cooldown never sleeps real time.
        cooldown: ClassicConnectCooldown(
          now: () => DateTime.fromMillisecondsSinceEpoch(0),
          wait: (_) async {},
        ),
      );

  group('ClassicElmChannel feeds the wedge detector (#3422)', () {
    test('three consecutive exhausted ladder results — across three channel '
        'objects, as reconnect episodes create them — latch LinkWedged',
        () async {
      const exhausted = (ok: false, strategy: 'exhausted', error: 'read -1');
      final plugin = _ScriptedPlugin([exhausted]);
      addTearDown(plugin.dispose);

      for (var i = 0; i < 3; i++) {
        // Every attempt uses a FRESH short-lived channel — the streak must
        // survive across them (the detector is process-wide).
        await expectLater(
          channel(plugin).open(),
          throwsA(isA<Obd2AdapterUnresponsive>()),
        );
      }
      expect(detector.isWedged, isTrue);
      expect(detector.wedgedMac, 'AA:BB');
    });

    test('a budget-exhausted result carries the wedge signature too',
        () async {
      const budget = (ok: false, strategy: 'budget-exhausted', error: null);
      final plugin = _ScriptedPlugin([budget]);
      addTearDown(plugin.dispose);

      for (var i = 0; i < 3; i++) {
        await expectLater(
          channel(plugin).open(),
          throwsA(isA<Obd2AdapterUnresponsive>()),
        );
      }
      expect(detector.isWedged, isTrue);
    });

    test('a successful open resets the streak (no wedge on flaky-but-alive '
        'links)', () async {
      const exhausted = (ok: false, strategy: 'exhausted', error: null);
      const success = (ok: true, strategy: 'secure', error: null);
      final plugin =
          _ScriptedPlugin([exhausted, exhausted, success, exhausted]);
      addTearDown(plugin.dispose);

      await expectLater(
          channel(plugin).open(), throwsA(isA<Obd2AdapterUnresponsive>()));
      await expectLater(
          channel(plugin).open(), throwsA(isA<Obd2AdapterUnresponsive>()));
      final live = channel(plugin);
      await live.open(); // success → streak reset
      await live.close();
      await expectLater(
          channel(plugin).open(), throwsA(isA<Obd2AdapterUnresponsive>()));

      expect(detector.isWedged, isFalse);
      expect(detector.streak, 1);
    });
  });
}
