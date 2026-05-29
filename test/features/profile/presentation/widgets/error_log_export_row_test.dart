// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/features/profile/presentation/widgets/error_log_export_row.dart';

import '../../../../helpers/pump_app.dart';

/// TraceStorage that never touches Hive (#2248).
class _StubTraceStorage extends TraceStorage {
  _StubTraceStorage({
    this.stubCount = 0,
    this.stubParsedCount = 0,
    this.stubExport = '{"traceCount":0,"traces":[]}',
  });

  final int stubCount;
  final int stubParsedCount;
  final String stubExport;

  @override
  int get count => stubCount;

  @override
  int get parsedCount => stubParsedCount;

  @override
  int get unparsedCount => 0;

  @override
  String exportAsJson() => stubExport;

  bool clearAllCalled = false;

  @override
  Future<void> clearAll() async {
    clearAllCalled = true;
  }
}

void main() {
  group('ErrorLogExportRow (#2248 shared export)', () {
    setUp(() {
      // The widget routes catches through errorLogger; silence it in tests.
      errorLogger.spoolEnqueueOverride = ({
        required String isolateTaskName,
        required Object error,
        StackTrace? stack,
        Map<String, dynamic>? contextMap,
        DateTime? timestamp,
      }) async {};
      addTearDown(errorLogger.resetForTest);
    });

    void wireClipboard(WidgetTester tester) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall call) async => null);
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });
    }

    testWidgets('renders the save + clear buttons; clear disabled when empty',
        (tester) async {
      await pumpApp(
        tester,
        const ErrorLogExportRow(),
        overrides: [
          traceStorageProvider.overrideWithValue(_StubTraceStorage()),
        ],
      );

      expect(find.byKey(const ValueKey('error-log-export-button')),
          findsOneWidget);
      final clear = tester.widget<IconButton>(
        find.byKey(const ValueKey('error-log-clear-button')),
      );
      expect(clear.onPressed, isNull,
          reason: 'clear is disabled while the buffer is empty');
      // No View button unless onView is wired.
      expect(find.byKey(const ValueKey('error-log-view-button')),
          findsNothing);
    });

    testWidgets('shows the View button when onView is provided',
        (tester) async {
      await pumpApp(
        tester,
        ErrorLogExportRow(onView: () {}),
        overrides: [
          traceStorageProvider.overrideWithValue(_StubTraceStorage()),
        ],
      );

      expect(find.byKey(const ValueKey('error-log-view-button')),
          findsOneWidget);
    });

    // #2236 regression — the large-log path must write to Downloads
    // exactly ONCE. With no share sink wired (production behaviour) the
    // share-seam is a no-op and the single save is owned by the caller.
    testWidgets('large JSON path writes to Downloads exactly once',
        (tester) async {
      wireClipboard(tester);

      var saveCalls = 0;
      final savedNames = <String>[];
      debugPublicFileExporterOverride = ({
        required bytes,
        required fileName,
        required mimeType,
      }) async {
        saveCalls++;
        savedNames.add(fileName);
        return '/Downloads/$fileName';
      };
      addTearDown(() => debugPublicFileExporterOverride = null);

      final bigPayload = '{"traceCount":1,"big":"${'x' * (80 * 1024)}"}';
      await pumpApp(
        tester,
        const ErrorLogExportRow(),
        overrides: [
          traceStorageProvider.overrideWithValue(
            _StubTraceStorage(
              stubCount: 1,
              stubParsedCount: 1,
              stubExport: bigPayload,
            ),
          ),
        ],
      );

      await tester.tap(find.byKey(const ValueKey('error-log-export-button')));
      await tester.pumpAndSettle();

      expect(saveCalls, 1,
          reason: 'the large error-log export must write the Downloads '
              'file exactly once, not twice (#2236)');
      expect(savedNames, ['tankstellen-error-log.json']);
    });

    testWidgets('clear button invokes clearAll when the buffer is non-empty',
        (tester) async {
      wireClipboard(tester);
      final stub = _StubTraceStorage(stubCount: 3, stubParsedCount: 3);
      await pumpApp(
        tester,
        const ErrorLogExportRow(),
        overrides: [
          traceStorageProvider.overrideWithValue(stub),
        ],
      );

      await tester.tap(find.byKey(const ValueKey('error-log-clear-button')));
      await tester.pumpAndSettle();

      expect(stub.clearAllCalled, isTrue);
    });
  });
}
