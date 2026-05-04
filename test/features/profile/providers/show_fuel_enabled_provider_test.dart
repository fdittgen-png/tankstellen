import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/providers/show_fuel_enabled_provider.dart';

/// Provider-layer coverage for [showFuelEnabledProvider] (#1373 phase
/// 3c). Mirrors the gamification shim test:
///
///   1. Default state mirrors the manifest default (true).
///   2. set(true) routes through featureFlagsProvider.enable.
///   3. set(false) routes through featureFlagsProvider.disable.
///   4. External writes to featureFlagsProvider propagate.
///
/// The migration concerns (legacy `UserProfile.showFuel` → central
/// state promotion) are covered in
/// `test/features/feature_management/data/legacy_toggle_migrator_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('show_fuel_shim_');
    Hive.init(tmpDir.path);
    flagsBox = await Hive.openBox<dynamic>(
      'feature_flags_${DateTime.now().microsecondsSinceEpoch}',
    );
    repo = FeatureFlagsRepository(box: flagsBox);
  });

  tearDown(() async {
    await flagsBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer({List<Object> extraOverrides = const []}) {
    final c = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repo),
      ...extraOverrides.cast(),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> pumpLoad(ProviderContainer c) async {
    c.read(featureFlagsProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('showFuelEnabledProvider — shim over featureFlagsProvider', () {
    test('defaults to true on a fresh install (manifest default)', () async {
      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(showFuelEnabledProvider),
        isTrue,
        reason:
            'Manifest declares Feature.showFuel defaultEnabled=true; the '
            'shim must surface that default so existing fuel-station UI '
            'stays visible on fresh installs.',
      );
    });

    test('reads the central enabled-set on build', () async {
      // Pre-seed central state with showFuel removed.
      await repo.saveEnabled(<Feature>{Feature.priceAlerts});

      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(showFuelEnabledProvider),
        isFalse,
        reason:
            'A persisted central state without Feature.showFuel must '
            'surface as false, not the manifest default. The central '
            'feature-flag set is the single source of truth post-3c.',
      );
    });

    test('set(true) enables showFuel in the central provider', () async {
      // Pre-seed without showFuel so we can observe the enable.
      await repo.saveEnabled(<Feature>{});

      final container = makeContainer();
      await pumpLoad(container);

      container.read(showFuelEnabledProvider);
      await container.read(showFuelEnabledProvider.notifier).set(true);

      expect(
        container.read(featureFlagsProvider),
        contains(Feature.showFuel),
        reason:
            'set(true) must route through featureFlagsProvider.enable so '
            'the central state is the single source of truth — the legacy '
            'UserProfile.showFuel field is no longer the authoritative '
            'store.',
      );
      expect(container.read(showFuelEnabledProvider), isTrue);
    });

    test('set(false) disables showFuel in the central provider', () async {
      // Manifest default already includes showFuel. Use the provider to
      // disable so we exercise the shim end-to-end.
      final container = makeContainer();
      await pumpLoad(container);

      container.read(showFuelEnabledProvider);
      await container.read(showFuelEnabledProvider.notifier).set(false);

      expect(
        container.read(featureFlagsProvider),
        isNot(contains(Feature.showFuel)),
      );
      expect(container.read(showFuelEnabledProvider), isFalse);
    });

    test('external mutation on featureFlagsProvider propagates', () async {
      final container = makeContainer();
      await pumpLoad(container);

      // Sanity: starts true.
      expect(container.read(showFuelEnabledProvider), isTrue);

      // External disable.
      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.showFuel);

      expect(
        container.read(showFuelEnabledProvider),
        isFalse,
        reason:
            'External writes to featureFlagsProvider (settings UI, '
            'deep-link, another shim) must propagate through the '
            'showFuel shim because it watches the central state.',
      );
    });
  });
}
