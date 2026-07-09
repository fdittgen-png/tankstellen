// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/location/location_consent.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Behaviour of the GDPR location-consent dialog (#561 coverage).
///
/// * Persistence helpers — `hasConsent` / `recordConsent` read and
///   write the `location_consent_given` flag on the narrow
///   [SettingsStorage] interface, NOT the legacy `location_consent`
///   key used elsewhere.
/// * Dialog UX — `show` is a pre-permission explainer with a single
///   "Continue" action that always proceeds to the OS permission
///   request (App Review 5.1.1(iv), #3535): no decline/skip button may
///   appear on the message, and it renders the GDPR bullets in every
///   shipped locale.
void main() {
  group('LocationConsentDialog — persistence', () {
    test('hasConsent returns false on a fresh storage', () {
      final storage = _FakeSettingsStorage();
      expect(LocationConsentDialog.hasConsent(storage), isFalse);
    });

    test('hasConsent returns true after recordConsent', () async {
      final storage = _FakeSettingsStorage();
      await LocationConsentDialog.recordConsent(storage);
      expect(LocationConsentDialog.hasConsent(storage), isTrue);
    });

    test('recordConsent writes the canonical key, not the legacy key',
        () async {
      final storage = _FakeSettingsStorage();
      await LocationConsentDialog.recordConsent(storage);
      // The hasConsent method reads `location_consent_given`; verify
      // the storage saw exactly that write so the two helpers agree.
      expect(storage.data, {'location_consent_given': true});
    });

    test('hasConsent is false when only the legacy key is stored', () {
      final storage = _FakeSettingsStorage()
        ..data['location_consent'] = true;
      // Legacy key must not be picked up by this narrow API — that
      // prevents a consent leak between the two storage domains.
      expect(LocationConsentDialog.hasConsent(storage), isFalse);
    });

    test('hasConsent requires strict boolean true', () {
      final storage = _FakeSettingsStorage()
        ..data['location_consent_given'] = 1;
      // Strict `== true` comparison — a numeric 1 or String must NOT
      // count as consent.
      expect(LocationConsentDialog.hasConsent(storage), isFalse);

      storage.data['location_consent_given'] = 'true';
      expect(LocationConsentDialog.hasConsent(storage), isFalse);

      storage.data['location_consent_given'] = false;
      expect(LocationConsentDialog.hasConsent(storage), isFalse);
    });
  });

  group('LocationConsentDialog — dialog behaviour (English)', () {
    testWidgets('returns true when user taps Continue', (tester) async {
      final future = await _openDialog(tester, const Locale('en'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(await future, isTrue);
    });

    testWidgets(
        'offers no decline/skip action — Continue is the only button '
        '(App Review 5.1.1(iv), #3535)', (tester) async {
      // The pre-permission explainer must always proceed to the OS
      // permission request; declining happens on the OS prompt itself.
      final future = await _openDialog(tester, const Locale('en'));
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
      expect(find.text('Decline'), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('renders all three privacy bullets', (tester) async {
      final future = await _openDialog(tester, const Locale('en'));
      expect(
        find.textContaining('sent to the fuel price API'),
        findsOneWidget,
      );
      expect(
        find.textContaining('not stored on any server'),
        findsOneWidget,
      );
      expect(
        find.textContaining('not used for advertising'),
        findsOneWidget,
      );
      // Clean up.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('shows the GDPR legal-basis line', (tester) async {
      final future = await _openDialog(tester, const Locale('en'));
      expect(find.textContaining('Art. 6(1)(a) GDPR'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('dialog is not dismissible by tapping the barrier',
        (tester) async {
      // barrierDismissible: false — tapping outside the dialog must NOT
      // resolve the future. The explainer only resolves via Continue,
      // which hands off to the OS permission prompt.
      final future = await _openDialog(tester, const Locale('en'));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      // Dialog is still up.
      expect(find.text('Continue'), findsOneWidget);
      // Clean up so the pending future doesn't leak.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(await future, isTrue);
    });
  });

  group('LocationConsentDialog — localisation', () {
    testWidgets('renders German labels for de locale', (tester) async {
      final future = await _openDialog(tester, const Locale('de'));
      expect(find.text('Standortfreigabe'), findsOneWidget);
      expect(find.text('Weiter'), findsOneWidget);
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('renders French labels for fr locale', (tester) async {
      final future = await _openDialog(tester, const Locale('fr'));
      expect(find.text('Accès à la localisation'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('renders Bulgarian labels for bg locale (#2306)',
        (tester) async {
      // #2306 — the legacy `_ConsentTexts` map did NOT cover 'bg', so
      // Bulgarian users saw an English consent surface. The strings now
      // route through AppLocalizations, so every shipped locale —
      // including 'bg' — renders in the device language.
      final future = await _openDialog(tester, const Locale('bg'));
      expect(find.text('Достъп до местоположението'), findsOneWidget);
      expect(find.text('Продължи'), findsOneWidget);
      await tester.tap(find.text('Продължи'));
      await tester.pumpAndSettle();
      await future;
    });
  });
}

/// Pumps an app whose only widget is a button that opens the consent
/// dialog, taps it, and returns the in-flight `Future<bool>` so the
/// caller can assert on its resolved value after the interaction.
Future<Future<bool>> _openDialog(WidgetTester tester, Locale locale) async {
  late Future<bool> future;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('bg'),
      ],
      locale: locale,
      home: Builder(
        builder: (ctx) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  future = LocationConsentDialog.show(ctx);
                },
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return future;
}

/// Minimal in-memory [SettingsStorage] fake. Only the two methods the
/// production code calls need to behave realistically; the remaining
/// abstract members throw so accidental usage is loud.
class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = <String, dynamic>{};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  bool get isSetupComplete => throw UnimplementedError();

  @override
  bool get isSetupSkipped => throw UnimplementedError();

  @override
  Future<void> resetSetupSkip() => throw UnimplementedError();

  @override
  Future<void> skipSetup() => throw UnimplementedError();
}
