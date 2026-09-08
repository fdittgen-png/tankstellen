// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4005 — the wiki is in the repository now, so it can be checked the
// way the code is.
//
// Sparkilo's user guide exists in seven languages. Before this it lived
// only in the GitHub wiki, where nothing compared them: a page added to
// the English guide and forgotten in Danish looked exactly like a page
// that was never meant to exist in Danish. Seven copies drift silently
// and nobody finds out until a reader does.
//
// These are the two checks that catch drift without pretending to check
// translation quality, which no test can do:
//
//  * every language carries the same SET of pages;
//  * a page's images exist in the wiki's own image folders.
//
// Deliberately NOT checked: heading counts or word counts. A translation
// that says the same thing in fewer sentences is a good translation, and
// a lint that forbids it teaches people to pad.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _languages = ['da', 'de', 'en', 'es', 'fr', 'it', 'pt'];
const _wiki = 'docs/wiki';

/// `User-en-Finding-Stations.md` → `Finding-Stations`.
String? _pageOf(String name, String language) {
  final prefix = 'User-$language-';
  if (!name.startsWith(prefix) || !name.endsWith('.md')) return null;
  return name.substring(prefix.length, name.length - 3);
}

Set<String> _pagesFor(String language) {
  final dir = Directory(_wiki);
  return {
    for (final f in dir.listSync().whereType<File>())
      ?_pageOf(f.uri.pathSegments.last, language),
  };
}

void main() {
  test('the wiki is in the repository', () {
    expect(Directory(_wiki).existsSync(), isTrue,
        reason: 'docs/wiki is the source of truth; the GitHub wiki is a '
            'mirror of it. See docs/guides/wiki-mirror.md.');
  });

  test('every language carries the same set of user pages', () {
    final english = _pagesFor('en');
    expect(english, isNotEmpty, reason: 'no English user pages found');
    final problems = <String>[];
    for (final language in _languages) {
      if (language == 'en') continue;
      final pages = _pagesFor(language);
      for (final missing in english.difference(pages)) {
        problems.add('$language is missing User-$language-$missing.md');
      }
      for (final extra in pages.difference(english)) {
        problems.add('$language has User-$language-$extra.md with no '
            'English counterpart');
      }
    }
    expect(problems, isEmpty,
        reason: 'the user guide must exist in every language it claims to '
            'support, or the claim is false:\n${problems.join('\n')}');
  });

  test('an image a page references exists', () {
    // The wiki keeps its images in `guide/` and `screenshots/`; the
    // markdown is in the repository and the images stay in the wiki, so
    // this check runs against whichever of the two is present.
    final folders = [
      Directory('$_wiki/guide'),
      Directory('$_wiki/screenshots'),
    ].where((d) => d.existsSync()).toList();
    if (folders.isEmpty) return; // images live in the wiki only — nothing to check
    final have = {
      for (final d in folders)
        for (final f in d.listSync().whereType<File>())
          '${d.path.split('/').last}/${f.uri.pathSegments.last}',
    };
    final reference = RegExp(r'(?:src="|\]\()((?:guide|screenshots)/[^")]+)');
    final missing = <String>[];
    for (final f in Directory(_wiki).listSync().whereType<File>()) {
      if (!f.path.endsWith('.md')) continue;
      for (final m in reference.allMatches(f.readAsStringSync())) {
        final ref = m.group(1)!;
        if (!have.contains(ref)) {
          missing.add('${f.uri.pathSegments.last} → $ref');
        }
      }
    }
    expect(missing, isEmpty,
        reason: 'a page points at an image that is not there:\n'
            '${missing.join('\n')}');
  });
}
