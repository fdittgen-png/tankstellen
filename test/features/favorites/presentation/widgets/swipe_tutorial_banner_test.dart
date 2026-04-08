import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/swipe_tutorial_banner.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Fake [SettingsStorage] that stores values in a plain map.
class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _store = {};

  @override
  dynamic getSetting(String key) => _store[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _store[key] = value;
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

void main() {
  late _FakeSettingsStorage fakeSettings;

  Future<void> pumpBanner(
    WidgetTester tester, {
    _FakeSettingsStorage? settings,
  }) async {
    fakeSettings = settings ?? _FakeSettingsStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStorageProvider.overrideWithValue(fakeSettings),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(body: SwipeTutorialBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SwipeTutorialBanner', () {
    testWidgets('shows banner on first visit', (tester) async {
      await pumpBanner(tester);

      expect(find.byIcon(Icons.swipe), findsOneWidget);
      expect(
        find.text('Swipe right to navigate, swipe left to remove'),
        findsOneWidget,
      );
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('hides banner after tapping dismiss', (tester) async {
      await pumpBanner(tester);

      // Banner is visible
      expect(find.byIcon(Icons.swipe), findsOneWidget);

      // Tap "Got it"
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // Banner is gone
      expect(find.byIcon(Icons.swipe), findsNothing);

      // Flag is persisted
      expect(
        fakeSettings.getSetting(StorageKeys.swipeTutorialShown),
        isTrue,
      );
    });

    testWidgets('does not show banner when already dismissed', (tester) async {
      final settings = _FakeSettingsStorage();
      await settings.putSetting(StorageKeys.swipeTutorialShown, true);

      await pumpBanner(tester, settings: settings);

      // Banner should not appear
      expect(find.byIcon(Icons.swipe), findsNothing);
    });

    testWidgets('renders correctly in German locale', (tester) async {
      fakeSettings = _FakeSettingsStorage();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStorageProvider.overrideWithValue(fakeSettings),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('de'),
            home: Scaffold(body: SwipeTutorialBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Nach rechts wischen zum Navigieren, nach links zum Entfernen'),
        findsOneWidget,
      );
      expect(find.text('Verstanden'), findsOneWidget);
    });

    testWidgets('has correct semantics label', (tester) async {
      await pumpBanner(tester);

      final semantics = tester.getSemantics(find.byType(Container).first);
      expect(
        semantics.label,
        contains('Swipe right to navigate'),
      );
    });
  });
}
