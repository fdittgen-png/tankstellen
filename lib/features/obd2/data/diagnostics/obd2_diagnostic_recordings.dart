// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// One stored full-diagnostic recording (#4551).
@immutable
class Obd2DiagnosticRecording {
  const Obd2DiagnosticRecording({
    required this.file,
    required this.startedAt,
    required this.sizeBytes,
  });

  final File file;

  /// When the recorded trip started (parsed from the file name).
  final DateTime startedAt;

  final int sizeBytes;

  /// The file's base name — also the name the export uses.
  String get fileName => file.uri.pathSegments.last;
}

/// #4548 / #4551 (Epic #4547) — where full-diagnostic traces live, how
/// they are named, listed, pruned and deleted. Local-only: a recording
/// leaves the device only when the user downloads it.
abstract final class Obd2DiagnosticRecordings {
  /// Sub-directory of the app-support directory.
  static const String folderName = 'obd2_diagnostics';

  /// File-name prefix; the rest is the trip start as compact UTC.
  static const String prefix = 'obd2-diagnostic-';

  /// Keep at most this many recordings; [prune] removes the oldest.
  static const int keepNewest = 20;

  /// Test seam for [directory].
  @visibleForTesting
  static Directory? debugDirectoryOverride;

  /// The recordings directory, created on first use.
  static Future<Directory> directory() async {
    final override = debugDirectoryOverride;
    final base = override ?? Directory(
        '${(await getApplicationSupportDirectory()).path}/$folderName');
    if (!base.existsSync()) await base.create(recursive: true);
    return base;
  }

  /// `obd2-diagnostic-20261031T081500Z.ndjson` for a trip started at
  /// [startedAt].
  static String fileNameFor(DateTime startedAt) {
    final u = startedAt.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '$prefix${u.year}${two(u.month)}${two(u.day)}T'
        '${two(u.hour)}${two(u.minute)}${two(u.second)}Z.ndjson';
  }

  /// The trip start encoded in [fileName], or null for a foreign file.
  static DateTime? startedAtOf(String fileName) {
    final m = RegExp(r'^obd2-diagnostic-(\d{8})T(\d{6})Z\.ndjson$')
        .firstMatch(fileName);
    if (m == null) return null;
    final d = m.group(1)!;
    final t = m.group(2)!;
    return DateTime.utc(
      int.parse(d.substring(0, 4)),
      int.parse(d.substring(4, 6)),
      int.parse(d.substring(6, 8)),
      int.parse(t.substring(0, 2)),
      int.parse(t.substring(2, 4)),
      int.parse(t.substring(4, 6)),
    );
  }

  /// Every recording in [dir] (default: [directory]), newest first.
  static Future<List<Obd2DiagnosticRecording>> list([Directory? dir]) async {
    final d = dir ?? await directory();
    final out = <Obd2DiagnosticRecording>[];
    await for (final entity in d.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final startedAt = startedAtOf(name);
      if (startedAt == null) continue;
      out.add(Obd2DiagnosticRecording(
        file: entity,
        startedAt: startedAt,
        sizeBytes: await entity.length(),
      ));
    }
    out.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return out;
  }

  /// Delete all but the newest `keepNewest - 1` recordings, making room
  /// for the one about to start.
  static Future<void> prune(Directory dir) async {
    final all = await list(dir);
    for (final r in all.skip(keepNewest - 1)) {
      await r.file.delete();
    }
  }
}
