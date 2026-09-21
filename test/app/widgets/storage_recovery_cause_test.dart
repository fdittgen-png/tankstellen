// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/widgets/storage_recovery_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4116 — the recovery screen must not claim damage it has not been
/// told about.
///
/// `_initStorage`'s generic catch routes EVERY storage-phase fault to
/// this screen: a cipher failure, a TraceStorage failure, or a bug in our
/// own code. It told all of them "the storage file appears to be damaged
/// … clear the app's storage or reinstall. Your favourites and history
/// cannot be restored." A recursion shipped in #4115 produced exactly
/// that screen on every launch, so the app spent an evening advising
/// users to destroy their data to work around a one-line bug.
///
/// The asymmetry is deliberate: claiming "not damaged" when it is
/// damaged costs the user a restart, while claiming "damaged" when it is
/// not costs them their favourites and history permanently. So the
/// default is the harmless branch.
///
/// #4118 added the third cause — a restored install whose KeyStore key
/// could not follow its boxes. Clearing storage IS right there, but for
/// a different reason and with a different consequence, and the
/// corruption copy can say neither.
void main() {
  Future<AppLocalizations> pump(WidgetTester tester,
      {required StorageRecoveryCause cause}) async {
    await tester.pumpWidget(StorageRecoveryHost(cause: cause));
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Column)));
  }

  testWidgets('a NON-corruption fault never advises clearing storage',
      (tester) async {
    final l10n = await pump(tester, cause: StorageRecoveryCause.unknown);

    expect(find.text(l10n.startupFailureTitle), findsOneWidget);
    expect(find.text(l10n.startupFailureMessage), findsOneWidget);
    expect(find.text(l10n.startupFailureGuidance), findsOneWidget);

    // The harmful copy must be absent, not merely de-emphasised.
    expect(find.text(l10n.storageRecoveryGuidance), findsNothing,
        reason: 'clearing storage deletes favourites and history and fixes '
            'nothing when the fault is a bug in the app');
    expect(find.text(l10n.storageRecoveryMessage), findsNothing,
        reason: 'the file is not known to be damaged');
  });

  testWidgets('the non-corruption message says the data is intact',
      (tester) async {
    final l10n = await pump(tester, cause: StorageRecoveryCause.unknown);
    // Whatever the wording per locale, the reassurance has to be there:
    // a user who reads "storage problem" and nothing else assumes the
    // worst and wipes.
    expect(l10n.startupFailureMessage.toLowerCase(),
        anyOf(contains('not been touched'), contains('intact')));
    expect(l10n.startupFailureGuidance.toLowerCase(),
        contains('do not clear'),
        reason: 'the guidance must actively countermand the advice the '
            'corruption screen gives, or a user who saw that screen '
            'yesterday will clear storage anyway');
  });

  testWidgets('established corruption DOES keep the clear-storage advice',
      (tester) async {
    final l10n = await pump(tester, cause: StorageRecoveryCause.corruptBox);
    expect(find.text(l10n.storageRecoveryTitle), findsOneWidget);
    expect(find.text(l10n.storageRecoveryGuidance), findsOneWidget,
        reason: 'when Hive reports a file it cannot recover, clearing '
            'storage genuinely is the recovery');
    expect(find.text(l10n.startupFailureGuidance), findsNothing);
  });

  testWidgets('a restored install is told it was a RESTORE, not damage',
      (tester) async {
    final l10n = await pump(tester, cause: StorageRecoveryCause.keyLost);

    expect(find.text(l10n.storageKeyLostTitle), findsOneWidget);
    expect(find.text(l10n.storageKeyLostGuidance), findsOneWidget);

    // Not the corruption copy: the files are intact, and "damaged"
    // implies a repair that AES-256 with a lost key does not have.
    expect(find.text(l10n.storageRecoveryMessage), findsNothing);
    expect(find.text(l10n.startupFailureGuidance), findsNothing);
  });

  testWidgets('the restore copy names the exit the corruption copy cannot',
      (tester) async {
    final l10n = await pump(tester, cause: StorageRecoveryCause.keyLost);
    // Whatever the wording per locale, the one piece of good news has to
    // survive translation: the synced data is not gone.
    expect(l10n.storageKeyLostGuidance, contains('TankSync'),
        reason: 'clearing storage without being told the synced data '
            'comes back reads as "lose everything"');
    expect(l10n.storageRecoveryGuidance, isNot(contains('TankSync')),
        reason: 'the corruption case has no such promise to make — this '
            'test exists so the two copies cannot be collapsed back '
            'into one');
  });

  testWidgets('the default is the HARMLESS branch', (tester) async {
    await tester.pumpWidget(const StorageRecoveryHost());
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(Column)));
    expect(find.text(l10n.startupFailureTitle), findsOneWidget,
        reason: 'a caller that forgets to say which fault it hit must not '
            'get the one that costs the user data');
  });
}
