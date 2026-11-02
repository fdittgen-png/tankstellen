// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'obd2_diagnostic_recordings.dart';
import '../protocol/diagnostics/diagnostic_evidence.dart';

/// Explicit per-session file link only. Never attach a nearby trip's health
/// by guessing from its date, vehicle, or most recent recording.
Future<Map<String, Object?>> loadDiagnosticEvidence(String? fileName) async {
  if (fileName == null ||
      Obd2DiagnosticRecordings.startedAtOf(fileName) == null) {
    return const {
      'status': 'unavailable',
      'reason': 'notLinked',
      'nextRecording':
          'Enable Full diagnostic recording before an OBD trip. '
          'Old trip summaries cannot recover unrecorded sensor values.',
    };
  }
  try {
    final dir = await Obd2DiagnosticRecordings.directory();
    return await compute(_readEvidence, '${dir.path}/$fileName');
  } on FormatException {
    return const {'status': 'unavailable', 'reason': 'malformedEncoding'};
  } on FileSystemException {
    return const {
      'status': 'unavailable',
      'reason': 'expiredDeletedOrUnreadable',
    };
  }
}

Future<Map<String, Object?>> _readEvidence(String path) async {
  final evidence = DiagnosticEvidence();
  // Streaming on a worker isolate: large retained traces never parse on the UI.
  await for (final line in File(
    path,
  ).openRead().transform(utf8.decoder).transform(const LineSplitter())) {
    evidence.addLine(line);
  }
  return evidence.toJson();
}
