// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #4232 acceptance: "no alternate production estimator is called by the
/// fuzzy service".
///
/// A source-scanning test proves the text, not the code — so this one
/// scans the **real** import closure (following every relative import from
/// the engine's entry file), asserts the closure is non-empty and contains
/// the files it must, and then proves it can fail by injecting an offender
/// into the real source in memory. The closure is an allowlist: a new
/// import of *anything* outside it fails, not only a known estimator.
void main() {
  const entry = 'lib/features/trips/domain/fuzzy_consumption/'
      'fuzzy_consumption_engine.dart';
  const engineDir = 'lib/features/trips/domain/fuzzy_consumption/';

  /// The only lib files the engine may reach.
  const allowedOutsideEngineDir = {
    'lib/core/domain/consumption_estimate.dart',
    'lib/core/domain/data_value.dart',
    'lib/core/domain/fuzzy_membership.dart',
  };

  /// The only non-relative imports the closure may use. No Flutter: the
  /// replay tool runs the engine under plain `dart run`.
  const allowedPackages = {'dart:math', 'package:meta/meta.dart'};

  /// Production estimators and fuel-rate arithmetic the engine must take
  /// as INPUTS, never call.
  const forbiddenIdentifiers = [
    'GpsLiveFuelEstimator',
    'GpsFuelEstimator',
    'PhysicsScaleCalibrator',
    'GpsMatrixReconciler',
    'Obd2Service',
    'deriveFuelRateLPerHour',
    'estimateFuelRateLPerHourFromMap',
    'FuelConsumptionEstimator',
    'FuzzyClassifier',
    'resolvePumpGain',
  ];

  final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true);

  String normalize(String path) {
    final out = <String>[];
    for (final seg in path.split('/')) {
      if (seg == '.' || seg.isEmpty) continue;
      if (seg == '..') {
        out.removeLast();
      } else {
        out.add(seg);
      }
    }
    return out.join('/');
  }

  /// Strips `//` comments so a doc mentioning an estimator by name is not
  /// a call to it.
  String code(String source) => source
      .split('\n')
      .map((l) => l.contains('//') ? l.substring(0, l.indexOf('//')) : l)
      .join('\n');

  /// Violations in the closure reachable from [start], reading sources
  /// through [read] (the real filesystem, or a mutated copy).
  ({Set<String> closure, List<String> violations}) scan(
      String start, String Function(String path) read) {
    final closure = <String>{};
    final violations = <String>[];
    final queue = [start];
    while (queue.isNotEmpty) {
      final path = queue.removeLast();
      if (!closure.add(path)) continue;
      final source = read(path);
      final dir = path.substring(0, path.lastIndexOf('/'));
      for (final m in directive.allMatches(source)) {
        final uri = m.group(1)!;
        if (uri.startsWith('dart:') || uri.startsWith('package:')) {
          if (!allowedPackages.contains(uri)) {
            violations.add('$path imports $uri');
          }
          continue;
        }
        final target = normalize('$dir/$uri');
        if (!target.startsWith(engineDir) &&
            !allowedOutsideEngineDir.contains(target)) {
          violations.add('$path imports $target');
          continue;
        }
        queue.add(target);
      }
      final body = code(source);
      for (final id in forbiddenIdentifiers) {
        if (RegExp('\\b$id\\b').hasMatch(body)) {
          violations.add('$path references $id');
        }
      }
    }
    return (closure: closure, violations: violations);
  }

  String readReal(String path) => File(path).readAsStringSync();

  test('the real import closure reaches no other estimator', () {
    final result = scan(entry, readReal);

    expect(result.closure, containsAll([
      entry,
      '${engineDir}fuzzy_rule_base.dart',
      '${engineDir}fuzzy_variables.dart',
      'lib/core/domain/fuzzy_membership.dart',
      'lib/core/domain/consumption_estimate.dart',
    ]), reason: 'the scan must actually walk the engine, or it proves '
        'nothing');
    expect(result.violations, isEmpty,
        reason: result.violations.join('\n'));
  });

  group('the scan can fail (mutation check)', () {
    String Function(String) mutated(String inject) => (path) {
          final real = readReal(path);
          return path == entry ? '$inject\n$real' : real;
        };

    test('importing a production estimator is caught', () {
      final result = scan(entry,
          mutated("import '../services/gps_live_fuel_estimator.dart';"));
      expect(result.violations.join('\n'),
          contains('services/gps_live_fuel_estimator.dart'));
    });

    test('importing Flutter is caught', () {
      final result = scan(
          entry, mutated("import 'package:flutter/foundation.dart';"));
      expect(result.violations, isNotEmpty);
    });

    test('a transitive offender in a sibling file is caught', () {
      const sibling = '${engineDir}fuzzy_variables.dart';
      final result = scan(entry, (path) {
        final real = readReal(path);
        return path == sibling
            ? "import '../../../obd2/data/obd2_service.dart';\n$real"
            : real;
      });
      expect(result.violations.join('\n'), contains(sibling));
    });

    test('calling an estimator by name is caught, mentioning it is not', () {
      final call = scan(entry,
          mutated('final _x = GpsLiveFuelEstimator.forVehicle(null, null);'));
      expect(call.violations.join('\n'), contains('GpsLiveFuelEstimator'));

      final mention = scan(entry, mutated('/// Unlike GpsLiveFuelEstimator.'));
      expect(mention.violations, isEmpty);
    });
  });
}
