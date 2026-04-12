import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against hardcoded user-facing strings in presentation code.
///
/// Detects `Text('literal')` and `Text("literal")` patterns in widget files
/// that should use `AppLocalizations.of(context)?.key ?? 'fallback'` instead.
///
/// A baseline count is maintained so existing violations don't break CI,
/// but new ones are caught.
void main() {
  test('hardcoded Text() count does not increase', () {
    final featuresDir = Directory('lib/features');
    expect(featuresDir.existsSync(), isTrue);

    // Matches: Text('literal'), Text("literal"), title: 'literal', etc.
    // Excludes: patterns with ?? (already using l10n fallback),
    //           patterns with $ (string interpolation with variables),
    //           patterns that reference l10n/l/AppLocalizations
    final hardcodedTextPattern = RegExp(
      r"""(?:const\s+)?Text\(\s*['"][A-Z][^'"$]*['"]\s*\)"""
      r"""|(?:const\s+)?Text\(\s*['"][a-z][^'"$]{3,}['"]\s*\)""",
    );

    final violations = <String>[];

    for (final entity in featuresDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('.g.dart')) continue;
      if (path.endsWith('.freezed.dart')) continue;
      if (!path.contains('/presentation/')) continue;

      final lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Skip lines that already use l10n pattern
        if (line.contains('??') || line.contains('l10n') || line.contains('AppLocalizations')) continue;
        // Skip comments
        if (line.trimLeft().startsWith('//')) continue;

        for (final match in hardcodedTextPattern.allMatches(line)) {
          final text = match.group(0)!;
          // Skip very short strings (likely identifiers, not UI text)
          if (text.length < 12) continue;
          violations.add('$path:${i + 1}: $text');
        }
      }
    }

    // Baseline: number of known hardcoded strings as of 2026-04-12.
    // This number should only go DOWN over time as strings are localized.
    // If this test fails, you added a new hardcoded string — use l10n instead.
    const baseline = 120;

    expect(
      violations.length,
      lessThanOrEqualTo(baseline),
      reason: 'Hardcoded user-facing strings increased! '
          'Found ${violations.length} (baseline: $baseline).\n'
          'New violations:\n${violations.take(20).join('\n')}\n'
          'Use AppLocalizations.of(context)?.key ?? \'fallback\' instead.',
    );
  });
}
