// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Feature-boundary gate (#3132, epic #3129) — the import-direction lint.
///
/// The feature-first layout describes folders, not the dependency graph:
/// the 2026-06-10 audit found 787 cross-feature imports across 110
/// directed pairs with 24 bidirectional cycles, plus 101 core→feature
/// inversions (the #3130 domain kernel removed ~310 of them; the
/// baselines below are the post-kernel measurement). This test freezes
/// the remaining graph and lets it move in ONE direction only.
///
/// ## What counts as a violation
///
///   * **feature → feature** — a file under `lib/features/<a>/` importing
///     (or exporting) a file under `lib/features/<b>/` (`a != b`) that is
///     NOT `lib/features/<b>/api.dart`. Every feature's public contract is
///     its `api.dart` barrel; reaching into `providers/`, `data/`,
///     `domain/` or `presentation/` of another feature is the violation.
///   * **core → feature** — a file under `lib/core/` importing anything
///     under `lib/features/` (the barrel does NOT excuse this direction:
///     core must never depend on features at all — epic #3129's goal).
///
/// The app shell (`lib/` outside `core/` and `features/`) is out of scope
/// here — #3133/#3135 own that surface.
///
/// ## Relative-import resolution (the audit's key finding)
///
/// The codebase uses *relative* imports exclusively — a
/// `package:tankstellen/` grep finds **zero** cross-feature imports while
/// the real count is in the hundreds. Every `import`/`export` URI is
/// therefore resolved against the importing file's directory (and
/// `package:tankstellen/` URIs against `lib/`) before classification.
///
/// ## The only-decreasing ratchet
///
/// The baselines are **exact-match** snapshots (same mechanism as the
/// `file_length_test` shrink signal):
///
///   1. a count above its baseline entry — or a brand-new pair — fails CI;
///   2. a count below its baseline entry ALSO fails ("stale baseline") so
///      every single decrement is locked in by updating the map in the
///      same PR and can never silently creep back.
///
/// NEVER raise an entry or add a new pair. The targets are: zero
/// core→feature imports, zero bidirectional cycles, and every surviving
/// feature→feature edge routed through `api.dart`.
void main() {
  // importing feature -> imported feature -> count (api.dart exempt).
  final featurePairs = <String, int>{};
  // imported feature -> count of lib/core/ files importing it.
  final coreImports = <String, int>{};
  final violationLines = <String>[];

  // ---------------------------------------------------------------------
  // Scan: resolve every import/export directive in lib/ to a lib/ path.
  // ---------------------------------------------------------------------
  setUpAll(() {
    final directive = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );

    String normalize(String path) {
      final parts = <String>[];
      for (final seg in path.split('/')) {
        if (seg == '.' || seg.isEmpty) continue;
        if (seg == '..') {
          if (parts.isNotEmpty) parts.removeLast();
          continue;
        }
        parts.add(seg);
      }
      return parts.join('/');
    }

    /// `lib/features/<name>/...` → `<name>`, else null.
    String? featureOf(String libPath) =>
        RegExp(r'^lib/features/([^/]+)/').firstMatch('$libPath/')?.group(1);

    final libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'lib/ must exist at project root',
    );

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
        continue;
      }
      if (path.contains('/l10n/app_localizations')) continue;

      final fromFeature = featureOf(path);
      final isCore = path.startsWith('lib/core/');
      if (fromFeature == null && !isCore) continue; // shell: out of scope

      final source = entity.readAsStringSync();
      final dir = path.substring(0, path.lastIndexOf('/'));
      for (final match in directive.allMatches(source)) {
        final uri = match.group(1)!;
        String target;
        if (uri.startsWith('package:tankstellen/')) {
          target = 'lib/${uri.substring('package:tankstellen/'.length)}';
        } else if (uri.startsWith('dart:') || uri.startsWith('package:')) {
          continue; // SDK / third-party
        } else {
          target = normalize('$dir/$uri');
        }
        final toFeature = featureOf(target);
        if (toFeature == null) continue; // target outside lib/features
        if (fromFeature == toFeature) continue; // intra-feature: fine

        if (isCore) {
          // core -> feature: ALWAYS a violation, even via api.dart.
          coreImports.update(toFeature, (v) => v + 1, ifAbsent: () => 1);
          violationLines.add('$path -> $target');
        } else {
          // feature -> feature: api.dart barrel is the public contract.
          if (target == 'lib/features/$toFeature/api.dart') continue;
          featurePairs.update(
            '$fromFeature -> $toFeature',
            (v) => v + 1,
            ifAbsent: () => 1,
          );
          violationLines.add('$path -> $target');
        }
      }
    }
  });

  /// Renders [actual] as the Dart map literal to paste over a baseline.
  String literalOf(Map<String, int> actual) {
    final keys = actual.keys.toList()..sort();
    return keys.map((k) => "    '$k': ${actual[k]},").join('\n');
  }

  /// All keys whose actual count differs from its baseline entry, with
  /// the direction of the drift spelled out.
  List<String> driftOf(Map<String, int> actual, Map<String, int> baseline) {
    final drift = <String>[];
    for (final key in {...actual.keys, ...baseline.keys}) {
      final a = actual[key] ?? 0;
      final b = baseline[key] ?? 0;
      if (a > b) drift.add('$key: $a (baseline $b) — REGRESSION, revert it');
      if (a < b) drift.add('$key: $a (baseline $b) — stale, lower the entry');
    }
    return drift..sort();
  }

  test('every feature exposes an api.dart public barrel', () {
    final missing = <String>[];
    for (final dir in Directory('lib/features').listSync()) {
      if (dir is! Directory) continue;
      final path = dir.path.replaceAll(r'\', '/');
      if (!File('$path/api.dart').existsSync()) missing.add(path);
    }
    expect(
      missing..sort(),
      isEmpty,
      reason:
          'Every feature directory must expose a public api.dart barrel '
          '(#3132) — the only file other features may import.\n'
          'Missing:\n${missing.join('\n')}',
    );
  });

  test('feature → feature imports never exceed the per-pair baseline', () {
    final drift = driftOf(featurePairs, _featurePairBaseline);
    expect(
      drift,
      isEmpty,
      reason:
          'Cross-feature import graph drifted from the only-decreasing '
          'baseline (#3132).\n'
          'A new/raised pair means a feature reached into another feature\'s '
          'internals — import its api.dart barrel (or move the shared type '
          'to lib/core/domain) instead. A lowered pair must be locked in by '
          'updating _featurePairBaseline in the same PR.\n\n'
          'Drift:\n${drift.join('\n')}\n\n'
          'Up-to-date baseline literal:\n${literalOf(featurePairs)}\n\n'
          'All current cross-feature imports:\n'
          '${(violationLines..sort()).join('\n')}',
    );
  });

  test('core → feature imports never exceed the (target-zero) baseline', () {
    final drift = driftOf(coreImports, _coreImportBaseline);
    expect(
      drift,
      isEmpty,
      reason:
          'core → feature is the WORST inversion direction: lib/core/ '
          'must never depend on lib/features/ at all (epic #3129; the '
          'api.dart barrel does not excuse it). Invert the dependency '
          '(callback / interface in core, implementation in the feature) or '
          'move the shared type to lib/core/. A lowered count must be locked '
          'in by updating _coreImportBaseline in the same PR.\n\n'
          'Drift:\n${drift.join('\n')}\n\n'
          'Up-to-date baseline literal:\n${literalOf(coreImports)}',
    );
  });

  test('bidirectional feature cycles never exceed the baseline', () {
    final cycles = <String>{};
    for (final key in featurePairs.keys) {
      final parts = key.split(' -> ');
      final reverse = '${parts[1]} -> ${parts[0]}';
      if (featurePairs.containsKey(reverse)) {
        final pair = [parts[0], parts[1]]..sort();
        cycles.add('${pair[0]} <-> ${pair[1]}');
      }
    }
    final sorted = cycles.toList()..sort();
    expect(
      sorted.length,
      _cycleBaseline,
      reason:
          'Bidirectional feature cycles changed (baseline '
          '$_cycleBaseline, target 0). A new cycle is a hard architectural '
          'regression — break it before merging. A broken cycle must be '
          'locked in by lowering _cycleBaseline in the same PR.\n\n'
          'Current cycles:\n${sorted.join('\n')}',
    );
  });
}

