import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/features/sync/providers/sync_setup_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('starts at mode step, no mode selected', () {
    final c = makeContainer();
    final s = c.read(syncSetupControllerProvider);
    expect(s.step, SyncSetupStep.mode);
    expect(s.selectedMode, SyncMode.none);
    expect(s.isLoading, isFalse);
    expect(s.error, isNull);
    expect(s.showKey, isFalse);
  });

  test('selectMode(community) jumps straight to auth', () {
    final c = makeContainer();
    c.read(syncSetupControllerProvider.notifier).selectMode(SyncMode.community);
    final s = c.read(syncSetupControllerProvider);
    expect(s.step, SyncSetupStep.auth);
    expect(s.selectedMode, SyncMode.community);
  });

  test('selectMode(private) goes to credentials', () {
    final c = makeContainer();
    c.read(syncSetupControllerProvider.notifier).selectMode(SyncMode.private);
    expect(c.read(syncSetupControllerProvider).step, SyncSetupStep.credentials);
  });

  test('toggleKeyVisibility flips showKey', () {
    final c = makeContainer();
    final ctrl = c.read(syncSetupControllerProvider.notifier);
    ctrl.toggleKeyVisibility();
    expect(c.read(syncSetupControllerProvider).showKey, isTrue);
    ctrl.toggleKeyVisibility();
    expect(c.read(syncSetupControllerProvider).showKey, isFalse);
  });

  test('startLoading clears error and sets loading', () {
    final c = makeContainer();
    final ctrl = c.read(syncSetupControllerProvider.notifier);
    ctrl.setError('boom');
    expect(c.read(syncSetupControllerProvider).error, 'boom');
    ctrl.startLoading();
    final s = c.read(syncSetupControllerProvider);
    expect(s.isLoading, isTrue);
    expect(s.error, isNull);
  });

  test('setError stops loading and stores message', () {
    final c = makeContainer();
    final ctrl = c.read(syncSetupControllerProvider.notifier);
    ctrl.startLoading();
    ctrl.setError('nope');
    final s = c.read(syncSetupControllerProvider);
    expect(s.error, 'nope');
    expect(s.isLoading, isFalse);
  });
}
