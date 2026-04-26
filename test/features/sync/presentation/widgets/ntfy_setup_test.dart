// Widget tests for `lib/features/sync/presentation/widgets/ntfy_setup.dart`.
//
// Covers state-driven rendering and post-frame notifier wiring.
//
// Both `syncStateProvider` and `ntfySetupControllerProvider` are
// overridden with fake notifier subclasses to avoid the Supabase /
// Hive static dependencies that the real notifiers reach into.
//
// Refs #561.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/sync/presentation/widgets/ntfy_setup.dart';
import 'package:tankstellen/features/sync/providers/ntfy_setup_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';

class _FakeSyncState extends SyncState {
  _FakeSyncState(this._config);
  final SyncConfig _config;
  @override
  SyncConfig build() => _config;
}

class _FakeNtfySetupController extends NtfySetupController {
  _FakeNtfySetupController(this._initial);
  final NtfySetupState _initial;

  int ensureTopicCalls = 0;
  String? lastEnsureUserId;
  int loadInitialStateCalls = 0;
  String? lastLoadUserId;

  @override
  NtfySetupState build() => _initial;

  @override
  void ensureTopic(String userId) {
    ensureTopicCalls++;
    lastEnsureUserId = userId;
  }

  @override
  Future<void> loadInitialState(String userId) async {
    loadInitialStateCalls++;
    lastLoadUserId = userId;
  }

  @override
  Future<bool> setEnabled(bool value, String userId) async {
    state = state.copyWith(enabled: value);
    return true;
  }

  @override
  Future<bool> sendTestNotification() async => true;
}

