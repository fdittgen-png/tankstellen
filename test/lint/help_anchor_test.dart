// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4007 — an anchor is only useful if it resolves for every reader.
//
// The failure this exists to prevent: a Danish reader taps a `?`, the
// anchor resolves in English and not in Danish, and the guide opens at
// the top with no explanation. The reader concludes the button is
// broken, which it is.
//
// So an anchor the app points at must name a heading in EVERY wiki
// language. That is checked here against the guides, not against the
// compiled assets, so a stale asset cannot make a broken anchor look
// fine.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/help/help_anchors.dart';

const _languages = ['da', 'de', 'en', 'es', 'fr', 'it', 'pt'];
const _wiki = 'docs/wiki';

final _anchorComment =
    RegExp(r'<!--\s*anchor:\s*([a-z][a-z0-9]*(?:\.[a-z0-9-]+)+)\s*-->');

/// anchor → the heading it names, across every page of one language.
Map<String, String> _anchorsOf(String language) {
  final found = <String, String>{};
  for (final file in Directory(_wiki).listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (!name.startsWith('User-$language-') || !name.endsWith('.md')) continue;
    final lines = file.readAsStringSync().split('\n');
    for (var i = 0; i < lines.length - 1; i++) {
      final match = _anchorComment.firstMatch(lines[i]);
      if (match == null) continue;
      var j = i + 1;
      while (j < lines.length && lines[j].trim().isEmpty) {
        j++;
      }
      if (j >= lines.length || !lines[j].startsWith('#')) continue;
      found[match.group(1)!] =
          lines[j].replaceFirst(RegExp(r'^#+\s*'), '').trim();
    }
  }
  return found;
}

void main() {
  test('an anchor comment sits on the line above a heading', () {
    final problems = <String>[];
    for (final file in Directory(_wiki).listSync().whereType<File>()) {
      if (!file.path.endsWith('.md')) continue;
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final match = _anchorComment.firstMatch(lines[i]);
        if (match == null) continue;
        var j = i + 1;
        while (j < lines.length && lines[j].trim().isEmpty) {
          j++;
        }
        if (j >= lines.length || !lines[j].startsWith('#')) {
          problems.add('${file.uri.pathSegments.last}: '
              '${match.group(1)} names no heading');
        }
      }
    }
    expect(problems, isEmpty,
        reason: 'an anchor above a paragraph names nothing, and the help '
            'screen silently opens at the top:\n${problems.join('\n')}');
  });

  test('every anchor the app points at resolves in every language', () {
    final byLanguage = {
      for (final l in _languages) l: _anchorsOf(l),
    };
    final problems = <String>[];
    for (final anchor in HelpAnchor.all) {
      for (final language in _languages) {
        if (!byLanguage[language]!.containsKey(anchor)) {
          problems.add('$anchor is missing from $language');
        }
      }
    }
    expect(problems, isEmpty,
        reason: 'a symbol pointing at an anchor a language does not carry '
            'opens the guide at the top for that reader, with no '
            'explanation:\n${problems.join('\n')}');
  });

  test('an anchor names one heading per language, never two', () {
    for (final language in _languages) {
      final seen = <String, int>{};
      for (final file in Directory(_wiki).listSync().whereType<File>()) {
        final name = file.uri.pathSegments.last;
        if (!name.startsWith('User-$language-')) continue;
        for (final m in _anchorComment.allMatches(file.readAsStringSync())) {
          seen.update(m.group(1)!, (n) => n + 1, ifAbsent: () => 1);
        }
      }
      final duplicates = seen.entries.where((e) => e.value > 1).toList();
      expect(duplicates, isEmpty,
          reason: 'in $language, an anchor used twice makes the jump a '
              'coin toss: ${duplicates.map((e) => e.key).join(', ')}');
    }
  });

  test('every declared anchor is in HelpAnchor.all', () {
    final source =
        File('lib/core/help/help_anchors.dart').readAsStringSync();
    final declared = RegExp(r"static const \w+ =\s*'([^']+)';")
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toList();
    expect(declared, isNotEmpty);
    expect(HelpAnchor.all, containsAll(declared));
    expect(HelpAnchor.all.length, declared.length,
        reason: 'a constant missing from `all` is invisible to every '
            'check in this file');
  });

  test('an anchor is lower case and dotted', () {
    final shape = RegExp(r'^[a-z][a-z0-9]*(\.[a-z0-9-]+){2,}$');
    for (final anchor in HelpAnchor.all) {
      expect(shape.hasMatch(anchor), isTrue, reason: anchor);
    }
  });
}
