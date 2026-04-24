import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_switch_event.dart';
import 'package:tankstellen/core/country/country_switch_listener.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Mutable holder that stands in for the test's controllable event
/// source. The override of `countrySwitchEventProvider` reads from this
/// holder; tests change `current` and call `container.invalidate(...)`
/// to fire a new event.
class _EventHolder {
  CountrySwitchEvent? current;
}

/// Minimal fake of [ActiveProfile] that records every `switchProfile`
/// call without touching the profile repository. Subclassing the real
/// notifier is required because `activeProfileProvider` is a generated
/// `Notifier` provider whose `overrideWith` factory expects an
/// `ActiveProfile` subclass.
class _RecordingActiveProfile extends ActiveProfile {
  _RecordingActiveProfile(this.calls);

  final List<String> calls;

  @override
  UserProfile? build() => null;

  @override
  Future<void> switchProfile(String id) async {
    calls.add(id);
  }
}

const _frenchProfile = UserProfile(
  id: 'p-fr',
  name: 'France Profile',
  countryCode: 'FR',
);

CountrySwitchEvent _autoSwitchToFr() => const CountrySwitchEvent(
      action: CountrySwitchAction.autoSwitch,
      detectedCountryCode: 'FR',
      matchingProfile: _frenchProfile,
    );

CountrySwitchEvent _suggestFr() => const CountrySwitchEvent(
      action: CountrySwitchAction.suggest,
      detectedCountryCode: 'FR',
      matchingProfile: _frenchProfile,
    );

CountrySwitchEvent _noProfileFr() => const CountrySwitchEvent(
      action: CountrySwitchAction.noProfile,
      detectedCountryCode: 'FR',
    );

CountrySwitchEvent _autoSwitchTo(String code, UserProfile profile) =>
    CountrySwitchEvent(
      action: CountrySwitchAction.autoSwitch,
      detectedCountryCode: code,
      matchingProfile: profile,
    );

/// Builds the widget tree with a controllable `countrySwitchEventProvider`
/// and a recording fake `activeProfileProvider`. Returns the
/// [ProviderContainer] and the event [holder] so tests can drive events.
Future<
    ({
      ProviderContainer container,
      _EventHolder holder,
      List<String> switchCalls
    })> _pump(WidgetTester tester) async {
  final calls = <String>[];
  final holder = _EventHolder();
  final container = ProviderContainer(
    overrides: [
      // Re-route the listener's input through a holder we own. After
      // mutating `holder.current`, invalidate the provider to make the
      // listener observe a new value.
      countrySwitchEventProvider.overrideWith((ref) => holder.current),
      // Replace the real ActiveProfile with one that records calls
      // instead of touching the (unprovided) repository.
      activeProfileProvider.overrideWith(
        () => _RecordingActiveProfile(calls),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: CountrySwitchListener(
            child: Text('child-content'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return (container: container, holder: holder, switchCalls: calls);
}

/// Pushes [event] through the listener: mutate the holder, invalidate
/// the provider, force a synchronous read so the new value is computed,
/// then pump so widgets observe the change.
///
/// The synchronous read is the key: `ref.listen` only delivers when the
/// new value is materialised, and an invalidated provider does not
/// recompute until something reads it. The container.read here plays
/// the role of the real app's `ref.watch` from a parent widget.
Future<void> _fire(
  WidgetTester tester,
  ({ProviderContainer container, _EventHolder holder, List<String> switchCalls})
      h,
  CountrySwitchEvent? event,
) async {
  h.holder.current = event;
  h.container.invalidate(countrySwitchEventProvider);
  // Force materialisation of the new value before the next frame.
  h.container.read(countrySwitchEventProvider);
  // First pump: ref.listen delivers the new value.
  await tester.pump();
  // Second pump: any UI scheduled by the handler is built.
  await tester.pump();
}

void main() {
  group('CountrySwitchListener', () {
    testWidgets('renders child and shows nothing when event is null',
        (tester) async {
      final harness = await _pump(tester);

      expect(find.text('child-content'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.switchCalls, isEmpty);
    });

    testWidgets(
        'autoSwitch event calls switchProfile and shows success SnackBar',
        (tester) async {
      final harness = await _pump(tester);

      await _fire(tester, harness, _autoSwitchToFr());

      expect(harness.switchCalls, ['p-fr']);
      expect(find.byType(SnackBar), findsOneWidget);
      // Snackbar copy is `Switched to profile "<name>" (<country>)` (en).
      expect(
        find.textContaining('France Profile'),
        findsOneWidget,
      );
    });

    testWidgets(
        'suggest event shows AlertDialog; tapping Switch calls switchProfile',
        (tester) async {
      final harness = await _pump(tester);

      await _fire(tester, harness, _suggestFr());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // Country flag (icon) and France text in the prompt.
      expect(find.text('France Profile'), findsNothing,
          reason:
              'Profile name only appears interpolated inside the prompt copy');
      // The dialog has both Dismiss and Switch buttons.
      expect(find.text('Switch'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.switchCalls, ['p-fr']);
    });

    testWidgets('suggest event — Dismiss closes dialog without switching',
        (tester) async {
      final harness = await _pump(tester);

      await _fire(tester, harness, _suggestFr());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.switchCalls, isEmpty);
    });

    testWidgets('noProfile event shows informational AlertDialog',
        (tester) async {
      final harness = await _pump(tester);

      await _fire(tester, harness, _noProfileFr());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // The dialog title comes from the localization key
      // `noProfileForCountryTitle` ("No profile for this country" in EN).
      expect(find.text('No profile for this country'), findsOneWidget);
      // Single OK action (hardcoded literal in the listener).
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      // noProfile must not call switchProfile — there is no profile to switch to.
      expect(harness.switchCalls, isEmpty);
    });

    testWidgets(
        'cooldown — second event for the same country within the window '
        'is suppressed (no extra switchProfile, no snackbar)',
        (tester) async {
      final harness = await _pump(tester);

      // Fire #1 — autoSwitch, should be honored.
      await _fire(tester, harness, _autoSwitchToFr());
      expect(harness.switchCalls, ['p-fr']);
      expect(find.byType(SnackBar), findsOneWidget);

      // Reset to null then re-fire the same FR autoSwitch — _markDismissed
      // was called on #1 so this second fire must be suppressed by the
      // cooldown (the listener early-returns for `_isOnCooldown`).
      await _fire(tester, harness, null);
      await _fire(tester, harness, _autoSwitchToFr());

      expect(harness.switchCalls, ['p-fr'],
          reason:
              'Second same-country autoSwitch within 10 minutes must not '
              're-trigger switchProfile.');
    });

    testWidgets(
        'cooldown is per-country — switching to a different country fires',
        (tester) async {
      final harness = await _pump(tester);

      await _fire(tester, harness, _autoSwitchToFr());
      expect(harness.switchCalls, ['p-fr']);

      // A different country must NOT be suppressed by the FR cooldown.
      const dePrf = UserProfile(
        id: 'p-de',
        name: 'Germany Profile',
        countryCode: 'DE',
      );
      await _fire(tester, harness, null);
      await _fire(tester, harness, _autoSwitchTo('DE', dePrf));

      expect(harness.switchCalls, ['p-fr', 'p-de'],
          reason: 'Cooldown is keyed on detectedCountryCode — a switch to '
              'a different country must still be honored.');
    });
  });
}
