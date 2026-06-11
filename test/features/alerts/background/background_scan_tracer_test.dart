// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/alerts/background/background_scan_tracer.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// #2933 (error-log #25) part B — the background tracer's Downloads export
/// must NOT crash / spool an ERROR when the `tankstellen/public_files` platform
/// channel is unavailable in a WorkManager background isolate.
///
/// Field stack: `BackgroundScanTracer.exportIfEnabled` →
/// `DataAccessTraceExport.export` → `PublicFileExporter.saveBytesToDownloads`
/// → MethodChannel `tankstellen/public_files` → `MissingPluginException` (no
/// plugin registrant in the background isolate). The export is a foreground
/// sink; the fix skips it in the background isolate and degrades a stray
/// channel fault to a no-op instead of an ERROR trace.
class _CapturingRecorder implements TraceRecorder {
  final errors = <Object>[];
  @override
  Future<void> record(Object error, StackTrace stackTrace,
          {ServiceChainSnapshot? serviceChainState}) async =>
      errors.add(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;
  late _CapturingRecorder rec;

  // i18n-ignore: Hive box name, not user-facing.
  const boxName = 'feature_flags';
  // i18n-ignore: storage key (Feature.debugMode.name), not user-facing.
  const debugModeKey = 'debugMode';

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_bg_tracer_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    errorLogger.resetForTest();
    rec = _CapturingRecorder();
    errorLogger.testRecorderOverride = rec;
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<dynamic>(boxName);
    }
    // Developer mode ON so `forScan()` returns a TRACING tracer (recorder
    // non-null) — the precondition for the export path to be reached at all.
    await Hive.box<dynamic>(boxName).put(debugModeKey, true);
  });

  tearDown(() async {
    errorLogger.resetForTest();
    debugIsBackgroundIsolateOverride = null;
    debugPublicFileExporterOverride = null;
    if (Hive.isBoxOpen(boxName)) await Hive.box<dynamic>(boxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('forScan with developer mode on yields a tracing tracer', () {
    final tracer = BackgroundScanTracer.forScan();
    expect(tracer.isTracing, isTrue,
        reason: 'the feature_flags box has debugMode=true');
  });

  test(
      'in a BACKGROUND isolate, exportIfEnabled SKIPS the Downloads export '
      'without spooling an ERROR or rethrowing (#2933)', () async {
    debugIsBackgroundIsolateOverride = true;
    var saverCalls = 0;
    debugPublicFileExporterOverride = ({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
    }) async {
      saverCalls++;
      return 'fake://Downloads/$fileName';
    };

    final tracer = BackgroundScanTracer.forScan();

    // Must complete normally (never-throws contract for the background path).
    await tracer.exportIfEnabled();
    await Future<void>.delayed(Duration.zero);

    expect(saverCalls, 0,
        reason: 'the foreground-only Downloads sink is skipped in the '
            'background isolate');
    expect(rec.errors, isEmpty,
        reason: 'skipping the unavailable channel must NOT spool a background '
            'ERROR — the field MissingPluginException flood');
  });

  test(
      'when the public_files channel throws MissingPluginException, '
      'exportIfEnabled degrades to a skip — no ERROR, no rethrow (#2933)',
      () async {
    // Force the FOREGROUND branch so the export path actually calls the saver,
    // then make the saver throw the exact field exception.
    debugIsBackgroundIsolateOverride = false;
    debugPublicFileExporterOverride = ({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
    }) async {
      throw MissingPluginException(
        'No implementation found for method saveBytes on channel '
        'tankstellen/public_files',
      );
    };

    final tracer = BackgroundScanTracer.forScan();

    // The never-throws contract: the injected channel fault must not surface.
    await expectLater(tracer.exportIfEnabled(), completes);
    await Future<void>.delayed(Duration.zero);

    expect(rec.errors, isEmpty,
        reason: 'a MissingPluginException from an unregistered channel must '
            'degrade to a skip, not an ERROR trace');
  });

  test(
      'in the FOREGROUND with a working channel, exportIfEnabled STILL saves '
      'to Downloads (the guard does not break the real export)', () async {
    debugIsBackgroundIsolateOverride = false;
    var saverCalls = 0;
    String? savedName;
    debugPublicFileExporterOverride = ({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
    }) async {
      saverCalls++;
      savedName = fileName;
      return 'fake://Downloads/$fileName';
    };

    final tracer = BackgroundScanTracer.forScan();

    await tracer.exportIfEnabled();
    await Future<void>.delayed(Duration.zero);

    expect(saverCalls, 1,
        reason: 'the foreground path still writes the trace to Downloads');
    expect(savedName, contains('tankstellen-dataaccess-'));
    expect(rec.errors, isEmpty);
  });

  test('a non-tracing tracer (developer mode off) is a no-op', () async {
    await Hive.box<dynamic>(boxName).put(debugModeKey, false);
    debugIsBackgroundIsolateOverride = false;
    var saverCalls = 0;
    debugPublicFileExporterOverride = ({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
    }) async {
      saverCalls++;
      return '';
    };

    final tracer = BackgroundScanTracer.forScan();
    expect(tracer.isTracing, isFalse);

    await tracer.exportIfEnabled();
    expect(saverCalls, 0);
    expect(rec.errors, isEmpty);
  });
}
