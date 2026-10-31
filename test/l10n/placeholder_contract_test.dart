// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

Map<String, dynamic> _readArb(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

/// Read argument names, including nested ICU branches. Branch text is a
/// message, not an argument: `=0{None}` must not invent a `None` placeholder.
/// Escaping is disabled in the project's l10n.yaml, as in gen-l10n.
Set<String> _arguments(String message) {
  final names = <String>{};
  var cursor = 0;

  String until(Set<String> delimiters) {
    final start = cursor;
    while (cursor < message.length && !delimiters.contains(message[cursor])) {
      cursor++;
    }
    return message.substring(start, cursor).trim();
  }

  void readMessage() {
    while (cursor < message.length && message[cursor] != '}') {
      if (message[cursor++] != '{') continue;
      names.add(until({',', '}'}));
      if (cursor >= message.length) break;
      if (message[cursor++] == '}') continue;
      final type = until({',', '}'});
      if (cursor >= message.length) break;
      final delimiter = message[cursor++];
      if (delimiter == ',' &&
          const {'plural', 'select', 'selectordinal'}.contains(type)) {
        while (cursor < message.length && message[cursor] != '}') {
          until({'{', '}'}); // Skip the branch selector, e.g. `=0`.
          if (cursor >= message.length || message[cursor] != '{') break;
          cursor++;
          readMessage();
          if (cursor < message.length) cursor++; // branch close
          while (cursor < message.length && message[cursor].trim().isEmpty) {
            cursor++;
          }
        }
      } else if (delimiter == ',') {
        until({'}'}); // number/date/time format
      } else {
        continue; // the argument's closing brace was already consumed
      }
      if (cursor < message.length) cursor++; // argument close
    }
  }

  readMessage();
  return names;
}

List<String> _violations(
  Map<String, dynamic> reference,
  Map<String, dynamic> translated,
) {
  final failures = <String>[];
  for (final entry in reference.entries) {
    if (entry.key.startsWith('@') || entry.value is! String) continue;
    final actual = translated[entry.key];
    if (actual is! String ||
        !setEquals(_arguments(entry.value as String), _arguments(actual))) {
      failures.add('${entry.key}: argument names differ');
    }
    final expectedMeta = reference['@${entry.key}'] as Map?;
    final actualMeta = translated['@${entry.key}'] as Map?;
    final expectedTypes = expectedMeta?['placeholders'] as Map? ?? const {};
    final actualTypes = actualMeta?['placeholders'] as Map? ?? const {};
    for (final placeholder in actualTypes.entries) {
      final expected = expectedTypes[placeholder.key] as Map?;
      final actual = placeholder.value as Map;
      // A locale can omit metadata and inherit it from English. An explicit
      // override must keep the English argument and its type (#4497).
      if (expected == null || actual['type'] != expected['type']) {
        failures.add('${entry.key}.${placeholder.key}: argument type differs');
      }
    }
  }
  return failures;
}

void main() {
  test('ICU branch messages and nested arguments keep their identities', () {
    expect(
      _arguments(
        '{count, plural, =0{None} other{Hello {station}, '
        '{kind, select, a{{distance, number, ::decimal}} other{Again}}}}',
      ),
      {'count', 'station', 'kind', 'distance'},
    );
  });

  test('contract detects a removed placeholder and a changed type', () {
    const english = {
      'match': 'Below target: {station}',
      '@match': {
        'placeholders': {
          'station': {'type': 'String'},
        },
      },
    };
    expect(_violations(english, {'match': 'Sous votre cible.'}), [
      'match: argument names differ',
    ]);
    expect(
      _violations(english, {
        'match': '{station} sous votre cible.',
        '@match': {
          'placeholders': {
            'station': {'type': 'int'},
          },
        },
      }),
      ['match.station: argument type differs'],
    );
    expect(
      _violations(english, {'match': '{station} sous votre cible.'}),
      isEmpty,
    );
  });

  final reference = _readArb(File('lib/l10n/app_en.arb'));
  final files =
      Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    test('${file.path} preserves English placeholder names and types', () {
      expect(_violations(reference, _readArb(file)), isEmpty);
    });
  }

  for (final locale in AppLocalizations.supportedLocales) {
    test('test alert includes its station in $locale', () {
      const station = 'Regression station 4497';
      final body = lookupAppLocalizations(
        locale,
      ).developerToolsTestAlertBody(station);
      expect(body, contains(station));
      expect(body, isNot(contains('{station}')));
    });
  }
}
