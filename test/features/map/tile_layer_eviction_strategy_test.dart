import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces that every `TileLayer` in the codebase sets an
/// `evictErrorTileStrategy`. Default is `EvictErrorTileStrategy.none`,
/// which caches failed tile fetches and never retries them — the
/// root cause of the persistent-gray-tile user reports (#757).
///
/// Pattern mirrors `test/security/no_plaintext_station_endpoints_test.dart`
/// — a lightweight AST-free grep scan over the lib/ tree. The bug
/// class it prevents (a new `TileLayer` instance without the
/// eviction strategy) is high-frequency enough to warrant the
/// explicit static check.
void main() {
  test('every TileLayer(...) sets evictErrorTileStrategy (#757)', () {
    final libRoot = Directory('lib');
    final offenders = <String>[];

    for (final entity in libRoot.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      // Token-boundary match: `TileLayer(` preceded by a non-word
      // char (space / newline / `[` / `,` / `(`). Avoids the
      // `buildTileLayer(` false positive in the MapProvider
      // abstraction.
      final tokenRe = RegExp(r'(?<![A-Za-z0-9_])TileLayer\(');
      for (final match in tokenRe.allMatches(text)) {
        final idx = match.start;
        {
        // Find the matching close paren; naive but sufficient for
        // well-formed Dart. The TileLayer constructor is short and
        // balanced.
        final end = _matchingCloseParen(text, idx + 'TileLayer('.length - 1);
        if (end < 0) {
          offenders.add('${entity.path} near char $idx: '
              'unbalanced TileLayer(...) — cannot verify strategy');
          continue;
        }
        final snippet = text.substring(idx, end + 1);
        if (!snippet.contains('evictErrorTileStrategy')) {
          final line = _lineNumber(text, idx);
          offenders.add('${entity.path}:$line — TileLayer without '
              'evictErrorTileStrategy');
        }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: offenders.join('\n'),
    );
  });
}

int _matchingCloseParen(String text, int openIdx) {
  var depth = 0;
  for (var i = openIdx; i < text.length; i++) {
    final c = text[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

int _lineNumber(String text, int index) {
  var line = 1;
  for (var i = 0; i < index; i++) {
    if (text.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}
