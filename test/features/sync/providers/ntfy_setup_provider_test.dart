// Unit tests for `lib/features/sync/providers/ntfy_setup_provider.dart`.
//
// Scope:
//   * `NtfySetupState` — pure value object, default ctor + copyWith.
//   * `NtfySetupController.ensureTopic` — delegates to the pure
//     `NtfyService.generateTopic('tankstellen-$userId')` helper.
//
// Future work (Refs #561):
//   * `loadInitialState`, `setEnabled`, `sendTestNotification` are
//     coupled to `TankSyncClient.client` (a static Supabase singleton)
//     and `NtfyService.sendTestNotification` (Dio HTTP). They cannot be
//     overridden via Riverpod because the controller instantiates its
//     own `NtfyService` and reads `TankSyncClient` statically. Covering
//     them requires either making those seams injectable or running the
//     widget that hosts the controller against a fake Supabase backend.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/providers/ntfy_setup_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('NtfySetupState', () {
    test('default constructor uses safe defaults', () {
      const s = NtfySetupState();
      expect(s.enabled, isFalse);
      expect(s.isSendingTest, isFalse);
      expect(s.isToggling, isFalse);
      expect(s.initialLoadDone, isFalse);
      expect(s.topic, isNull);
    });

    test('custom constructor stores all fields', () {
      const s = NtfySetupState(
        enabled: true,
        isSendingTest: true,
        isToggling: true,
        initialLoadDone: true,
        topic: 'tankstellen-abc',
      );
      expect(s.enabled, isTrue);
      expect(s.isSendingTest, isTrue);
      expect(s.isToggling, isTrue);
      expect(s.initialLoadDone, isTrue);
      expect(s.topic, 'tankstellen-abc');
    });

    test('copyWith updates each field independently', () {
      const base = NtfySetupState();

      final enabled = base.copyWith(enabled: true);
      expect(enabled.enabled, isTrue);
      expect(enabled.isSendingTest, isFalse);
      expect(enabled.isToggling, isFalse);
      expect(enabled.initialLoadDone, isFalse);
      expect(enabled.topic, isNull);

      final sending = base.copyWith(isSendingTest: true);
      expect(sending.isSendingTest, isTrue);
      expect(sending.enabled, isFalse);

      final toggling = base.copyWith(isToggling: true);
      expect(toggling.isToggling, isTrue);
      expect(toggling.enabled, isFalse);

      final loaded = base.copyWith(initialLoadDone: true);
      expect(loaded.initialLoadDone, isTrue);
      expect(loaded.enabled, isFalse);

      final topic = base.copyWith(topic: 'tankstellen-xyz');
      expect(topic.topic, 'tankstellen-xyz');
      expect(topic.enabled, isFalse);
    });

    test('copyWith with no args returns identical-valued state', () {
      const base = NtfySetupState(
        enabled: true,
        isSendingTest: true,
        isToggling: true,
        initialLoadDone: true,
        topic: 'tankstellen-abc',
      );
      final copy = base.copyWith();
      expect(copy.enabled, base.enabled);
      expect(copy.isSendingTest, base.isSendingTest);
      expect(copy.isToggling, base.isToggling);
      expect(copy.initialLoadDone, base.initialLoadDone);
      expect(copy.topic, base.topic);
    });
  });

  group('NtfySetupController', () {
    test('initial build state matches NtfySetupState defaults', () {
      final c = makeContainer();
      final s = c.read(ntfySetupControllerProvider);
      expect(s.enabled, isFalse);
      expect(s.isSendingTest, isFalse);
      expect(s.isToggling, isFalse);
      expect(s.initialLoadDone, isFalse);
      expect(s.topic, isNull);
    });

    test('ensureTopic with null topic derives "tankstellen-{userId}"', () {
      final c = makeContainer();
      c.read(ntfySetupControllerProvider.notifier).ensureTopic('abc');
      expect(c.read(ntfySetupControllerProvider).topic, 'tankstellen-abc');
    });

    test('ensureTopic is a no-op when topic is already set', () {
      final c = makeContainer();
      final ctrl = c.read(ntfySetupControllerProvider.notifier);
      ctrl.ensureTopic('first');
      expect(c.read(ntfySetupControllerProvider).topic, 'tankstellen-first');
      // Second call with a different userId must not overwrite.
      ctrl.ensureTopic('second');
      expect(c.read(ntfySetupControllerProvider).topic, 'tankstellen-first');
    });

    test('ensureTopic with empty userId still derives a topic prefix', () {
      final c = makeContainer();
      c.read(ntfySetupControllerProvider.notifier).ensureTopic('');
      expect(c.read(ntfySetupControllerProvider).topic, 'tankstellen-');
    });
  });
}
