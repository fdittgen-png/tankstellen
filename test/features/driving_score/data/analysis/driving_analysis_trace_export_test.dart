// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/features/driving_score/data/analysis/driving_analysis_trace.dart';
import 'package:tankstellen/features/driving_score/data/analysis/driving_analysis_trace_export.dart';
import 'package:tankstellen/features/driving_score/domain/driving_score.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/domain/recording_session_journal.dart';
import 'package:tankstellen/features/obd2/data/diagnostics/obd2_diagnostic_recordings.dart';

TripSummary _summary() => const TripSummary(
  distanceKm: 12,
  maxRpm: 0,
  highRpmSeconds: 0,
  idleSeconds: 0,
  harshBrakes: 0,
  harshAccelerations: 0,
  kind: TripKind.gpsOnly,
);

DrivingAnalysisTrace _trace({String? diagnosticFile}) => DrivingAnalysisTrace(
  sessionJournal: diagnosticFile == null
      ? null
      : RecordingSessionJournal.fromJson({
          'ev': <Object?>[],
          'df': diagnosticFile,
        }),
  capturedAt: DateTime.utc(2026, 6, 3, 9, 30, 15),
  summary: _summary(),
  score: const DrivingScore(
    score: 80,
    idlingPenalty: 0,
    hardAccelPenalty: 0,
    hardBrakePenalty: 0,
    highRpmPenalty: 0,
    fullThrottlePenalty: 0,
  ),
  lessons: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<({String fileName, String mimeType, Uint8List bytes})> writes;

  setUp(() {
    writes = [];
    debugPublicFileExporterOverride =
        ({required bytes, required fileName, required mimeType}) async {
          writes.add((fileName: fileName, mimeType: mimeType, bytes: bytes));
          return 'content://downloads/$fileName';
        };
  });

  tearDown(() {
    debugPublicFileExporterOverride = null;
    Obd2DiagnosticRecordings.debugDirectoryOverride = null;
  });

  test(
    '#2817 — writes a stamped JSON FILE to Downloads and returns true',
    () async {
      final ok = await DrivingAnalysisTraceExport.export(_trace());

      expect(ok, isTrue);
      // Exactly one Downloads write — no share-sheet detour.
      expect(writes, hasLength(1));
      final write = writes.single;
      // Stamp derives from capturedAt with `:`/`.` swapped for `-`.
      expect(
        write.fileName,
        'tankstellen-driving-2026-06-03T09-30-15-000Z.json',
      );
      expect(write.mimeType, 'application/json');
      // The bytes are the pretty-printed, parseable trace JSON.
      final decoded = jsonDecode(utf8.decode(write.bytes));
      expect(decoded['kind'], 'drivingAnalysis');
      expect(decoded['comment'], kDrivingAnalysisCommentPrompt);
    },
  );

  test(
    'one exported JSON includes only its explicitly linked health trace',
    () async {
      final dir = await Directory.systemTemp.createTemp('health-export');
      addTearDown(() => dir.delete(recursive: true));
      Obd2DiagnosticRecordings.debugDirectoryOverride = dir;
      final name = Obd2DiagnosticRecordings.fileNameFor(DateTime.utc(2026));
      await File('${dir.path}/$name').writeAsString(
        [
          {'k': 'cmd', 't': 1000, 'c': '0106', 'r': '41 06 90'},
          {'k': 'cmd', 't': 2000, 'c': '0114', 'r': '41 14 80 FF'},
          {'k': 'cmd', 't': 3000, 'c': '03', 'r': '43 01 71 00 00'},
          {'k': 'mark', 'p': 'end'},
        ].map(jsonEncode).join('\n'),
      );
      final other = Obd2DiagnosticRecordings.fileNameFor(
        DateTime.utc(2026, 1, 2),
      );
      await File('${dir.path}/$other').writeAsString(
        jsonEncode({'k': 'cmd', 't': 1000, 'c': '03', 'r': '43 04 20 00 00'}),
      );
      expect(
        await DrivingAnalysisTraceExport.export(_trace(diagnosticFile: name)),
        isTrue,
      );
      final json = jsonDecode(utf8.decode(writes.single.bytes)) as Map;
      final health = json['vehicleHealth'] as Map;
      expect(json['schema'], 8);
      expect(health['status'], 'recorded');
      expect(health['completeTrace'], isTrue);
      expect(
        (health['signals'] as Map)['stftBank1'],
        containsPair('mean', 12.5),
      );
      expect(((health['faults'] as Map)['stored'] as Map)['observedCodes'], [
        'P0171',
      ]);
      final journal = RecordingSessionJournal.fromJson({
        'ev': <Object?>[],
        'df': name,
      });
      expect(
        RecordingSessionJournal.fromJson(
          journal.toJson(),
        ).diagnosticRecordingFile,
        name,
      );
    },
  );

  test(
    'legacy, deleted and invalid links preserve export with an honest reason',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'missing-health-export',
      );
      addTearDown(() => dir.delete(recursive: true));
      Obd2DiagnosticRecordings.debugDirectoryOverride = dir;
      for (final name in [
        null,
        '../secret',
        Obd2DiagnosticRecordings.fileNameFor(DateTime.utc(2026)),
      ]) {
        writes.clear();
        expect(
          await DrivingAnalysisTraceExport.export(_trace(diagnosticFile: name)),
          isTrue,
        );
        final json = jsonDecode(utf8.decode(writes.single.bytes)) as Map;
        expect((json['vehicleHealth'] as Map)['status'], 'unavailable');
        expect(
          (json['vehicleHealth'] as Map)['reason'],
          name != null && name.endsWith('.ndjson')
              ? 'expiredDeletedOrUnreadable'
              : 'notLinked',
        );
      }
    },
  );

  test('a Downloads-write failure returns false and does not throw', () async {
    debugPublicFileExporterOverride =
        ({required bytes, required fileName, required mimeType}) async =>
            throw const FileSystemException('no Downloads access');

    final ok = await DrivingAnalysisTraceExport.export(_trace());
    expect(ok, isFalse);
  });
}
