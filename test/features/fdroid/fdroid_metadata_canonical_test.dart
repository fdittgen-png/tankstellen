// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The fdroiddata `rewritemeta` job, reimplemented (#4023).
///
/// ## Why this exists
///
/// fdroiddata's pipeline runs `fdroid rewritemeta` and fails if the file
/// it produces differs from the one committed. That job has blocked the
/// MR three times, always on line wrapping inside the `AntiFeatures`
/// block scalar, never on content.
///
/// The obvious fix — run `fdroid rewritemeta` locally before pushing —
/// does not work here, and the reason is worth writing down because it
/// cost three round-trips:
///
///   * CI does not use a released fdroidserver. `.gitlab-ci.yml`
///     downloads `fdroidserver` **master** as a tarball on every run.
///   * But the version is not the cause. Master's `rewritemeta` run
///     locally produces byte-identical output to the packaged 2.4.5
///     release, and neither matches CI.
///   * The difference is in **`ruamel.yaml`'s emitter**. Both fold at
///     width 80. CI's generation keeps the word that crosses column 80
///     and emits no trailing whitespace; the local one breaks *before*
///     that word and leaves a trailing space. No fdroidserver version
///     changes that.
///   * Local `rewritemeta` also re-flows the `prebuild:` / `build:`
///     shell command strings, which CI accepts as committed — so
///     running it introduces new diffs on top of not converging.
///
/// So this test implements CI's rule directly. It needs no fdroidserver,
/// no ruamel and no network, and it fails in the same place CI would —
/// before a push, not after a red pipeline.
///
/// ## The rule
///
/// A folded block scalar wraps at **width 80**: append words until the
/// line's length would exceed 80, emit including the word that crossed,
/// then continue on the next line at the block's indent. No trailing
/// whitespace, ever.
void main() {
  final file = File('metadata/de.tankstellen.fuelprices.yml');

  group('fdroiddata metadata is in CI-canonical form (#4023)', () {
    test('every folded block scalar matches what rewritemeta would emit', () {
      final offenders = <String>[];
      for (final block in _foldedBlocks(file.readAsStringSync())) {
        final expected = foldToWidth(
          block.text,
          firstPrefix: block.firstPrefix,
          contIndent: block.contIndent,
        );
        if (block.lines.join('\n') != expected.join('\n')) {
          offenders.add(
            'line ${block.startLine} (${block.key}):\n'
            '  committed:\n${block.lines.map((l) => "    |$l|").join("\n")}\n'
            '  canonical:\n${expected.map((l) => "    |$l|").join("\n")}',
          );
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'These block scalars are not in the form fdroiddata CI '
            "would write, so the MR's `fdroid rewritemeta` job will go red. "
            'Do NOT run `fdroid rewritemeta` locally to fix it — see this '
            "file's docstring. Re-fold to width 80, keeping the word that "
            'crosses the boundary:\n\n${offenders.join("\n\n")}',
      );
    });

    test('no trailing whitespace anywhere', () {
      final bad = <String>[];
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i] != lines[i].trimRight()) bad.add('line ${i + 1}');
      }
      // The local ruamel leaves one on every folded line, so this is the
      // fastest tell that someone ran the local tool over the file.
      expect(bad, isEmpty,
          reason: 'Trailing whitespace — the signature of a local '
              '`fdroid rewritemeta` run. ${bad.join(", ")}');
    });

    test('the fold rule reproduces the exact block CI asked for '
        '— fidelity check', () {
      // Pinned from the reviewer's own paste of the CI diff on 0685ae58.
      // If this stops matching, the rule drifted from CI's and every
      // other assertion here is measuring the wrong thing (#2348).
      const ci = <String>[
        '    en-US: By default the map loads tiles through a developer-hosted proxy (a fixed',
        '      Supabase edge-function URL), and the optional community price reports / TankSync',
        '      features ship a default configuration (assets/tanksync_config.json) pointing',
        '      to the same developer-hosted Supabase instance. The server software is FOSS',
        '      and TankSync is designed for self-hosting (the app provides the SQL to run your',
        "      own instance), but the shipped defaults use the developer's instance. The FDROID_LIBRE",
        '      define these build entries pass removes both defaults, but the code reading',
        '      it landed after the commit pinned here, so it has no effect on this build; this',
        '      entry is removed when the pin moves to a release containing it.',
      ];
      const prefix = '    en-US: ';
      final text = [
        ci.first.substring(prefix.length),
        ...ci.skip(1).map((l) => l.trim()),
      ].join(' ');

      expect(
        foldToWidth(text, firstPrefix: prefix, contIndent: '      '),
        ci,
        reason: 'the implemented rule no longer reproduces CI output',
      );

      // The local tool's rule — break BEFORE the crossing word — must
      // NOT reproduce it, or the test would pass on a locally-mangled
      // file too.
      final localRule = _foldBreakingBefore(text, prefix, '      ');
      expect(localRule, isNot(ci));
      expect(localRule.first.endsWith('(a'), isTrue,
          reason: 'the local rule stops one word earlier');
    });
  });

  group('the mirror really is the MR body (#3481)', () {
    test('the file is a comment header followed by the recipe, nothing else',
        () {
      final lines = file.readAsStringSync().split('\n');
      final firstYaml =
          lines.indexWhere((l) => l.isNotEmpty && !l.startsWith('#'));
      expect(firstYaml, greaterThan(0),
          reason: 'the tankstellen-only header must come first');
      // Everything the MR carries starts here. A `#` comment below this
      // point would be in the MR body too — fdroiddata accepts that, but
      // it has drifted before, so keep the split unambiguous.
      final body = lines.sublist(firstYaml);
      expect(body.first, 'AntiFeatures:',
          reason: 'the body must start where the MR body starts');
      expect(body.where((l) => l.startsWith('#')), isEmpty,
          reason: 'no comments inside the mirrored body — the MR has none, '
              'and a comment here is invisible drift');
    });
  });
}

