import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#930): every `RetryNetworkTileProvider(`
/// instantiation in `lib/features/map/` MUST pass an explicit
/// `abortObsoleteRequests:` argument.
///
/// Why: flutter_map 8.x's default is `abortObsoleteRequests: true`,
/// which aborts in-flight tile HTTP requests when the viewport
/// moves. Our retry layer used to treat those cancellations as
/// transient failures and burned its 3-attempt retry budget
/// producing an error tile. Combined with
/// `evictErrorTileStrategy.notVisibleRespectMargin`, the error tile
/// then stranded on-screen as gray whenever the user stopped panning
/// with a mid-flight tile still in view.
///
/// The runtime fix is two-part:
///   1. Provider rethrows cancellation exceptions immediately (no
///      retry).
///   2. Call site passes `abortObsoleteRequests: false` to stop the
///      abort at the source.
///
/// This scan enforces part 2: even if a future author removes the
/// `false` argument (or inlines it to the default), the missing
/// keyword will trip this test and force them to re-read #930 before
/// shipping. Either explicit value is accepted — the test only
/// enforces that the argument is present and named.
void main() {
  test('every RetryNetworkTileProvider(...) in lib/features/map passes '
      'abortObsoleteRequests explicitly (#930)', () {
    final mapRoot = Directory('lib/features/map');
    expect(mapRoot.existsSync(), isTrue,
        reason: 'lib/features/map must exist — worktree misconfigured');

    final offenders = <String>[];

    for (final entity in mapRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      // Skip the provider definition file itself — it declares the
      // class and references the constructor in doc comments, but
      // does not INSTANTIATE it (the instantiations live at call
      // sites in presentation/widgets). The scan targets call sites
      // only.
      if (entity.path.replaceAll('\\', '/').endsWith(
          'lib/features/map/data/retry_network_tile_provider.dart')) {
        continue;
      }

      final text = entity.readAsStringSync();
      // Match `RetryNetworkTileProvider(` with a token boundary on
      // the left so we don't get false positives from a hypothetical
      // `MyRetryNetworkTileProvider(` subclass.
      final tokenRe = RegExp(r'(?<![A-Za-z0-9_])RetryNetworkTileProvider\(');
      for (final match in tokenRe.allMatches(text)) {
        final idx = match.start;
        final end =
            _matchingCloseParen(text, idx + 'RetryNetworkTileProvider('.length - 1);
        if (end < 0) {
          offenders.add('${entity.path} near char $idx: '
              'unbalanced RetryNetworkTileProvider(...) — cannot verify '
              'abortObsoleteRequests argument. See #930.');
          continue;
        }
        final snippet = text.substring(idx, end + 1);
        if (!snippet.contains('abortObsoleteRequests')) {
          final line = _lineNumber(text, idx);
          offenders.add('${entity.path}:$line — RetryNetworkTileProvider '
              'without explicit abortObsoleteRequests. See #930 '
              '(gray-tile regression from flutter_map cancellations).');
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
