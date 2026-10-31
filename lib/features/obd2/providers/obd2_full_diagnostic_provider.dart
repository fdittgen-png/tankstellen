// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/diagnostics/obd2_diagnostic_recordings.dart';
import '../data/protocol/diagnostics/diagnostic_report_analyzer.dart';
import '../domain/diagnostics/diagnostic_report.dart';

// The presentation layer reads these types through this provider file.
export '../data/diagnostics/obd2_diagnostic_recordings.dart'
    show Obd2DiagnosticRecording;
export '../domain/diagnostics/diagnostic_report.dart';

part 'obd2_full_diagnostic_provider.g.dart';

/// #4548 (Epic #4547) — the opt-in "Full diagnostic recording" switch.
///
/// When on, every OBD2 trip additionally writes a raw per-command trace
/// (every request + reply at its own millisecond timestamp), polls the
/// car's health PIDs and trouble codes continuously (#4549) and takes a
/// start/stop identity snapshot (#4550). Read once per trip by the
/// recording pipeline. Off by default — it costs adapter bandwidth and
/// storage, and exists to analyse a car fault.
@riverpod
class Obd2FullDiagnosticRecording extends _$Obd2FullDiagnosticRecording {
  @override
  bool build() {
    final storage = ref.watch(storageRepositoryProvider);
    return storage.getSetting(
            StorageKeys.obd2FullDiagnosticRecordingEnabled) as bool? ??
        false;
  }

  /// Persist [value] and update the state.
  Future<void> set(bool value) async {
    await ref
        .read(storageRepositoryProvider)
        .putSetting(StorageKeys.obd2FullDiagnosticRecordingEnabled, value);
    state = value;
  }
}

/// #4551 — the stored full-diagnostic recordings, newest first.
/// Invalidate after a delete or when a trip ends.
@riverpod
Future<List<Obd2DiagnosticRecording>> obd2DiagnosticRecordings(Ref ref) =>
    Obd2DiagnosticRecordings.list();

/// #4552 — the per-system health report of the recording at [path],
/// analysed on a worker isolate (a long trace is tens of MB of NDJSON).
@riverpod
Future<DiagnosticReport> obd2DiagnosticReport(Ref ref, String path) async {
  final text = await File(path).readAsString();
  return compute(analyzeDiagnosticRecording, text);
}
