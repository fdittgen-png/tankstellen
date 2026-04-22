import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tankstellen/app/app.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/consent/presentation/screens/gdpr_consent_screen.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/setup/presentation/screens/onboarding_wizard_screen.dart';
import 'package:tankstellen/features/setup/presentation/widgets/welcome_step.dart';

/// Integration tests for the fresh-install onboarding wizard (#569).
///
/// These tests guard against the #555 regression where the wizard was
/// silently bypassed on a clean install. Each test starts from a fully
/// cleared Hive store so the router and providers see the true
/// "first launch" state.
///
/// Scope (from #569):
///   1. Empty Hive -> `isSetupComplete` is false.
///   2. Router redirects unsetup user to /consent then /setup.
///   3. Wizard advances through its full step set (6 for no-API-key
///      countries, 7 for API-key countries — Germany is the default).
///   4. Wizard completion creates a default profile.
///   5. After wizard with a non-default country selection, the active
///      profile records that country.
///
/// Test 6 from the issue body (EV favorite round-trip) is deferred to a
/// follow-up PR — the EV-entity hardening on #691 is still in flux.
Future<void> _clearAllHiveBoxes() async {
  // Close any open boxes from a prior test so we can safely wipe their
  // underlying files. HiveStorage.init() will reopen them fresh.
  await Hive.close();
  // Nuke every box this app touches. We recreate them on the next
  // HiveStorage.init() call so each test starts from a true fresh-install
  // state (the setup_skipped flag from an earlier test MUST not leak).
  const names = [
    'settings',
    'favorites',
    'cache',
    'profiles',
    'price_history',
    'alerts',
    'obd2_baselines',
    'obd2_trip_history',
    'achievements',
  ];
  for (final name in names) {
    try {
      await Hive.deleteBoxFromDisk(name);
    } catch (e) {
      // Box may not exist yet on the very first run — that is fine, we
      // just wanted to remove whatever was there. Log so any other
      // error still shows up in the integration-test output.
      debugPrint('fresh_install_wizard_test: deleteBoxFromDisk($name): $e');
    }
  }
}

Future<HiveStorage> _bootFreshStorage() async {
  await _clearAllHiveBoxes();
  await HiveStorage.init();
  final storage = HiveStorage();
  // Pin locale to English so findByText('Next', 'Back', 'Skip', 'Get
  // started', 'All set!', 'Accept all') all match regardless of the
  // device locale the integration test happens to run under. Stored
  // under the legacy 'active_language_code' key because no profile
  // exists yet (the wizard creates it on completion).
  await storage.putSetting('active_language_code', 'en');
  return storage;
}

/// Pumps [TankstellenApp] inside a fresh `ProviderScope` and lets routing
/// + initial providers settle. Returns the `ProviderContainer` so callers
/// can assert on provider values.
Future<ProviderContainer> _pumpFreshApp(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TankstellenApp(),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 3));
  return container;
}

