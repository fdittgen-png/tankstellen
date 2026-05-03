import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/vehicle/data/catalog_reresolve_detector.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/catalog_reresolve_snackbar_host.dart';
import 'package:tankstellen/features/vehicle/providers/catalog_reresolve_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [CatalogReresolveSnackbarHost] (#1396).
///
/// We override [catalogReresolveCandidatesProvider] with hand-built
/// values and substitute an in-memory [SettingsStorage] so the host
/// is exercised end-to-end without touching Hive or the reference
/// catalog asset.
void main() {
  Widget hostUnderTest({
    required AsyncValue<List<CatalogReresolveCandidate>> candidates,
  }) {
    final settings = _FakeSettingsStorage();
    return ProviderScope(
      overrides: [
        // Provide an in-memory SettingsStorage so the host's
        // `markCatalogReresolveSuggested` Hive write doesn't crash
        // on the un-opened settings box.
        settingsStorageProvider.overrideWithValue(settings),
        catalogReresolveCandidatesProvider.overrideWith((ref) {
          // `overrideWith` for a Future provider takes a function
          // returning a Future. Collapse the AsyncValue into a
          // matching resolution. The loading branch returns a
          // Completer's future that's never completed — no timer is
          // scheduled, so the test framework's "no pending timers"
          // invariant holds.
          return candidates.when(
            data: (v) => Future<List<CatalogReresolveCandidate>>.value(v),
            loading: () =>
                Completer<List<CatalogReresolveCandidate>>().future,
            error: (_, _) => Future<List<CatalogReresolveCandidate>>.value(
                const <CatalogReresolveCandidate>[]),
          );
        }),
      ],
      child:
          // ignore: prefer_const_constructors
          MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: CatalogReresolveSnackbarHost(
            child: Center(child: Text('child')),
          ),
        ),
      ),
    );
  }

  group('CatalogReresolveSnackbarHost', () {
    testWidgets('renders the wrapped child verbatim when no candidates',
        (tester) async {
      await tester.pumpWidget(hostUnderTest(
        candidates: const AsyncValue.data(<CatalogReresolveCandidate>[]),
      ));
      await tester.pump();
      // Two pumps to let the snackbar scheduler settle if it had
      // something to do; with empty candidates it must NOT do
      // anything.
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('child'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows a snackbar with make/model when a candidate is pending',
        (tester) async {
      const candidate = CatalogReresolveCandidate(
        vehicleId: 'v1',
        make: 'Dacia',
        model: 'Duster',
        resolvedReferenceVehicleId: 'dacia-duster-ii-2017-2023',
        resolvedFuelType: 'petrol',
      );

      await tester.pumpWidget(hostUnderTest(
        candidates:
            const AsyncValue.data(<CatalogReresolveCandidate>[candidate]),
      ));
      // Provider future + post-frame schedule; pump twice instead of
      // pumpAndSettle (the snackbar is a long-lived 8s animation we
      // don't want to drain).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Dacia Duster'),
        findsOneWidget,
        reason: 'snackbar content should include the make + model',
      );
      expect(find.text('Update'), findsOneWidget,
          reason: 'snackbar should expose the Update CTA');
    });

    testWidgets('does nothing while candidates are still loading',
        (tester) async {
      await tester.pumpWidget(hostUnderTest(
        candidates: const AsyncValue.loading(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('child'), findsOneWidget);
    });
  });
}

/// Minimal in-memory [SettingsStorage] for the host widget tests.
///
/// The host writes a Hive flag in `markCatalogReresolveSuggested`
/// when a snackbar fires; the fake captures the writes so the test
/// path doesn't depend on a real Hive box being open.
class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = <String, dynamic>{};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
