// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/diesel_rev_prompt.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [DieselRevPrompt] (#1621) — the diesel rev prompt
/// that keys the broken-MAP probe off a confirmed rev.

void main() {
  testWidgets('renders the prompt title, body and confirm button',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DieselRevPrompt(
          window: const Duration(seconds: 4),
          onResult: (revved) => result = revved,
        ),
      ),
    ));

    expect(find.text('Rev the engine'), findsOneWidget);
    expect(
      find.textContaining('blip the throttle'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dieselRevPromptConfirm')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(result, isNull, reason: 'no outcome before the user acts');

    // Settle the countdown so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('tapping the confirm button reports a revved=true outcome',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DieselRevPrompt(
          window: const Duration(seconds: 4),
          onResult: (revved) => result = revved,
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('dieselRevPromptConfirm')));
    await tester.pump();

    expect(result, isTrue);
  });

  testWidgets('the countdown elapsing reports a revved=false outcome',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DieselRevPrompt(
          window: const Duration(seconds: 3),
          onResult: (revved) => result = revved,
        ),
      ),
    ));

    expect(result, isNull);
    // Advance past the rev window without confirming.
    await tester.pump(const Duration(seconds: 4));

    expect(result, isFalse);
  });

  testWidgets('a confirm tap after the window still fires onResult only once',
      (tester) async {
    var fireCount = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DieselRevPrompt(
          window: const Duration(seconds: 2),
          onResult: (_) => fireCount++,
        ),
      ),
    ));

    // Window elapses → first (and only) fire.
    await tester.pump(const Duration(seconds: 3));
    expect(fireCount, 1);

    // A late tap must not fire a second outcome.
    await tester.tap(find.byKey(const Key('dieselRevPromptConfirm')));
    await tester.pump();
    expect(fireCount, 1);
  });
}
