// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/obd2/data/diagnostics/obd2_diagnostic_recordings.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_full_diagnostic_section.dart';
import 'package:tankstellen/features/obd2/providers/obd2_full_diagnostic_provider.dart';

import '../../../../fakes/fake_hive_storage.dart';
import '../../../../helpers/hive_temp_dir.dart';
import '../../../../helpers/pump_app.dart';

/// #4548 / #4551 — the switch persists; the recordings list downloads
/// and deletes.
void main() {
  late FakeHiveStorage storage;
  late Directory dir;
  late File file;

  setUp(() async {
    storage = FakeHiveStorage()..hasBundledDefaultKey = false;
    dir = await Directory.systemTemp.createTemp('diagsection');
    file = File('${dir.path}/${Obd2DiagnosticRecordings.fileNameFor(DateTime.utc(2026, 10, 31, 8))}')
      ..writeAsStringSync('{"k":"header"}\n');
  });
  tearDown(() async {
    debugPublicFileExporterOverride = null;
    await closeHiveAndDeleteTemp(dir);
  });

  Future<void> pump(WidgetTester tester, {List<Obd2DiagnosticRecording>? rows}) =>
      pumpApp(tester, const SingleChildScrollView(child: Obd2FullDiagnosticSection()),
          overrides: [
            hiveStorageProvider.overrideWithValue(storage),
            obd2DiagnosticRecordingsProvider.overrideWith((ref) async => rows ??
                [Obd2DiagnosticRecording(file: file, startedAt: DateTime.utc(2026, 10, 31, 8), sizeBytes: 2048)]),
          ]);

  testWidgets('the switch is off by default and persists when flipped',
      (tester) async {
    await pump(tester, rows: const []);
    final finder = find.byKey(const Key('obd2FullDiagnosticToggle'));
    expect(tester.widget<SwitchListTile>(finder).value, isFalse);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(storage.getSetting(StorageKeys.obd2FullDiagnosticRecordingEnabled), isTrue);
    expect(find.byKey(const Key('obd2DiagnosticRecordingsEmpty')), findsOneWidget);
  });

  testWidgets('Download hands the file bytes to the exporter', (tester) async {
    Uint8List? saved;
    String? name;
    debugPublicFileExporterOverride = ({required bytes, required fileName, required mimeType}) async {
      saved = bytes;
      name = fileName;
      return 'ok';
    };
    await pump(tester);
    await tester.pumpAndSettle();
    final download = find.byKey(ValueKey('obd2DiagnosticDownload-${file.uri.pathSegments.last}'));
    expect(download, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(download);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(name, file.uri.pathSegments.last);
    expect(String.fromCharCodes(saved!), '{"k":"header"}\n');
  });

  testWidgets('Delete removes the file', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(ValueKey('obd2DiagnosticDelete-${file.uri.pathSegments.last}')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(file.existsSync(), isFalse);
  });
}
