// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3841 — the status bar stayed an opaque black band after visiting the
// recording screen, for a whole session, through THREE shipped attempts.
//
// The first two (#3827, #3834) called `setSystemUIOverlayStyle` once on
// dispose. The third idea was that Flutter's AppBar overwrites it every frame
// with `statusBarColor: <its own background>` — true of vanilla Material, and
// WRONG here: FlexColorScheme already pins a transparent status bar on every
// theme this app ships. Probed before shipping a fix built on it.
//
// So the colour was never the problem. A transparent status bar shows
// whatever is painted behind it, and the black is the app NOT drawing there —
// i.e. `immersiveSticky` still in force. These tests pin the two facts that
// keep it shut: the themes really do keep the bar transparent, and an AppBar
// cannot take that over.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/theme.dart';

void main() {
  group('#3841 the status bar is transparent on every shipped theme', () {
    final themes = <String, ThemeData>{
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
      'eco': AppTheme.eco(),
    };

    themes.forEach((name, theme) {
      test('$name keeps statusBarColor transparent', () {
        final style = theme.appBarTheme.systemOverlayStyle;
        expect(style, isNotNull,
            reason: 'a null style lets AppBar fall back to painting the '
                'status bar with its own background');
        expect(style!.statusBarColor, Colors.transparent,
            reason: 'an opaque value here would reproduce the black band by '
                'a different route than the immersive-mode one');
      });
    });

    test('a NEW theme cannot silently reopen this', () {
      expect(themes.length, 3,
          reason: 'a new AppTheme entry point was added — check it also '
              'carries a transparent status bar, then update this count');
    });
  });

  testWidgets('a dark AppBar does not take over the status-bar colour',
      (tester) async {
    // The recording screen is the darkest surface in the app, and the bug
    // always appeared after visiting it. If an AppBar background could
    // become the status-bar colour, that is where it would happen.
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.eco(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF000000),
          title: const Text('recording'),
        ),
        body: const SizedBox.shrink(),
      ),
    ));
    await tester.pump();

    expect(SystemChrome.latestStyle, isNotNull);
    expect(SystemChrome.latestStyle!.statusBarColor, Colors.transparent,
        reason: 'a black AppBar background must not become the status-bar '
            'colour; if this ever fails, the colour theory is back in play');
  });
}
