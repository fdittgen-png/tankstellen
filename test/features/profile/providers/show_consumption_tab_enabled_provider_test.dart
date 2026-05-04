import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/providers/show_consumption_tab_enabled_provider.dart';

/// Provider-layer coverage for [showConsumptionTabEnabledProvider]
/// (#1373 phase 3c).
///
/// Distinct from the showFuel / showElectric shim tests because the
/// manifest declares [Feature.showConsumptionTab] as requiring
/// [Feature.obd2TripRecording]. Pre-seeded states therefore include
/// the prerequisite when toggling the dependent on, and the dependency-
/// violation path is exercised explicitly (set(true) without the
/// prerequisite must be a silent no-op via the shim's swallowed
/// StateError).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> flagsBox;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('show_consumption_tab_shim_');
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

  group('showConsumptionTabEnabledProvider — shim over featureFlagsProvider',
      () {
    test(
      'defaults to true on a fresh install (manifest default), even though '
      'the prerequisite obd2TripRecording is off — the shim surfaces the '
      'manifest default and the dependency-graph helpers gate the toggle '
      'in the UI separately',
      () async {
        final container = makeContainer();
        await pumpLoad(container);

        expect(
          container.read(showConsumptionTabEnabledProvider),
          isTrue,
          reason:
              'Manifest declares Feature.showConsumptionTab default'
              'Enabled=true. Even with the prerequisite obd2TripRecording '
              'off, the shim surfaces the manifest default — bottom-nav '
              'visibility logic should AND this with a separate '
              'obd2TripRecording check.',
        );
      },
    );

    test(
      'reads the central enabled-set on build — explicitly excluded → false',
      () async {
        await repo.saveEnabled(<Feature>{Feature.priceAlerts});

        final container = makeContainer();
        await pumpLoad(container);

        expect(
          container.read(showConsumptionTabEnabledProvider),
          isFalse,
          reason:
              'A persisted set without Feature.showConsumptionTab must '
              'surface as false. This is the post-migration shape for '
              'users whose legacy showConsumptionTab field was false '
              '(the common case).',
        );
      },
    );

    test(
      'set(true) with prerequisite enabled cascades only the dependent '
      '(prerequisite stays as-is)',
      () async {
        // Pre-seed with the prerequisite ON but the dependent OFF.
        await repo.saveEnabled(<Feature>{Feature.obd2TripRecording});

        final container = makeContainer();
        await pumpLoad(container);

        container.read(showConsumptionTabEnabledProvider);
        await container
            .read(showConsumptionTabEnabledProvider.notifier)
            .set(true);

        expect(
          container.read(featureFlagsProvider),
          contains(Feature.showConsumptionTab),
        );
        expect(
          container.read(featureFlagsProvider),
          contains(Feature.obd2TripRecording),
          reason:
              'The prerequisite must remain enabled — set(true) only '
              'enables the dependent, it does NOT touch unrelated state.',
        );
        expect(
          container.read(showConsumptionTabEnabledProvider),
          isTrue,
        );
      },
    );

    test(
      'set(true) WITHOUT prerequisite is a silent no-op (StateError '
      'swallowed) — toggle stays at prior false',
      () async {
        // Pre-seed an empty set to defeat the manifest-default mask:
        // without an explicit empty persisted state, the manifest default
        // would put showConsumptionTab=true, hiding the dependency-
        // violation path under the manifest fallback.
        await repo.saveEnabled(<Feature>{});

        final container = makeContainer();
        await pumpLoad(container);

        // Sanity: starting state is false.
        expect(container.read(showConsumptionTabEnabledProvider), isFalse);

        // No throw expected — the central provider raises StateError on
        // dependency-violation; the shim swallows.
        await container
            .read(showConsumptionTabEnabledProvider.notifier)
            .set(true);

        expect(
          container.read(showConsumptionTabEnabledProvider),
          isFalse,
          reason:
              'Dependency-violation is silent at the shim layer — the '
              'Phase 2 settings UI pre-checks canEnable, so reaching this '
              'path means a programmatic / test caller bypassed the guard. '
              'The shim swallows so the widget tree stays standing.',
        );
        expect(
          container.read(featureFlagsProvider),
          isNot(contains(Feature.showConsumptionTab)),
        );
      },
    );

    test('set(false) disables showConsumptionTab in the central provider',
        () async {
      // Seed with both prerequisite + dependent so we can flip dependent off.
      await repo.saveEnabled(<Feature>{
        Feature.obd2TripRecording,
        Feature.showConsumptionTab,
      });

      final container = makeContainer();
      await pumpLoad(container);

      container.read(showConsumptionTabEnabledProvider);
      await container
          .read(showConsumptionTabEnabledProvider.notifier)
          .set(false);

      expect(
        container.read(featureFlagsProvider),
        isNot(contains(Feature.showConsumptionTab)),
      );
      expect(
        container.read(featureFlagsProvider),
        contains(Feature.obd2TripRecording),
        reason:
            'set(false) on the dependent must NOT disturb the '
            'prerequisite — other features may still need it.',
      );
      expect(container.read(showConsumptionTabEnabledProvider), isFalse);
    });

    test('external mutation on featureFlagsProvider propagates', () async {
      final container = makeContainer();
      await pumpLoad(container);

      expect(container.read(showConsumptionTabEnabledProvider), isTrue);

      await container
          .read(featureFlagsProvider.notifier)
          .disable(Feature.showConsumptionTab);

      expect(container.read(showConsumptionTabEnabledProvider), isFalse);
    });
  });
}
