import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/providers/obd2_connection_state_provider.dart';

void main() {
  group('Obd2ConnectionStatus state machine (#784)', () {
    test('initial state is idle with no adapter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.idle);
      expect(s.adapterName, isNull);
      expect(s.adapterMac, isNull);
      expect(s.hasVisibleIndicator, isFalse);
    });

    test('markAttempting records adapter + switches state — '
        'indicator becomes visible even before the connect resolves',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(obd2ConnectionStatusProvider.notifier).markAttempting(
            adapterName: 'vLinker FS',
            adapterMac: 'A4:C1:38:00:00:01',
          );
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.attempting);
      expect(s.adapterName, 'vLinker FS');
      expect(s.hasVisibleIndicator, isTrue);
    });

    test('markUnreachable keeps the adapter label so the popover '
        'can still name the target', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markAttempting(
        adapterName: 'vLinker FS',
        adapterMac: 'AA:BB',
      );
      notifier.markUnreachable();
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.unreachable);
      expect(s.adapterName, 'vLinker FS');
    });

    test('markIdle clears everything — "forget adapter" flow', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markConnected(
        adapterName: 'vLinker FS',
        adapterMac: 'AA:BB',
      );
      expect(
        container.read(obd2ConnectionStatusProvider).hasVisibleIndicator,
        isTrue,
      );
      notifier.markIdle();
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.idle);
      expect(s.adapterName, isNull);
      expect(s.hasVisibleIndicator, isFalse);
    });

    test('attempting → connected preserves the adapter label', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markAttempting(
        adapterName: 'vLinker FS',
        adapterMac: 'AA:BB',
      );
      notifier.markConnected();
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.connected);
      expect(s.adapterName, 'vLinker FS');
      expect(s.adapterMac, 'AA:BB');
    });

    test('permissionDenied is its own terminal state with visible '
        'indicator so the user sees the system-settings CTA', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markAttempting(
        adapterName: 'vLinker FS',
        adapterMac: 'AA:BB',
      );
      notifier.markPermissionDenied();
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.permissionDenied);
      expect(s.hasVisibleIndicator, isTrue);
    });
  });
}
