// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

/// Rewrites `metadata/de.tankstellen.fuelprices.yml` into the exact form
/// fdroiddata's `fdroid rewritemeta` job expects (#4023).
///
/// Run this instead of `fdroid rewritemeta`. The local tool cannot
/// converge — CI's ruamel keeps the word that crosses column 80 and
/// emits no trailing whitespace, the local one breaks before that word
/// and leaves a trailing space — and it additionally re-flows the
/// `prebuild:` shell commands that CI accepts as committed. See
/// `test/features/fdroid/fdroid_metadata_canonical_test.dart`.
///
/// Prints nothing and exits 0 when the file was already canonical.
void main(List<String> args) {
  final file = File('metadata/de.tankstellen.fuelprices.yml');
  if (!file.existsSync()) {
    stderr.writeln('run from the repo root: ${file.path} not found');
    exit(2);
  }

  final original = file.readAsStringSync();
  final rewritten = canonicalize(original);
  if (rewritten == original) {
    stdout.writeln('already canonical — nothing to do');
    return;
  }
  if (args.contains('--check')) {
    stderr.writeln(
      '${file.path} is not in fdroiddata CI form; run '
      '`dart run tool/fdroid_canonicalize.dart` to fix it',
    );
    exit(1);
  }
  file.writeAsStringSync(rewritten);
  stdout.writeln('rewrote ${file.path} into fdroiddata CI form');
}

/// Re-folds every plain multi-line scalar to width 80, CI's way.
String canonicalize(String source) {
  final lines = source.split('\n');
  final keyLine = RegExp(r'^(\s*)([A-Za-z][\w-]*): (\S.*)$');
  final out = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final m = keyLine.firstMatch(lines[i]);
    if (m == null) {
      out.add(lines[i].trimRight());
      continue;
    }
    final indent = m.group(1)!.length;
    if (m.group(3)!.startsWith('|') || m.group(3)!.startsWith('>')) {
      out.add(lines[i].trimRight());
      continue;
    }

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
    if (block.length == 1) {
      out.add(lines[i].trimRight());
      continue;
    }

    final firstPrefix = '${' ' * indent}${m.group(2)!}: ';
    final contIndent = ' ' * (block[1].length - block[1].trimLeft().length);
    final text = [
      block.first.substring(firstPrefix.length).trim(),
      ...block.skip(1).map((l) => l.trim()),
    ].join(' ');
    out.addAll(_fold(text, firstPrefix, contIndent));
    i = j - 1;
  }
  return out.join('\n');
}

List<String> _fold(String text, String firstPrefix, String contIndent) {
  final out = <String>[];
  var prefix = firstPrefix;
  var current = '';
  for (final word in text.split(' ')) {
    current = current.isEmpty ? word : '$current $word';
    if (prefix.length + current.length > 80) {
      out.add(prefix + current);
      prefix = contIndent;
      current = '';
    }
  }
  if (current.isNotEmpty) out.add(prefix + current);
  return out;
}
