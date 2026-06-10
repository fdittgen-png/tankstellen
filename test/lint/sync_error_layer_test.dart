// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#3128): sync code must log to
/// [ErrorLayer.sync], not the catch-all [ErrorLayer.other].
///
/// The `ErrorLayer` enum has a dedicated `sync` layer ("TankSync /
/// Supabase / cloud sync flows"), but every catch block under
/// `lib/core/sync/` shipped with `ErrorLayer.other` — burying sync
/// failures in the unclassified bucket where the error-log triage view
/// and per-layer sample rates can't see them.
///
/// What is forbidden (in `lib/core/sync/`):
///   ErrorLayer.other
///
/// What is allowed:
///   - `ErrorLayer.sync` (and any other specific layer where genuinely
///     appropriate — only the catch-all is banned here).
///   - generated files (`.g.dart`, `.freezed.dart`).
///
/// Baseline is **0** — never add an offender.
void main() {
  test('no ErrorLayer.other in lib/core/sync (#3128)', () {
    final offenders = <String>[];
    final banned = RegExp(r'ErrorLayer\.other\b');

    final dir = Directory('lib/core/sync');
    expect(dir.existsSync(), isTrue,
        reason: 'run from the repo root (lib/core/sync not found)');

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (banned.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Sync code must log to ErrorLayer.sync, not the catch-all '
          'ErrorLayer.other (#3128):\n${offenders.join('\n')}',
    );
  });
}