void main() {
  Future<_FakeNtfySetupController> pumpCard(
    WidgetTester tester, {
    SyncConfig syncConfig = const SyncConfig(),
    NtfySetupState ntfyState = const NtfySetupState(),
  }) async {
    final fakeController = _FakeNtfySetupController(ntfyState);
    await pumpApp(
      tester,
      const NtfySetupCard(),
      overrides: [
        syncStateProvider.overrideWith(() => _FakeSyncState(syncConfig)),
        ntfySetupControllerProvider.overrideWith(() => fakeController),
      ],
    );
    return fakeController;
  }

  /// Pumps the card without `pumpAndSettle` so widget states that mount
  /// an indeterminate `CircularProgressIndicator` (which never settles in
  /// fake-async time) do not deadlock the test.
  Future<_FakeNtfySetupController> pumpCardNoSettle(
    WidgetTester tester, {
    SyncConfig syncConfig = const SyncConfig(),
    NtfySetupState ntfyState = const NtfySetupState(),
  }) async {
    final fakeController = _FakeNtfySetupController(ntfyState);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncStateProvider.overrideWith(() => _FakeSyncState(syncConfig)),
          ntfySetupControllerProvider.overrideWith(() => fakeController),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(body: NtfySetupCard()),
        ),
      ),
    );
    // Single pump flushes l10n + post-frame callbacks without waiting for
    // the spinner animation to settle.
    await tester.pump();
    return fakeController;
  }

  group('NtfySetupCard', () {
    testWidgets('renders title and toggle for any state', (tester) async {
      await pumpCard(tester);
      expect(find.text('Push Notifications (ntfy.sh)'), findsOneWidget);
      expect(find.text('Enable ntfy.sh push'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('shows "connect first" hint and disables toggle when userId is null',
        (tester) async {
      await pumpCard(tester);

      expect(
        find.textContaining('Connect TankSync first'),
        findsOneWidget,
      );
      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.onChanged, isNull);
    });

    testWidgets('does not call ensureTopic / loadInitialState when userId is null',
        (tester) async {
      final ctrl = await pumpCard(tester);
      expect(ctrl.ensureTopicCalls, 0);
      expect(ctrl.loadInitialStateCalls, 0);
    });

    testWidgets('calls ensureTopic via post-frame when userId set and topic null',
        (tester) async {
      final ctrl = await pumpCard(
        tester,
        syncConfig: const SyncConfig(userId: 'user-1'),
      );
      expect(ctrl.ensureTopicCalls, greaterThanOrEqualTo(1));
      expect(ctrl.lastEnsureUserId, 'user-1');
    });

    testWidgets('does not call ensureTopic when topic is already set',
        (tester) async {
      final ctrl = await pumpCard(
        tester,
        syncConfig: const SyncConfig(userId: 'user-1'),
        ntfyState: const NtfySetupState(topic: 'tankstellen-user-1'),
      );
      expect(ctrl.ensureTopicCalls, 0);
    });

    testWidgets(
        'calls loadInitialState via post-frame when userId set and not yet loaded',
        (tester) async {
      final ctrl = await pumpCard(
        tester,
        syncConfig: const SyncConfig(userId: 'user-2'),
      );
      expect(ctrl.loadInitialStateCalls, greaterThanOrEqualTo(1));
      expect(ctrl.lastLoadUserId, 'user-2');
    });

    testWidgets('does not call loadInitialState when initial load is done',
        (tester) async {
      final ctrl = await pumpCard(
        tester,
        syncConfig: const SyncConfig(userId: 'user-2'),
        ntfyState: const NtfySetupState(
          topic: 'tankstellen-user-2',
          initialLoadDone: true,
        ),
      );
      expect(ctrl.loadInitialStateCalls, 0);
    });

    testWidgets('toggle reflects state.enabled = false', (tester) async {
      await pumpCard(
        tester,
        syncConfig: const SyncConfig(userId: 'user-3'),
        ntfyState: const NtfySetupState(
          topic: 'tankstellen-user-3',
          initialLoadDone: true,
        ),
      );
      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.value, isFalse);
    });

    testWidgets('toggle reflects state.enabled = true and renders topic + send-test',
        (tester) async {
      await pumpCard(
        tester,
        syncConfig: const SyncConfig(userId: 'user-4'),
        ntfyState: const NtfySetupState(
          enabled: true,
          topic: 'tankstellen-user-4',
          initialLoadDone: true,
        ),
      );
      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.value, isTrue);

      // Topic URL row appears only when enabled and topic non-null.
      expect(find.text('Topic URL'), findsOneWidget);
      expect(find.textContaining('https://ntfy.sh/tankstellen-user-4'),
          findsOneWidget);
      expect(find.text('Send test notification'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows toggling spinner while isToggling = true', (tester) async {
      await pumpCardNoSettle(
        tester,
        syncConfig: const SyncConfig(userId: 'user-5'),
        ntfyState: const NtfySetupState(
          topic: 'tankstellen-user-5',
          initialLoadDone: true,
          isToggling: true,
        ),
      );
      // Spinner is mounted in the SwitchListTile secondary slot.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // While toggling, onChanged is disabled to prevent re-entry.
      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.onChanged, isNull);
    });

    testWidgets(
        'send-test button is disabled and shows spinner while isSendingTest = true',
        (tester) async {
      await pumpCardNoSettle(
        tester,
        syncConfig: const SyncConfig(userId: 'user-6'),
        ntfyState: const NtfySetupState(
          enabled: true,
          topic: 'tankstellen-user-6',
          initialLoadDone: true,
          isSendingTest: true,
        ),
      );

      final sendBtn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(sendBtn.onPressed, isNull);
      // The button shows a spinner instead of the send icon when sending.
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('toggle tap routes through notifier.setEnabled', (tester) async {
      final ctrl = await pumpCard(
        tester,
        syncConfig: const SyncConfig(userId: 'user-7'),
        ntfyState: const NtfySetupState(
          topic: 'tankstellen-user-7',
          initialLoadDone: true,
        ),
      );

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Fake setEnabled flips state.enabled to true.
      expect(ctrl.state.enabled, isTrue);
    });
  });
}
