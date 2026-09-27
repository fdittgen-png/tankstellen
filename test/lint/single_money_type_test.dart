// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #4395 — the app has exactly ONE `Money` type, `lib/core/domain/money.dart`.
///
/// Two parallel branches (#4361 refuel economics, #4215 fleet expenses)
/// each built a money value type because neither could see the other, and
/// a third feature had quietly named an unrelated saving breakdown `Money`
/// too. Two vocabularies for one fact make every "sum through `Money`"
/// rule (#4364) ambiguous about which one, so the scan fails on any
/// second declaration of a type named `Money` anywhere under `lib/` —
/// a class (any modifiers), a mixin, an enum, an extension type or a
/// typedef.
///
/// A source scan proves the text, not the code, so the rule is shown able
/// to fail by injecting an offender into the real sources in memory.
void main() {
  const home = 'lib/core/domain/money.dart';

  /// Strips `//` line comments so a doc mentioning `class Money` is not a
  /// declaration.
  String code(String source) => source
      .split('\n')
      .map((l) => l.contains('//') ? l.substring(0, l.indexOf('//')) : l)
      .join('\n');

  final declaration = RegExp(
    r'^\s*(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
    r'(?:class|mixin|enum|typedef|extension\s+type)\s+Money\b',
    multiLine: true,
  );

  List<String> declarations(Map<String, String> sources) => [
        for (final e in sources.entries)
          for (final _ in declaration.allMatches(code(e.value))) e.key,
      ];

  late Map<String, String> real;
  setUpAll(() => real = {
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.endsWith('.freezed.dart'))
            f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
      });

  test('exactly one Money type, in core/domain/money.dart', () {
    expect(declarations(real), [home],
        reason: 'fold a second money type into $home instead (#4395)');
  });

  group('the rule can fail (mutation check)', () {
    const other = 'lib/features/fleet/domain/expense_fields.dart';

    Map<String, String> inject(String snippet) =>
        {...real, other: '${real[other]!}\n$snippet\n'};

    test('a second class, whatever its modifiers', () {
      for (final snippet in [
        'class Money {}',
        'final class Money {}',
        'abstract interface class Money {}',
        'typedef Money = double;',
        'extension type Money(double amount) {}',
      ]) {
        expect(declarations(inject(snippet)), hasLength(2), reason: snippet);
      }
    });

    test('a comment, or a longer name, is not a declaration', () {
      expect(declarations(inject('// class Money lived here once')), [home]);
      expect(declarations(inject('class MoneyTally {}')), [home]);
      expect(declarations(inject('class OpportunityMoney {}')), [home]);
    });
  });
}
