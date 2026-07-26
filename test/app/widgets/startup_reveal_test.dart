// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3607 — the StartupReveal overlay must hold the branded splash over
// the real tree until the first screen settles (min hold + frame
// quiescence), force-reveal at the hard cap when the screen animates
// forever, and never re-play within the same process (the language-key
// tree rebuild).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/widgets/animated_splash.dart';
import 'package:tankstellen/app/widgets/startup_reveal.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

Widget host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StartupReveal(child: child),
    );

void main() {
  setUp(resetStartupRevealForTests);

  testWidgets('splash overlays the child, then reveals once the min hold '
      'elapses on a settled tree', (tester) async {
    await tester.pumpWidget(host(const Scaffold(body: Text('home'))));

    expect(find.byType(AnimatedSplash), findsOneWidget,
        reason: 'the overlay must cover the child from the first frame');
    // The child is BUILT under the overlay (loading happens behind the
    // splash) — it is present, just not visible to the user.
    expect(find.text('home'), findsOneWidget);

    // Before the min hold: still covered even though the tree is settled.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(AnimatedSplash), findsOneWidget);

    // Past the min hold + fade: revealed and the overlay unmounted.
    await tester.pump(kStartupRevealMinHold);
    await tester.pump(kStartupRevealFade);
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byType(AnimatedSplash), findsNothing,
        reason: 'settled tree + min hold elapsed = reveal');
  });

  testWidgets('a forever-animating screen is force-revealed at the cap',
      (tester) async {
    // An indeterminate spinner keeps a frame scheduled on every frame, so
    // quiescence never arrives — only the cap can reveal.
    await tester.pumpWidget(host(
      const Scaffold(body: Center(child: CircularProgressIndicator())),
    ));

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(AnimatedSplash), findsOneWidget,
        reason: 'no quiescence yet and the cap has not elapsed');

    await tester.pump(kStartupRevealCap);
    await tester.pump(kStartupRevealFade);
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byType(AnimatedSplash), findsNothing,
        reason: 'the hard cap must free the user from the splash');
  });

  testWidgets('one reveal per process — a rebuilt tree (language change) '
      'shows no second splash', (tester) async {
    await tester.pumpWidget(host(const Scaffold(body: Text('home'))));
    await tester.pump(kStartupRevealMinHold);
    await tester.pump(kStartupRevealFade);
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byType(AnimatedSplash), findsNothing);

    // Simulate the ValueKey(language.code) rebuild: a brand-new
    // StartupReveal instance in the same process.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(host(const Scaffold(body: Text('home2'))));
    expect(find.byType(AnimatedSplash), findsNothing,
        reason: 'the reveal already played this process');
    expect(find.text('home2'), findsOneWidget);
  });
}
