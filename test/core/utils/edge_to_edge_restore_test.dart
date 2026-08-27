// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3827 — leaving the recording screen left the status bar an opaque black
// band for the rest of the session, on every other screen, until restart.
//
// The cause was not one bad line but one bad line copied six times: every
// screen that went immersive restored `SystemUiMode.manual` instead of the
// `SystemUiMode.edgeToEdge` that startup had established, and none re-applied
// the transparent overlay style. `manual` is not the inverse of `edgeToEdge`.
//
// A widget test cannot observe the platform's real bar colour, so the thing
// worth pinning is the invariant that actually broke: exactly one place knows
// how to undo immersive mode, and no screen hand-rolls it.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/edge_to_edge.dart';

/// Every Dart file under lib/, so a NEW screen is covered the day it lands.
Iterable<File> _libDartFiles() sync* {
  for (final e in Directory('lib').listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) yield e;
  }
}

void main() {
  group('#3827 one place undoes immersive mode', () {
    test('no screen restores SystemUiMode.manual by hand', () {
      final offenders = <String>[];
      for (final file in _libDartFiles()) {
        // edge_to_edge.dart documents the old call in a doc comment so the
        // next reader knows what was wrong; that mention is not a call site.
        if (file.path.endsWith('core/utils/edge_to_edge.dart')) continue;
        if (file.readAsStringSync().contains('SystemUiMode.manual')) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'restoring `SystemUiMode.manual` re-shows the bars but '
              'leaves edge-to-edge OFF, so Android paints the status bar '
              'opaque black — and it survives leaving the screen. Call '
              'EdgeToEdge.restore() instead. Offenders: $offenders');
    });

    test('every screen that goes immersive also restores', () {
      // Going immersive without restoring is the same user-visible bug by a
      // different route, so pair the two calls per file.
      final unpaired = <String>[];
      for (final file in _libDartFiles()) {
        final src = file.readAsStringSync();
        if (!src.contains('SystemUiMode.immersiveSticky')) continue;
        if (!src.contains('EdgeToEdge.restore()')) unpaired.add(file.path);
      }
      expect(unpaired, isEmpty,
          reason: 'these go immersive but never restore, so the bars stay '
              'hidden or opaque after the screen is gone: $unpaired');
    });

    test('every dispose that can go immersive restores UNCONDITIONALLY', () {
      // #3834 — #3827 fixed WHAT the restore does and left it behind a
      // `if (_pinned)` / `if (!pinned) return` gate, so on the path users
      // actually took it never ran and the bars stayed immersive for the
      // rest of the session. The app's normal appearance must not depend
      // on a bool surviving to dispose.
      final offenders = <String>[];
      for (final file in _libDartFiles()) {
        final src = file.readAsStringSync();
        if (!src.contains('EdgeToEdge.restore()')) continue;
        for (final m in RegExp(r'(?:void|Future<void>)\s+\w*[Dd]ispose\w*\s*\([^)]*\)\s*(?:async\s*)?\{')
            .allMatches(src)) {
          // Scan the dispose body to its closing brace.
          var depth = 0, i = m.end - 1;
          final start = i;
          do {
            if (src[i] == '{') depth++;
            if (src[i] == '}') depth--;
            i++;
          } while (depth > 0 && i < src.length);
          final body = src.substring(start, i);
          if (!body.contains('EdgeToEdge.restore()')) continue;
          // The restore must appear OUTSIDE any pin-state conditional.
          final gated = RegExp(
                  r'if\s*\(\s*!?\s*_?pinned\s*\)[^}]*EdgeToEdge\.restore\(\)')
              .hasMatch(body);
          // ...and must not be unreachable behind an early return.
          final earlyReturn = RegExp(r'if\s*\(\s*!\s*_?pinned\s*\)\s*return\s*;')
              .hasMatch(body.substring(0, body.indexOf('EdgeToEdge.restore()')));
          if (gated || earlyReturn) offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'restore() is idempotent and costs one platform call, so '
              'running it needlessly is free — skipping it leaves the user '
              'with a black status bar until they restart. Offenders: '
              '$offenders');
    });

    testWidgets('restore re-establishes exactly what enable() set',
        (tester) async {
      // The regression was restore() and enable() disagreeing, so assert they
      // drive the platform identically rather than trusting the source text.
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemChrome.setEnabledSystemUIMode' ||
            call.method == 'SystemChrome.setSystemUIOverlayStyle') {
          calls.add('${call.method}:${call.arguments}');
        }
        return null;
      });

      await EdgeToEdge.restore();
      // The overlay style is committed in a post-frame callback, so it is
      // still null until a frame runs.
      await tester.pump();

      expect(calls.where((c) => c.contains('setEnabledSystemUIMode')).single,
          contains('edgeToEdge'),
          reason: 'restore must return to edge-to-edge, not manual');
      // The overlay style is batched to the next frame rather than sent as an
      // immediate platform message, so assert the value Flutter actually
      // holds — re-showing the bars WITHOUT this is how the black band
      // appeared.
      expect(SystemChrome.latestStyle, EdgeToEdge.overlayStyle,
          reason: 'restore must re-apply the transparent overlay style');

      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });
}
