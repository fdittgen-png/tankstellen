// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #4233 acceptance: "no production feature flag can select another
/// estimator" (Epic #4222, ADR 0024 §8).
///
/// Four static rules over `lib/`:
///
///  1. **One engine.** `FuzzyConsumptionEngine(`, `FuzzyRuleBase(` and
///     `FuzzyRuleBase.neutral` appear only in the production binding and the
///     engine's own declarations. Every `engine:` argument forwards a test
///     seam (`engine: engine` / `engine: _engine`), never picks one.
///  2. **No selector reaches the estimator.** The real domain-layer import
///     closure of the stage, the binding, the trip adapter, the provenance
///     stamp and the GPS road-load estimator imports no feature-flag,
///     settings, provider or Riverpod code, and neither they nor the engine
///     read `calibrationMode`, a `Feature` or a provider.
///  3. **No flag names an estimator.** No `Feature` value matches
///     fuzzy / estimator / physics / consumptionModel / calibration.
///  4. **The gain once.** `* pumpGain` (either operand order) appears only
///     in the fuzzy stage.
///
/// A source scan proves the text, not the code, so every rule is proven able
/// to fail by injecting an offender into the real sources in memory, and
/// the behaviour it guards is pinned separately
/// (`consumption_identity_goldens_test.dart`, `fuzzy_fuel_rate_stage_test`).
void main() {
  const fuzzyDir = 'lib/features/trips/domain/fuzzy_consumption/';
  const binding = '${fuzzyDir}production_fuzzy_engine.dart';
  const stage = '${fuzzyDir}fuzzy_fuel_rate_stage.dart';

  /// Files allowed to name an engine / rule-base constructor.
  const constructionAllowed = {
    binding,
    '${fuzzyDir}fuzzy_consumption_engine.dart', // the declaration
    '${fuzzyDir}fuzzy_rule_base.dart', // the declaration + `neutral`
  };

  /// Strips `//` line comments so a doc mentioning a name is not a use.
  String code(String source) => source
      .split('\n')
      .map((l) => l.contains('//') ? l.substring(0, l.indexOf('//')) : l)
      .join('\n');

  Map<String, String> libSources() => {
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.endsWith('.freezed.dart') &&
              !f.path.startsWith('lib/l10n/'))
            f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
      };

  // ─── Rule 1 ───────────────────────────────────────────────────────────
  final construction =
      RegExp(r'\b(FuzzyConsumptionEngine\(|FuzzyRuleBase\(|FuzzyRuleBase\.neutral\b)');
  final engineArg = RegExp(r'\bengine:\s*([A-Za-z_][\w.]*)');

  /// A file takes part in consumption estimation when it names the fuzzy
  /// engine, its binding or its per-sample stage. Only those files can pick
  /// an estimator through an `engine:` argument; the word alone is not
  /// specific — `TankBlendEngine` (#4275) is passed as `engine:` too, and a
  /// blend engine selects no consumption estimator.
  final estimationParticipant = RegExp(
      r'fuzzy_consumption/|FuzzyConsumptionEngine|kProductionFuzzyEngine|'
      r'estimatedFuelRateLPerHour');

  List<String> rule1(Map<String, String> sources) => [
        for (final e in sources.entries) ...[
          if (!constructionAllowed.contains(e.key) &&
              construction.hasMatch(code(e.value)))
            '${e.key} constructs an engine or rule base',
          if (estimationParticipant.hasMatch(code(e.value)))
            for (final m in engineArg.allMatches(code(e.value)))
              if (m.group(1) != 'engine' && m.group(1) != '_engine')
                '${e.key} passes engine: ${m.group(1)}',
        ],
      ];

  // ─── Rule 2 ───────────────────────────────────────────────────────────
  const roots = [
    stage,
    binding,
    'lib/features/trips/domain/trip_consumption_estimate.dart',
    'lib/features/trips/domain/trip_consumption_provenance.dart',
    'lib/features/trips/domain/services/gps_live_fuel_estimator.dart',
  ];
  final forbiddenPath = RegExp(
      r'feature_management|/settings/|/providers/|_provider\.dart|riverpod|'
      r'calibration_mode');
  const forbiddenIdentifiers = [
    'Feature.',
    'calibrationMode',
    'CalibrationMode',
    'featureFlag',
    'ref.watch',
    'ref.read',
  ];
  final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true);

  String normalize(String path) {
    final out = <String>[];
    for (final seg in path.split('/')) {
      if (seg == '.' || seg.isEmpty) continue;
      seg == '..' ? out.removeLast() : out.add(seg);
    }
    return out.join('/');
  }

  ({Set<String> closure, List<String> violations}) rule2(
      String Function(String) read) {
    final closure = <String>{};
    final violations = <String>[];
    final queue = [...roots];
    while (queue.isNotEmpty) {
      final path = queue.removeLast();
      if (!closure.add(path)) continue;
      final source = read(path);
      final dir = path.substring(0, path.lastIndexOf('/'));
      for (final m in directive.allMatches(source)) {
        final uri = m.group(1)!;
        final target = uri.startsWith('package:tankstellen/')
            ? 'lib/${uri.substring('package:tankstellen/'.length)}'
            : (uri.startsWith('dart:') || uri.startsWith('package:'))
                ? uri
                : normalize('$dir/$uri');
        if (forbiddenPath.hasMatch(target)) {
          violations.add('$path imports $target');
          continue;
        }
        // Walk the domain layer only. A barrel (`api.dart`) is another
        // feature's public surface: its PATH is checked above (a
        // `feature_management` barrel fails), but it is not followed —
        // through the barrels every file of the app is reachable, and a
        // closure of everything proves nothing.
        if (target.contains('/domain/') && !target.endsWith('/api.dart')) {
          queue.add(target);
        }
      }
      // Identifiers are checked where the estimate is computed — the roots
      // and the engine — not in every data class they read (VehicleProfile
      // legitimately persists the baseline `calibrationMode`, ADR 0022).
      if (roots.contains(path) || path.startsWith(fuzzyDir)) {
        final body = code(source);
        for (final id in forbiddenIdentifiers) {
          if (body.contains(id)) violations.add('$path references $id');
        }
      }
    }
    return (closure: closure, violations: violations);
  }

  // ─── Rule 3 ───────────────────────────────────────────────────────────
  const featureFile = 'lib/features/feature_management/domain/feature.dart';
  final estimatorName = RegExp(
      r'fuzzy|estimator|physics|consumptionModel|calibration',
      caseSensitive: false);

  List<String> featureNames(String source) {
    // Comments stripped first: a `;` in a value's doc ends nothing.
    final stripped = code(source);
    final body = stripped.substring(stripped.indexOf('enum Feature {'));
    final end = body.indexOf('\n}');
    return RegExp(r'^  ([a-z]\w*)\s*[,(;]', multiLine: true)
        .allMatches(body.substring(0, end < 0 ? body.length : end))
        .map((m) => m.group(1)!)
        .toList();
  }

  List<String> rule3(String source) =>
      featureNames(source).where(estimatorName.hasMatch).toList();

  // ─── Rule 4 ───────────────────────────────────────────────────────────
  final gainTimes = RegExp(r'\*\s*pumpGain\b|\bpumpGain\s*\*');

  List<String> rule4(Map<String, String> sources) => [
        for (final e in sources.entries)
          if (e.key != stage && gainTimes.hasMatch(code(e.value)))
            '${e.key} multiplies by pumpGain',
      ];

  late Map<String, String> real;
  setUpAll(() => real = libSources());

  group('the real tree', () {
    test('rule 1: one engine construction site, no engine picked', () {
      expect(real.keys.where((k) => construction.hasMatch(code(real[k]!))),
          contains(binding),
          reason: 'the scan must see the binding, or it proves nothing');
      expect(rule1(real), isEmpty);
    });

    test('rule 2: no selector in the estimator import closure', () {
      final r = rule2((p) => real[p] ?? File(p).readAsStringSync());
      expect(r.closure, containsAll([...roots,
        '${fuzzyDir}fuzzy_consumption_engine.dart']));
      expect(r.violations, isEmpty, reason: r.violations.join('\n'));
    });

    test('rule 3: no Feature value names an estimator', () {
      final names = featureNames(real[featureFile]!);
      expect(names, containsAll(['obd2TripRecording', 'startupTrace']),
          reason: 'the enum parse must see the real values');
      expect(rule3(real[featureFile]!), isEmpty);
    });

    test('rule 4: a pump gain multiplies an estimate only in the stage', () {
      expect(gainTimes.hasMatch(code(real[stage]!)), isTrue,
          reason: 'the stage must be where the gain is applied');
      expect(rule4(real), isEmpty);
    });
  });

  group('each rule can fail (mutation check)', () {
    const snapshot =
        'lib/features/obd2/data/session/live_sample_snapshot_fuel_rate.dart';

    Map<String, String> inject(String path, String Function(String) mutate) =>
        {...real, path: mutate(real[path]!)};

    test('rule 1: a second engine, or a picked one', () {
      expect(
          rule1(inject(snapshot,
              (s) => '$s\nconst _e = FuzzyConsumptionEngine();')),
          isNotEmpty);
      expect(
          rule1(inject(snapshot,
              (s) => '$s\nfinal _r = FuzzyRuleBase.neutral;')),
          isNotEmpty);
      expect(
          rule1(inject(snapshot, (s) => '$s\nf() => g(engine: myEngine);')),
          isNotEmpty);
      // A blend engine argument in a file outside consumption estimation
      // picks no estimator (#4277's next-fill decider passes one).
      expect(
          rule1(inject('lib/core/domain/fuel/next_fill_decider.dart',
              (s) => '$s\nf() => g(engine: blendEngine);')),
          isEmpty);
      // Mentioning it in a comment is not a construction.
      expect(
          rule1(inject(snapshot,
              (s) => '$s\n// FuzzyConsumptionEngine() lives in the binding')),
          isEmpty);
    });

    test('rule 2: a flag, a provider or calibrationMode in the closure', () {
      String Function(String) reading(String path, String inject) =>
          (p) => p == path ? '$inject\n${real[p]!}' : (real[p] ?? '');
      const gps =
          'lib/features/trips/domain/services/gps_live_fuel_estimator.dart';
      expect(
          rule2(reading(gps,
                  "import '../../../feature_management/domain/feature.dart';"))
              .violations,
          isNotEmpty);
      expect(
          rule2(reading(stage, 'final _m = profile.calibrationMode;'))
              .violations,
          isNotEmpty);
      expect(
          rule2(reading(binding,
                  "import 'package:flutter_riverpod/flutter_riverpod.dart';"))
              .violations,
          isNotEmpty);
    });

    test('rule 3: a Feature named after an estimator', () {
      final mutated = real[featureFile]!
          .replaceFirst('enum Feature {', 'enum Feature {\n  fuzzyEstimator,');
      expect(rule3(mutated), ['fuzzyEstimator']);
    });

    test('rule 4: a pump gain outside the stage, either operand order', () {
      expect(
          rule4(inject(snapshot, (s) => '$s\nfinal x = raw * pumpGain;')),
          isNotEmpty);
      expect(
          rule4(inject(snapshot, (s) => '$s\nfinal x = pumpGain * raw;')),
          isNotEmpty);
    });
  });
}
