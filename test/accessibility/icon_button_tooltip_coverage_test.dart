import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#566): every `IconButton(...)` in `lib/`
/// must have a `tooltip:` parameter. A missing tooltip fails accessibility
/// for TalkBack/VoiceOver users because the button has no accessible name.
///
/// The scan is a balanced-paren walk so nested IconButtons and multi-line
/// declarations are handled correctly. If this test fails, add a `tooltip:`
/// parameter to the reported line — prefer a localized key from app_en.arb
/// with an English fallback.
void main() {
  test('every IconButton in lib/ has a tooltip (#566)', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();

      for (final match in RegExp(r'IconButton\s*\(').allMatches(src)) {
        final start = match.start;
        int openParen = src.indexOf('(', start);
        int depth = 0;
        int? end;
        for (int i = openParen; i < src.length; i++) {
          final c = src[i];
          if (c == '(') depth++;
          if (c == ')') {
            depth--;
            if (depth == 0) {
              end = i;
              break;
            }
          }
        }
        if (end == null) continue;

        final body = src.substring(start, end + 1);
        if (!body.contains('tooltip:')) {
          final line = src.substring(0, start).split('\n').length;
          offenders.add('${entity.path}:$line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'IconButton without tooltip: breaks TalkBack/VoiceOver. '
          'Add `tooltip: l10n?.tooltipX ?? "X"` at these sites:\n'
          '${offenders.join("\n")}',
    );
  });
}
