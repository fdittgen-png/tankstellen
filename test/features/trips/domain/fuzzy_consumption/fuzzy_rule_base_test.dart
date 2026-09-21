// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';

import 'fuzzy_test_inputs.dart';

/// The shipped rule base's structure (#4232): well-formed, neutral, and
/// every rule reachable — the #2513 lesson (a membership that can never
/// fire is a dead bucket nobody notices) applied to rules.
void main() {
  final rules = FuzzyRuleBase.neutral.rules;

  test('rule ids are unique and stable-looking', () {
    final ids = rules.map((r) => r.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final r in rules) {
      expect(r.id, matches(RegExp(r'^[a-z0-9-]+$')));
      expect(r.id.endsWith('-d'), r.isDegraded,
          reason: 'the -d suffix and the degraded gate must agree: ${r.id}');
    }
  });

  test('every antecedent asks for a term its variable owns', () {
    for (final r in rules) {
      expect(r.antecedents, isNotEmpty, reason: r.id);
      for (final a in r.antecedents) {
        expect(a.variable.terms, contains(a.term),
            reason: '${r.id}: ${a.variable.name}.${a.term.name}');
      }
    }
  });

  test('a degraded rule never reads the input it stands in for', () {
    for (final r in rules.where((r) => r.isDegraded)) {
      for (final a in r.antecedents) {
        expect(r.onlyWhenUnavailable, isNot(contains(a.variable)),
            reason: r.id);
      }
    }
  });

  test('the shipped consequents are neutral priors — nothing is fitted', () {
    // The corpus holds no real trace (#4231). A non-neutral consequent here
    // would be an invented number; this test is the tripwire for it.
    for (final r in rules) {
      expect(r.consequent.multiplier, 1, reason: r.id);
      expect(r.consequent.residualLPerHour, 0, reason: r.id);
    }
    expect(FuzzyRuleBase.neutral.rulesVersion, 1);
  });

  test('every variable is read by at least one rule', () {
    final read = {
      for (final r in rules)
        for (final a in r.antecedents) a.variable,
    };
    expect(read, containsAll(FuzzyVariable.values));
  });

  group('every rule is reachable', () {
    for (final rule in rules) {
      test(rule.id, () {
        final result = const FuzzyConsumptionEngine()
            .infer(inputFiring(rule));
        final fired = result.evidence.firedRules.map((f) => f.id);
        expect(fired, contains(rule.id));
        final f = result.evidence.firedRules
            .firstWhere((f) => f.id == rule.id);
        expect(f.strength, closeTo(1, 0.02));
        expect(f.degraded, rule.isDegraded);
      });
    }
  });
}
