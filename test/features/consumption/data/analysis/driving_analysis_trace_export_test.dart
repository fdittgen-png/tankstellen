// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/features/consumption/data/analysis/driving_analysis_trace.dart';
import 'package:tankstellen/features/consumption/data/analysis/driving_analysis_trace_export.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';

TripSummary _summary() => const TripSummary(
      distanceKm: 12,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      kind: TripKind.gpsOnly,
    );

DrivingAnalysisTrace _trace() => DrivingAnalysisTrace(
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

  late Directory tempDir;
  late List<({String fileName, String mimeType, Uint8List bytes})> writes;
  late List<ShareParams> shares;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('driving-trace-export');
    writes = [];
    shares = [];
    debugPublicFileExporterOverride = ({
      required bytes,
      required fileName,
      required mimeType,
    }) async {
      writes.add((fileName: fileName, mimeType: mimeType, bytes: bytes));
      return 'content://downloads/$fileName';
    };
    debugDrivingTraceTempDirectoryOverride = () async => tempDir;
    debugDrivingTraceShareSinkOverride = (params) async => shares.add(params);
  });

  tearDown(() async {
    debugPublicFileExporterOverride = null;
    debugDrivingTraceTempDirectoryOverride = null;
    debugDrivingTraceShareSinkOverride = null;
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('writes a stamped JSON to Downloads and returns true', () async {
    final ok = await DrivingAnalysisTraceExport.export(_trace());

    expect(ok, isTrue);
    expect(writes, hasLength(1));
    final write = writes.single;
    // Stamp derives from capturedAt with `:`/`.` swapped for `-`.
    expect(write.fileName, 'tankstellen-driving-2026-06-03T09-30-15-000Z.json');
    expect(write.mimeType, 'application/json');
    // The bytes are the pretty-printed, parseable trace JSON.
    final decoded = jsonDecode(utf8.decode(write.bytes));
    expect(decoded['kind'], 'drivingAnalysis');
    expect(decoded['comment'], kDrivingAnalysisCommentPrompt);
  });

  test('hands a .json XFile to the share sheet so it can be sent back',
      () async {
    await DrivingAnalysisTraceExport.export(_trace());

    expect(shares, hasLength(1));
    final params = shares.single;
    expect(params.files, hasLength(1));
    final file = params.files!.single;
    expect(file.path, endsWith('.json'));
    expect(file.mimeType, 'application/json');
    // The temp file was actually written before sharing.
    expect(File(file.path).existsSync(), isTrue);
  });

  test('a Downloads-write failure still returns false but does not throw',
      () async {
    debugPublicFileExporterOverride = ({
      required bytes,
      required fileName,
      required mimeType,
    }) async =>
        throw const FileSystemException('no Downloads access');

    final ok = await DrivingAnalysisTraceExport.export(_trace());

    expect(ok, isFalse);
    // The share handoff is independent of the Downloads write.
    expect(shares, hasLength(1));
  });
}