/// Post-#3130 measurement (2026-06-11): cross-feature imports that do NOT
/// go through the target feature's `api.dart` barrel, grouped
/// `importing-feature -> imported-feature`. ONLY EVER DECREASES — never
/// raise an entry, never add a pair; remove an entry when it hits 0.
const _featurePairBaseline = <String, int>{
  'achievements -> consumption': 8,
  'achievements -> price_history': 2,
  'alerts -> map': 1,
  'approach -> consumption': 2,
  'approach -> favorites': 1,
  'approach -> profile': 8,
  'calculator -> consumption': 2,
  'calculator -> profile': 1,
  'calculator -> search': 3,
  'calculator -> vehicle': 1,
  'car -> widget': 1,
  'carbon -> consumption': 8,
  'carbon -> vehicle': 1,
  'consumption -> achievements': 1,
  'consumption -> approach': 8,
  'consumption -> carbon': 2,
  'consumption -> driving': 6,
  'consumption -> ev': 12,
  'consumption -> feature_management': 25,
  'consumption -> glide_coach': 4,
  'consumption -> map': 2,
  'consumption -> profile': 10,
  'consumption -> search': 2,
  'consumption -> sync': 1,
  'consumption -> vehicle': 47,
  'driving -> approach': 1,
  'driving -> consumption': 8,
  'driving -> feature_management': 6,
  'driving -> glide_coach': 2,
  'driving -> map': 3,
  'driving -> profile': 5,
  'driving -> search': 1,
  'ev -> search': 1,
  'ev -> vehicle': 1,
  'favorites -> alerts': 1,
  'favorites -> price_history': 1,
  'favorites -> profile': 1,
  'favorites -> search': 2,
  'favorites -> widget': 1,
  'feature_management -> profile': 2,
  'glide_coach -> feature_management': 2,
  'itinerary -> profile': 1,
  'itinerary -> route_search': 3,
  'itinerary -> search': 1,
  'map -> ev': 5,
  'map -> itinerary': 1,
  'map -> profile': 1,
  'map -> route_search': 6,
  'map -> search': 10,
  'price_history -> feature_management': 6,
  'profile -> alerts': 2,
  'profile -> approach': 1,
  'profile -> consent': 1,
  'profile -> consumption': 23,
  'profile -> driving': 1,
  'profile -> feature_management': 52,
  'profile -> search': 2,
  'profile -> sync': 2,
  'profile -> vehicle': 3,
  'profile -> widget': 1,
  'route_search -> profile': 11,
  'route_search -> search': 1,
  'search -> approach': 1,
  'search -> consumption': 5,
  'search -> ev': 4,
  'search -> favorites': 4,
  'search -> feature_management': 8,
  'search -> loyalty': 1,
  'search -> map': 1,
  'search -> profile': 15,
  'search -> route_search': 14,
  'search -> station_detail': 3,
  'search -> widget': 2,
  'setup -> consumption': 5,
  'setup -> feature_management': 4,
  'setup -> profile': 4,
  'setup -> vehicle': 7,
  'station_detail -> alerts': 3,
  'station_detail -> favorites': 1,
  'station_detail -> feature_management': 2,
  'station_detail -> payment': 3,
  'station_detail -> price_history': 4,
  'station_detail -> profile': 1,
  'station_detail -> route_search': 1,
  'station_detail -> search': 8,
  'station_detail -> sync': 1,
  'station_services -> station_detail': 1,
  'sync -> alerts': 3,
  'sync -> consumption': 3,
  'sync -> favorites': 2,
  'sync -> feature_management': 2,
  'sync -> vehicle': 2,
  'vehicle -> consumption': 24,
  'vehicle -> profile': 1,
  'widget -> consumption': 1,
  'widget -> price_history': 2,
  'widget -> profile': 3,
};

/// Post-#3130 measurement (2026-06-11): `lib/core/` files importing
/// `lib/features/` files, grouped by imported feature. Target **0** —
/// this direction is never legitimate. ONLY EVER DECREASES.
// #3131 — the alert-scan engine moved into features/alerts: alerts 17→3
// (the journal/trigger/telemetry seams remain), price_history and widget
// hit ZERO.
const _coreImportBaseline = <String, int>{
  'alerts': 3,
  'consumption': 8,
  'feature_management': 3,
  'itinerary': 3,
  'map': 1,
  'profile': 5,
  'search': 2,
  'station_services': 19,
};

/// Post-#3130 measurement (2026-06-11): bidirectional feature↔feature
/// cycles implied by [_featurePairBaseline]. Target **0**. ONLY EVER
/// DECREASES.
const _cycleBaseline = 19;
