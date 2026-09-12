// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/edge_to_edge.dart';

/// #4101 — the status-bar style is DECLARED, not re-asserted.
///
/// #3841, #4082 and #4084 each re-applied it imperatively at a moment we
/// predicted, and the black band came back twice, because anything that
/// changes it at an unpredicted moment wins — and Flutter dedupes an
/// unchanged style, so the next re-assert is a no-op. A root
/// `AnnotatedRegion` is the mechanism `AppBar` itself uses: the
/// framework re-applies it every frame and on every route.
void main() {
  test('the declared style keeps both bars transparent', () {
    expect(EdgeToEdge.overlayStyle.statusBarColor, Colors.transparent,
        reason: 'an opaque status bar IS the black band');
    expect(EdgeToEdge.overlayStyle.systemNavigationBarColor,
        Colors.transparent);
    expect(EdgeToEdge.overlayStyle.systemNavigationBarContrastEnforced,
        isFalse,
        reason: 'an enforced contrast scrim is the band at the other end');
  });

  testWidgets('an AnnotatedRegion re-applies the style after a route change '
      '— the case every imperative fix missed', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      AnnotatedRegion<SystemUiOverlayStyle>(
        value: EdgeToEdge.overlayStyle,
        child: MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle?.statusBarColor, Colors.transparent);

    // Something else takes the style over — an AppBar, a screen, an OS
    // reset. Imperatively we would now be one no-op away from the band.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Color(0xFF000000)),
    );
    await tester.pump();
    expect(SystemChrome.latestStyle?.statusBarColor, const Color(0xFF000000));

    // A route change: the framework re-applies the declared region, with
    // no call of ours involved.
    unawaited(navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('pushed')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle?.statusBarColor, Colors.transparent,
        reason: 'the declaration wins without anyone re-asserting it');
  });
}
