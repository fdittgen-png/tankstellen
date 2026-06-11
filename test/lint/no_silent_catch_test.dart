// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#565, evasion hole closed in #3163): no
/// silent catch blocks in `lib/`. A catch is *silent* when its body
/// contains no executable statement — that covers the literally-empty
/// `catch (_) {}` **and** the comment-only `catch (_) { /* meh */ }`
/// form that used to evade this gate (#3163). Silent catches hide root
/// causes — replace with at least `debugPrint('context: $e')` or route
/// through `errorLogger.log(...)`.
///
/// Two-parameter catches (`catch (e, st) { }`) with an empty or
/// comment-only body are silent too and are scanned the same way
/// (#3163 — they previously evaded both this gate and the
/// stacktrace-coverage gate, which excludes them by design).
///
/// **Opt-out** (mirrors the `catch_no_st` convention of
/// `catch_block_stacktrace_coverage_test.dart`): a *deliberate*
/// best-effort swallow — e.g. teardown where every failure mode is
/// benign — may opt out with a comment containing
/// `// ignore: silent_catch — <reason>` on the catch line, the line
/// directly above it, or inside the catch body. The reason is
/// mandatory by convention; use sparingly.
void main() {
  group('no silent catch blocks in lib/ (#565, #3163)', () {
    test('filesystem scan', () {
      final offenders = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // Skip generated files — they don't follow handwritten conventions.
        if (entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('.freezed.dart')) {
          continue;
        }

        final src = entity.readAsStringSync();
        for (final hit in findSilentCatches(src)) {
          offenders.add('${entity.path}:${hit.line}  ${hit.snippet}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Silent catch (empty or comment-only body) hides the root '
            'cause. Replace with at least `debugPrint("context: \$e")` or '
            '`errorLogger.log(...)` so the reason ends up in logs. For a '
            'deliberate best-effort swallow, opt out with '
            '`// ignore: silent_catch — <reason>`. '
            'Offending sites:\n${offenders.join("\n")}',
      );
    });

    // Regression cases for the evasion holes closed in #3163. These pin
    // the matcher itself so a future "simplification" cannot quietly
    // reopen a hole.
    group('matcher regression (#3163)', () {
      test('literally empty body is silent (original #565 behavior)', () {
        expect(findSilentCatches('try {} catch (_) {}'), hasLength(1));
        expect(findSilentCatches('try {} catch (e) {  }'), hasLength(1));
        expect(
          findSilentCatches('try {} on FormatException catch (e) {\n}'),
          hasLength(1),
        );
      });

      test('comment-only body is silent (evasion hole a)', () {
        expect(
          findSilentCatches('try {} catch (_) { /* best effort */ }'),
          hasLength(1),
        );
        expect(
          findSilentCatches(
            'try {} catch (_) {\n  // nothing we can do\n}',
          ),
          hasLength(1),
        );
        expect(
          findSilentCatches(
            'try {} catch (e) {\n  // line one\n  /* line\n  two */\n}',
          ),
          hasLength(1),
        );
        // Braces inside the comment must not hide the catch.
        expect(
          findSilentCatches(
            'try {} catch (_) {\n  // cleanup of {nested} things\n}',
          ),
          hasLength(1),
        );
      });

      test('two-parameter catch with empty/comment-only body is silent', () {
        expect(findSilentCatches('try {} catch (e, st) {}'), hasLength(1));
        expect(
          findSilentCatches('try {} catch (e, st) { /* shrug */ }'),
          hasLength(1),
        );
      });

      test('a body with any executable statement is not silent', () {
        expect(
          findSilentCatches(
            "try {} catch (e) { debugPrint('context: \$e'); }",
          ),
          isEmpty,
        );
        expect(
          findSilentCatches(
            'try {} catch (e, st) {\n  // log it\n  log(e, st);\n}',
          ),
          isEmpty,
        );
      });

      test('opt-out comment suppresses the finding', () {
        // Inside the body.
        expect(
          findSilentCatches(
            'try {} catch (_) {\n'
            '  // ignore: silent_catch — best-effort teardown\n'
            '}',
          ),
          isEmpty,
        );
        // On the catch line.
        expect(
          findSilentCatches(
            'try {} catch (_) { // ignore: silent_catch — benign\n}',
          ),
          isEmpty,
        );
        // On the line directly above.
        expect(
          findSilentCatches(
            'try {\n} \n// ignore: silent_catch — benign\ncatch (_) {\n}',
          ),
          isEmpty,
        );
        // An unrelated comment is NOT an opt-out.
        expect(
          findSilentCatches('try {} catch (_) { // ignore: lines_long\n}'),
          hasLength(1),
        );
      });
    });
  });
}

/// One silent-catch finding: 1-based [line] plus the matched [snippet].
class SilentCatch {
  const SilentCatch(this.line, this.snippet);
  final int line;
  final String snippet;
}

/// Scans [src] for silent catch blocks: a `catch (x)` / `catch (e, st)`
/// whose body contains nothing but whitespace and comments, and which
/// does not carry the `// ignore: silent_catch` opt-out (on the catch
/// line, the line above, or inside the body).
///
/// Comments are blanked out (newlines preserved, so line numbers stay
/// stable) *before* the empty-body regex runs — this is what closes the
/// comment-only evasion hole (#3163): after blanking, a comment-only
/// body is indistinguishable from an empty one.
List<SilentCatch> findSilentCatches(String src) {
  final blanked = _blankComments(src);
  final lines = src.split('\n');

  // Matches `catch (_) { }` and `catch (e, st) { }` — body empty after
  // comment-blanking (whitespace/newlines only).
  final silent = RegExp(
    r'catch\s*\(\s*\w+(?:\s*,\s*\w+)?\s*\)\s*\{\s*\}',
  );

  final findings = <SilentCatch>[];
  for (final m in silent.allMatches(blanked)) {
    final startLine = blanked.substring(0, m.start).split('\n').length - 1;
    final endLine = blanked.substring(0, m.end).split('\n').length - 1;
    // Opt-out window: line above the catch through the closing brace.
    final from = startLine > 0 ? startLine - 1 : 0;
    var optedOut = false;
    for (var i = from; i <= endLine && i < lines.length; i++) {
      if (lines[i].contains('ignore: silent_catch')) {
        optedOut = true;
        break;
      }
    }
    if (optedOut) continue;
    findings.add(
      SilentCatch(startLine + 1, src.split('\n')[startLine].trim()),
    );
  }
  return findings;
}

/// Blanks `// …` and `/* … */` comments, preserving newlines so the
/// blanked text keeps the original line numbering. Quote-aware enough
/// for this scan: a `//` inside a string literal never blanks code that
/// precedes it on the line, so a body with real statements can never be
/// blanked down to "empty" (false positives are impossible; a comment
/// containing string-quote characters merely stays conservative).
String _blankComments(String src) {
  final out = StringBuffer();
  var i = 0;
  String? quote; // active string-literal delimiter, if any
  var inLineComment = false;
  var inBlockComment = false;
  while (i < src.length) {
    final c = src[i];
    final next = i + 1 < src.length ? src[i + 1] : '';
    if (inLineComment) {
      if (c == '\n') {
        inLineComment = false;
        out.write('\n');
      }
      i++;
      continue;
    }
    if (inBlockComment) {
      if (c == '*' && next == '/') {
        inBlockComment = false;
        i += 2;
        continue;
      }
      if (c == '\n') out.write('\n');
      i++;
      continue;
    }
    if (quote != null) {
      out.write(c);
      if (c == r'\') {
        // Skip the escaped character.
        if (next.isNotEmpty) {
          out.write(next);
          i += 2;
          continue;
        }
      } else if (c == quote) {
        quote = null;
      }
      i++;
      continue;
    }
    if (c == "'" || c == '"') {
      quote = c;
      out.write(c);
      i++;
      continue;
    }
    if (c == '/' && next == '/') {
      inLineComment = true;
      i += 2;
      continue;
    }
    if (c == '/' && next == '*') {
      inBlockComment = true;
      i += 2;
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}
