import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/sync/presentation/screens/sync_setup_screen.dart';
import 'package:tankstellen/features/sync/providers/sync_setup_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Regression guard for #1234 (twin of #1186).
///
/// `SyncSetupScreen`'s `_onAuthSubmit` catch block was leaking the raw
/// `e.toString()` — including the supabase URL and the
/// `AuthRetryableFetchException` type name — straight into the form
/// error pill. The fix routes the exception through `friendlyAuthError`
/// the same way `auth_screen.dart` already did.
///
/// This test pumps the screen pre-positioned at the auth step with a
/// fake `SyncState` whose `connectCommunity()` throws a `SocketException`
/// carrying the exact failure shape the user reported, taps the
/// "Connect anonymously" button, and asserts the rendered pill is the
/// friendly localized message — never the raw exception.

class _FakeSyncState extends SyncState {
  _FakeSyncState(this._throwOnConnect);

  final Object _throwOnConnect;

  @override
  SyncConfig build() => const SyncConfig();

  @override
  Future<void> connectCommunity() async {
    throw _throwOnConnect;
  }
}

class _AuthStepSyncSetupController extends SyncSetupController {
  @override
  SyncSetupState build() => const SyncSetupState(
        step: SyncSetupStep.auth,
        selectedMode: SyncMode.community,
      );
}

void main() {
  group('SyncSetupScreen auth-step error mapping (#1234)', () {
    Future<void> pumpAtAuth(
      WidgetTester tester, {
      required Object thrown,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStateProvider.overrideWith(() => _FakeSyncState(thrown)),
            syncSetupControllerProvider
                .overrideWith(() => _AuthStepSyncSetupController()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: SyncSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'SocketException with supabase URL renders friendly text, '
      'never the raw exception or the project URL',
      (tester) async {
        const e = SocketException(
            "Failed host lookup: 'klelxnkzrxlpzuddhpfg.supabase.co' "
            '(errno = 7)');
        await pumpAtAuth(tester, thrown: e);

        await tester.tap(find.text('Connect anonymously'));
        await tester.pumpAndSettle();

        expect(find.text('No network connection. Try again later.'),
            findsOneWidget);
        expect(find.textContaining('SocketException'), findsNothing);
        expect(find.textContaining('klelxnkzrxlpzuddhpfg'), findsNothing);
        expect(find.textContaining('errno'), findsNothing);
      },
    );

    testWidgets(
      'AuthRetryableFetchException-shaped string renders friendly text, '
      'never the type name',
      (tester) async {
        final e = Exception(
            'AuthRetryableFetchException(message: ClientException with '
            "SocketException: Failed host lookup: 'klelxnkzrxlpzuddhpfg."
            "supabase.co' (errno = 7), uri=https://klelxnkzrxlpzuddhpfg."
            'supabase.co/auth/v1/signup?, statusCode: null)');
        await pumpAtAuth(tester, thrown: e);

        await tester.tap(find.text('Connect anonymously'));
        await tester.pumpAndSettle();

        expect(find.text('No network connection. Try again later.'),
            findsOneWidget);
        expect(find.textContaining('AuthRetryableFetchException'), findsNothing);
        expect(find.textContaining('klelxnkzrxlpzuddhpfg'), findsNothing);
      },
    );
  });
}
