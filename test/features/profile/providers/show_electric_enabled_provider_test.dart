import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/providers/show_electric_enabled_provider.dart';

/// Provider-layer coverage for [showElectricEnabledProvider]
/// (#1373 phase 3c). Mirrors `show_fuel_enabled_provider_test.dart` —
/// same shape (no prerequisites, manifest default-true).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('show_electric_shim_');
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

  group('showElectricEnabledProvider — shim over featureFlagsProvider', () {
    test('defaults to true on a fresh install (manifest default)', () async {
      final container = makeContainer();
      await pumpLoad(container);

      expect(container.read(showElectricEnabledProvider), isTrue);
    });

    test('reads the central enabled-set on build', () async {
      await repo.saveEnabled(<Feature>{Feature.priceAlerts});

      final container = makeContainer();
      await pumpLoad(container);

      expect(
        container.read(showElectricEnabledProvider),
        isFalse,
        reason:
            'A persisted set without Feature.showElectric must surface '
            'as false; the central state is the single source of truth.',
      );
    });

    test('set(true) enables showElectric in the central provider', () async {
      await repo.saveEnabled(<Feature>{});

      final container = makeContainer();
      await pumpLoad(container);

      container.read(showElectricEnabledProvider);
      await container.read(showElectricEnabledProvider.notifier).set(true);

      expect(
        container.read(featureFlagsProvider),
        contains(Feature.showElectric),
      );
      expect(container.read(showElectricEnabledProvider), isTrue);
    });

    test('set(false) disables showElectric in the central provider',
        () async {
      final container = makeContainer();
      await pumpLoad(container);

      container.read(showElectricEnabledProvider);
      await container.read(showElectricEnabledProvider.notifier).set(false);

      expect(
        container.read(featureFlagsProvider),
        isNot(contains(Feature.showElectric)),
      );
      expect(container.read(showElectricEnabledProvider), isFalse);
    });

    test('external mutation on featureFlagsProvider propagates', () async {
      final container = makeContainer();
      await pumpLoad(container);

      expect(container.read(showElectricEnabledProvider), isTrue);

      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.showElectric);

      expect(container.read(showElectricEnabledProvider), isFalse);
    });
  });
}
