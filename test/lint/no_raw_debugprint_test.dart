// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet (#3981, Epic #3952): raw `debugPrint(` anywhere in `lib/`.
///
/// ADR 0021 (#3976) decided one sanctioned logging path — `log.debug` /
/// `log.info` / `log.warn` / `log.error` — deliberately including the
/// pure-trace sites: a `debugPrint` never reaches the field export, while
/// `log.info` also drops a breadcrumb that rides inside every persisted
/// trace, and `log.debug` keeps the release no-op the façade owns.
///
/// 313 sites in 154 files on 2026-09-08 (outside the telemetry pipeline,
/// which keeps `debugPrint` as its never-throws fallback). Decrease-only;
/// the #3978 migration series and the tasks that touch these files lower
/// it. Target 0.
void main() {
  final re = RegExp(r'\bdebugPrint\s*\(');

  test('matcher fidelity: debugPrint( and not lookalikes (#2348)', () {
    const fixture = '''
      debugPrint('a');            // 1
      debugPrint (            // 2 — space before paren
        'b');
      log.debug('c');             // the façade: not a hit
      myDebugPrint('d');          // different identifier: not a hit
    ''';
    expect(re.allMatches(fixture).length, 2);
  });

  test('raw debugPrint( in lib/ does not grow (#3981)', () {
    final perFile = <String, int>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      final path = entity.path.replaceAll('\\', '/');
      if (_pipeline.any(path.startsWith)) continue;
      final n = re.allMatches(entity.readAsStringSync()).length;
      if (n > 0) perFile[path] = n;
    }
    final sites = perFile.values.fold<int>(0, (a, b) => a + b);
    final listing = (perFile.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(25)
        .map((e) => '  - ${e.key} (${e.value}x)')
        .join('\n');
    expect(sites, lessThanOrEqualTo(_baselineSites),
        reason: 'raw debugPrint( sites: $sites (baseline $_baselineSites, '
            'decrease-only). Use log.debug / log.info from '
            'lib/core/logging/app_log.dart (ADR 0021, #3981). Top files:\n'
            '$listing');
    expect(perFile.length, lessThanOrEqualTo(_baselineFiles),
        reason: 'files with raw debugPrint(: ${perFile.length} '
            '(baseline $_baselineFiles, decrease-only).\n$listing');
  });
}

/// The telemetry pipeline keeps `debugPrint` as its never-throws fallback.
const _pipeline = <String>['lib/core/logging/', 'lib/core/telemetry/'];

/// Baselines as of 2026-09-08 (#3981). Only ever decrease; target 0.
///
/// #4039 — 313 → 253 sites, 154 → 130 files: the 61 catch handlers whose
/// entire body was a `debugPrint` (a silent swallow in release) became
/// `log.warn(..., error:, stack:, layer:)` calls. The remainder are
/// ordinary trace prints outside catch blocks and come down in the
/// per-feature batches the issue describes.
const _baselineSites = 253;
const _baselineFiles = 130;