/// Clicks "Accept all" on the consent screen to advance the router
/// into the wizard. The consent screen exposes two CTAs; the all-accept
/// path is the fastest way to deterministically reach `/setup`.
Future<void> _acceptConsentAll(WidgetTester tester) async {
  // The consent screen renders two buttons: "Accept selected" and
  // "Accept all". "Accept all" is stable across locales because the
  // English label is the widest. Tap by text first, fallback to the
  // last FilledButton on screen if the label moves in a future l10n
  // refactor.
  final acceptAll = find.text('Accept all');
  if (acceptAll.evaluate().isNotEmpty) {
    await tester.tap(acceptAll.first);
  } else {
    final filled = find.byType(FilledButton);
    await tester.tap(filled.last);
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Taps the wizard's primary "Next" button (or "Get started" on the
/// final step, which carries the check icon).
Future<void> _tapNext(WidgetTester tester) async {
  // Try by label first, localized English. Falls back to the lone
  // FilledButton.icon on the screen.
  final next = find.text('Next');
  if (next.evaluate().isNotEmpty) {
    await tester.tap(next.first);
  } else {
    final finish = find.text('Get started');
    if (finish.evaluate().isNotEmpty) {
      await tester.tap(finish.first);
    } else {
      await tester.tap(find.byType(FilledButton).last);
    }
  }
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Taps the optional "Skip" button on the current step.
Future<void> _tapSkip(WidgetTester tester) async {
  final skip = find.text('Skip');
  expect(skip, findsOneWidget,
      reason: 'Expected a Skip button on the current optional step');
  await tester.tap(skip.first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Taps the "Get started" button that appears on the final (Done) step.
Future<void> _tapGetStarted(WidgetTester tester) async {
  final finish = find.text('Get started');
  expect(finish, findsOneWidget,
      reason: 'Expected Get started button on the final wizard step');
  await tester.tap(finish.first);
  // Completion persists the profile + routes home. Give the async work
  // and navigation plenty of room to settle.
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Selects the given country on the Country/Language step. The step
/// renders each country as a ChoiceChip labeled with `<flag> <name>`.
Future<void> _selectCountry(WidgetTester tester, CountryConfig country) async {
  // Prefer tapping by country name text, which sits inside the ChoiceChip
  // for that country. Wrap in ensureVisible so a chip beneath the fold
  // is scrolled into the viewport first.
  final label = find.textContaining(country.name);
  expect(label, findsAtLeast(1),
      reason: 'Country label "${country.name}" should be tappable');
  await tester.ensureVisible(label.first);
  await tester.pumpAndSettle();
  await tester.tap(label.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fresh install wizard flow (#569)', () {
    setUp(() async {
      await _clearAllHiveBoxes();
    });

    tearDownAll(() async {
      // Leave the test device in a deterministic state for the next
      // integration suite.
      await _clearAllHiveBoxes();
    });

    testWidgets(
        'test 1: empty Hive -> isSetupComplete is false',
        (tester) async {
      final storage = await _bootFreshStorage();
      expect(storage.isSetupComplete, isFalse,
          reason:
              'A freshly-cleared Hive must report setup as incomplete — a true '
              'value leaks the #555 regression where the app silently skipped '
              'the wizard.');
      expect(storage.isSetupSkipped, isFalse);
    });

    testWidgets(
        'test 2: router redirects unsetup user away from / through /consent '
        'to /setup', (tester) async {
      await _bootFreshStorage();
      await _pumpFreshApp(tester);

      // First hop: /consent. Anything on '/' must be gated until consent
      // is given, so the user sees the GDPR screen — not the shell.
      expect(find.byType(GdprConsentScreen), findsOneWidget,
          reason:
              'Router must land on GdprConsentScreen for a fresh install');
      expect(find.byType(NavigationBar), findsNothing,
          reason: 'Shell must not be reachable before consent + setup');

      // Second hop: /setup. After accepting consent, the redirect logic
      // in router.dart sends the user to the onboarding wizard.
      await _acceptConsentAll(tester);
      expect(find.byType(OnboardingWizardScreen), findsOneWidget,
          reason:
              'Router must land on the wizard after consent when setup is '
              'incomplete');
      expect(find.byType(WelcomeStep), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing,
          reason:
              'Shell must not be reachable until the wizard completes');
    });

    testWidgets(
        'test 3: wizard advances through every step and ends on '
        '"All set!"', (tester) async {
      await _bootFreshStorage();
      await _pumpFreshApp(tester);
      await _acceptConsentAll(tester);

      // Germany is the default country in the DE/locale-derived startup
      // path and requires an API key, so the wizard exposes 7 steps:
      // Welcome, Country, Vehicles, Preferences, Landing, API Key, Done.
      // Countries without an API key trim Landing/API-Key merge and run
      // 6 steps. We accept either shape; what matters for #569 is that
      // the wizard RUNS every step and lands on "All set!".
      expect(find.byType(WelcomeStep), findsOneWidget);
      expect(
          find.textContaining(RegExp(r'^1 / [67]$')), findsOneWidget,
          reason:
              'Progress indicator should read "1 / 6" or "1 / 7" on the '
              'welcome step');

      // Walk steps forward until we see the completion button. Each
      // iteration either taps Next (for non-optional steps) or Skip
      // (Vehicles + API Key). Cap iterations so a misbehaving wizard
      // can't spin forever.
      const maxSteps = 10;
      var stepsWalked = 0;
      while (find.text('Get started').evaluate().isEmpty &&
          stepsWalked < maxSteps) {
        if (find.text('Skip').evaluate().isNotEmpty) {
          await _tapSkip(tester);
        } else {
          await _tapNext(tester);
        }
        stepsWalked++;
      }

      expect(find.text('Get started'), findsOneWidget,
          reason:
              'Wizard must reach the "Get started" CTA on the final step; '
              'walked $stepsWalked steps from Welcome');
      expect(find.text('All set!'), findsOneWidget,
          reason:
              'Completion step must render the localized "All set!" headline');
    });

    testWidgets(
        'test 4: wizard completion creates a default active profile',
        (tester) async {
      await _bootFreshStorage();
      final container = await _pumpFreshApp(tester);

      // Pre-condition: no profile exists yet. app_initializer's
      // ensureDefaultProfile is NOT invoked here (we use TankstellenApp
      // directly, not AppInitializer.run), so the only path that creates
      // the profile is the wizard itself — exactly the flow #569 guards.
      expect(container.read(activeProfileProvider), isNull,
          reason:
              'Fresh install without wizard completion must have a null '
              'active profile');

      await _acceptConsentAll(tester);

      // Walk the wizard from Welcome through Done with default
      // selections on every step.
      const maxSteps = 10;
      var stepsWalked = 0;
      while (find.text('Get started').evaluate().isEmpty &&
          stepsWalked < maxSteps) {
        if (find.text('Skip').evaluate().isNotEmpty) {
          await _tapSkip(tester);
        } else {
          await _tapNext(tester);
        }
        stepsWalked++;
      }
      await _tapGetStarted(tester);

      // The wizard's _completeSetup() calls ensureDefaultProfile +
      // updateProfile + refresh. The active profile should now be
      // non-null.
      final profile = container.read(activeProfileProvider);
      expect(profile, isNotNull,
          reason:
              'Wizard completion must create a default profile — this is '
              'the #555 regression guard');
      expect(profile!.name, isNotEmpty);
    });

    testWidgets(
        'test 5: wizard with FR country selection writes FR to the '
        'active profile', (tester) async {
      await _bootFreshStorage();
      final container = await _pumpFreshApp(tester);
      await _acceptConsentAll(tester);

      // Welcome is step 1. Advance to Country step (step 2).
      expect(find.byType(WelcomeStep), findsOneWidget);
      await _tapNext(tester);

      // Country step: pick France. France does NOT require an API key
      // so the wizard shape drops from 7 steps to 6 for the remaining
      // traversal. Our loop below doesn't depend on the number.
      await _selectCountry(tester, Countries.france);

      // Sanity: active country provider must reflect the selection
      // immediately so the wizard branches to the no-api-key layout.
      expect(container.read(activeCountryProvider).code, 'FR');

      // Walk the rest of the wizard from the Country step through Done.
      const maxSteps = 10;
      var stepsWalked = 0;
      while (find.text('Get started').evaluate().isEmpty &&
          stepsWalked < maxSteps) {
        if (find.text('Skip').evaluate().isNotEmpty) {
          await _tapSkip(tester);
        } else {
          await _tapNext(tester);
        }
        stepsWalked++;
      }
      await _tapGetStarted(tester);

      final profile = container.read(activeProfileProvider);
      expect(profile, isNotNull,
          reason: 'Wizard must still create a profile for FR');
      expect(profile!.countryCode, 'FR',
          reason:
              'Country selection during the wizard must propagate to '
              'UserProfile.countryCode on completion');
    });
  });
}
