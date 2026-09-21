// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/pinned_save_bar.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4119 — a pinned bottom action row must reserve the system
/// navigation inset.
///
/// The profile edit sheet's Save/Delete footer did not, and because a
/// `DraggableScrollableSheet` runs to the physical screen bottom, the
/// Android back/home targets were drawn over a DESTRUCTIVE button. Five
/// field captures showed it at every scroll position.
///
/// This pins the contract on the core widget that already had it right,
/// plus the shape of the bug: a footer whose bottom padding does not
/// include the inset.
void main() {
  const inset = EdgeInsets.only(bottom: 48);

  testWidgets('PinnedSaveBar keeps its CTA clear of the nav inset',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: inset),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: PinnedSaveBar(onSave: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = tester.getRect(find.byType(FilledButton));
    final screenBottom = tester.getSize(find.byType(MaterialApp)).height;
    expect(screenBottom - button.bottom, greaterThanOrEqualTo(inset.bottom),
        reason: 'the CTA must end at least the nav-bar height above the '
            'screen edge, or the OS draws its own targets over it');
  });
}
