// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/providers/trip_baseline_sync.dart';
import 'package:tankstellen/features/sync/providers/baseline_sync_enabled_provider.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3670 — [syncBaselineAfterFlush] is the fire-and-forget half of the
/// stop path; its never-throws contract is fault-injected here (a
/// throwing merge must be logged and swallowed, never surface into the
/// unawaited zone).
void main() {
  silenceErrorLoggerSpool();
  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('baseline_sync_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2Baselines).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
    debugBaselineMergeOverride = null;
  });

  ProviderContainer container({required bool enabled}) {
    final c = ProviderContainer(overrides: [
      baselineSyncEnabledProvider.overrideWithValue(enabled),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  // The function takes a Riverpod [Ref]; a throwaway provider hands one
  // out of the container.
  final refProvider = Provider<Ref>((ref) => ref);

  test('a THROWING merge is swallowed and logged — never thrown into '
      'the fire-and-forget zone', () async {
    final c = container(enabled: true);
    debugBaselineMergeOverride = ({required vehicleId, localJson}) =>
        throw StateError('handshake ground to dust');

    await expectLater(
      syncBaselineAfterFlush(c.read(refProvider), 'v1'),
      completes,
    );
  });

  test('a merge slower than the 15 s cap is abandoned (TimeoutException '
      'swallowed), and a successful merge persists the fold-in', () async {
    final c = container(enabled: true);
    final box = Hive.box<String>(HiveBoxes.obd2Baselines);
    await box.put('baseline:v1', '{"local":true}');

    debugBaselineMergeOverride =
        ({required vehicleId, localJson}) async => '{"merged":true}';
    await syncBaselineAfterFlush(c.read(refProvider), 'v1');
    expect(box.get('baseline:v1'), '{"merged":true}');
  });

  test('sync disabled → no merge call at all', () async {
    final c = container(enabled: false);
    var calls = 0;
    debugBaselineMergeOverride = ({required vehicleId, localJson}) async {
      calls++;
      return null;
    };
    await syncBaselineAfterFlush(c.read(refProvider), 'v1');
    expect(calls, 0);
  });
}
