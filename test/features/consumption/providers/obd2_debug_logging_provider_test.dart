import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_debug_session.dart';
import 'package:tankstellen/features/consumption/providers/obd2_debug_logging_provider.dart';

import '../../../fakes/fake_hive_storage.dart';

/// Tests for [Obd2DebugSessionLogging] (#1925) — the opt-in OBD2
/// debug-logging flag. Its contract is that it both persists the
/// setting AND mirrors it onto [Obd2DebugSessionRecorder.enabled], so
/// reading it once at app start arms the static recorder.
void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage()..hasBundledDefaultKey = false;
    Obd2DebugSessionRecorder.reset();
    Obd2DebugSessionRecorder.enabled = false;
  });

  tearDown(() {
    Obd2DebugSessionRecorder.reset();
    Obd2DebugSessionRecorder.enabled = false;
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('build returns false and disarms the recorder when never set', () {
    final c = createContainer();
    expect(c.read(obd2DebugSessionLoggingProvider), isFalse);
    expect(Obd2DebugSessionRecorder.enabled, isFalse);
  });

  test('build reflects a stored true value and arms the recorder', () async {
    await fakeStorage.putSetting(
        StorageKeys.obd2DebugSessionLoggingEnabled, true);
    final c = createContainer();
    expect(c.read(obd2DebugSessionLoggingProvider), isTrue);
    // The recorder must be armed by `build` alone — this is what makes
    // reading the provider once at app start enough.
    expect(Obd2DebugSessionRecorder.enabled, isTrue);
  });

  test('set(true) persists, arms the recorder and updates state', () async {
    final c = createContainer();
    await c.read(obd2DebugSessionLoggingProvider.notifier).set(true);

    expect(
      fakeStorage.getSetting(StorageKeys.obd2DebugSessionLoggingEnabled),
      isTrue,
    );
    expect(c.read(obd2DebugSessionLoggingProvider), isTrue);
    expect(Obd2DebugSessionRecorder.enabled, isTrue);
  });

  test('set(false) persists and disarms the recorder', () async {
    await fakeStorage.putSetting(
        StorageKeys.obd2DebugSessionLoggingEnabled, true);
    final c = createContainer();
    // Reading the provider runs `build`, which arms the recorder.
    expect(c.read(obd2DebugSessionLoggingProvider), isTrue);
    expect(Obd2DebugSessionRecorder.enabled, isTrue);

    await c.read(obd2DebugSessionLoggingProvider.notifier).set(false);
    expect(
      fakeStorage.getSetting(StorageKeys.obd2DebugSessionLoggingEnabled),
      isFalse,
    );
    expect(Obd2DebugSessionRecorder.enabled, isFalse);
  });

  test('toggle flips the current value', () async {
    final c = createContainer();
    expect(c.read(obd2DebugSessionLoggingProvider), isFalse);
    await c.read(obd2DebugSessionLoggingProvider.notifier).toggle();
    expect(c.read(obd2DebugSessionLoggingProvider), isTrue);
    expect(Obd2DebugSessionRecorder.enabled, isTrue);
  });
}