/// Folds [text] the way fdroiddata CI's ruamel does.
///
/// Words are appended until the line would exceed [width]; the word that
/// crosses is kept on that line, then a new line starts at [contIndent].
List<String> foldToWidth(
  String text, {
  required String firstPrefix,
  required String contIndent,
  int width = 80,
}) {
  final out = <String>[];
  var prefix = firstPrefix;
  var current = '';
  for (final word in text.split(' ')) {
    current = current.isEmpty ? word : '$current $word';
    if (prefix.length + current.length > width) {
      out.add(prefix + current);
      prefix = contIndent;
      current = '';
    }
  }
  if (current.isNotEmpty) out.add(prefix + current);
  return out;
}

/// The LOCAL ruamel's rule — break before the crossing word. Only used to
/// prove the two differ.
List<String> _foldBreakingBefore(
    String text, String firstPrefix, String contIndent) {
  final out = <String>[];
  var prefix = firstPrefix;
  var current = '';
  for (final word in text.split(' ')) {
    final candidate = current.isEmpty ? word : '$current $word';
    if (current.isNotEmpty && prefix.length + candidate.length > 80) {
      out.add(prefix + current);
      prefix = contIndent;
      current = word;
    } else {
      current = candidate;
    }
  }
  if (current.isNotEmpty) out.add(prefix + current);
  return out;
}

/// One folded block scalar found in the file.
class _Block {
  _Block({
    required this.key,
    required this.startLine,
    required this.lines,
    required this.firstPrefix,
    required this.contIndent,
  });

  final String key;
  final int startLine;
  final List<String> lines;
  final String firstPrefix;
  final String contIndent;

  /// The logical paragraph: folded lines rejoin with a single space.
  String get text => [
        lines.first.substring(firstPrefix.length),
        ...lines.skip(1).map((l) => l.trim()),
      ].join(' ');
}

/// Every `key: value` whose value continues on more-indented plain lines.
///
/// Only plain multi-line scalars are folded by rewritemeta; a `|` or `>`
/// scalar keeps its author's line breaks, and a single-line value has
/// nothing to fold.
Iterable<_Block> _foldedBlocks(String source) sync* {
  final lines = source.split('\n');
  final keyLine = RegExp(r'^(\s*)([A-Za-z][\w-]*): (\S.*)$');
  for (var i = 0; i < lines.length; i++) {
    final m = keyLine.firstMatch(lines[i]);
    if (m == null) continue;
    final indent = m.group(1)!.length;
    final value = m.group(3)!;
    if (value.startsWith('|') || value.startsWith('>')) continue;
    // Continuation lines are indented deeper than the key and are not
    // themselves keys or list items.
    final block = <String>[lines[i]];
    var j = i + 1;
    while (j < lines.length) {
      final next = lines[j];
      if (next.trim().isEmpty) break;
      final nextIndent = next.length - next.trimLeft().length;
      if (nextIndent <= indent) break;
      if (next.trimLeft().startsWith('- ')) break;
      if (keyLine.hasMatch(next)) break;
      block.add(next);
      j++;
    }
    if (block.length == 1) continue;
    yield _Block(
      key: m.group(2)!,
      startLine: i + 1,
      lines: block,
      firstPrefix: '${' ' * indent}${m.group(2)!}: ',
      contIndent: ' ' * (block[1].length - block[1].trimLeft().length),
    );
    i = j - 1;
  }
}
