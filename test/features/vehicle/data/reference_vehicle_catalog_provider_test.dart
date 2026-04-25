import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/data/reference_vehicle_catalog_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';

/// Unit tests for the reference vehicle catalog provider (#950 phase 1).
///
/// The provider reads `assets/reference_vehicles/vehicles.json` via
/// `rootBundle`. In `flutter test`, the bundle is wired up to the
/// project's declared assets in `pubspec.yaml` — no fake bundle needed.
void main() {
  // Required so rootBundle can resolve declared assets in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('referenceVehicleCatalogProvider', () {
    test('loads at least 30 entries, all with non-empty make and model',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final catalog =
          await container.read(referenceVehicleCatalogProvider.future);

      expect(
        catalog.length,
        greaterThanOrEqualTo(30),
        reason: 'Catalog should ship the initial ~30 popular EU cars',
      );
      for (final v in catalog) {
        expect(v.make, isNotEmpty, reason: 'every entry needs a make');
        expect(v.model, isNotEmpty, reason: 'every entry needs a model');
        expect(v.generation, isNotEmpty);
        expect(v.yearStart, greaterThan(1900));
        expect(v.displacementCc, greaterThan(0));
        // Strategy must be one of the documented enum-as-string values.
        expect(
          const {'stdA6', 'psaUds', 'bmwCan', 'vwUds', 'unknown'}
              .contains(v.odometerPidStrategy),
          isTrue,
          reason:
              '${v.make} ${v.model} has unknown odometerPidStrategy '
              '"${v.odometerPidStrategy}"',
        );
        // VE should be a sensible fraction.
        expect(v.volumetricEfficiency, greaterThan(0.5));
        expect(v.volumetricEfficiency, lessThanOrEqualTo(1.0));
      }
    });

    test('shares the same list instance on repeated reads (keepAlive cache)',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first =
          await container.read(referenceVehicleCatalogProvider.future);
      final second =
          await container.read(referenceVehicleCatalogProvider.future);

      // Same list — proves the JSON wasn't re-decoded on the second
      // read.
      expect(identical(first, second), isTrue);
    });
  });

  group('referenceVehicleByMakeModelProvider', () {
    test('returns a non-null match for Peugeot 208 (2020)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Warm the catalog so the synchronous lookup can read it.
      await container.read(referenceVehicleCatalogProvider.future);

      final match = container.read(
        referenceVehicleByMakeModelProvider(
          make: 'Peugeot',
          model: '208',
          year: 2020,
        ),
      );

      expect(match, isNotNull);
      expect(match!.make, 'Peugeot');
      expect(match.model, '208');
      expect(match.coversYear(2020), isTrue);
    });

    test('lookup is case-insensitive on make and model', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(referenceVehicleCatalogProvider.future);

      final match = container.read(
        referenceVehicleByMakeModelProvider(
          make: 'peugeot',
          model: '208',
          year: 2020,
        ),
      );

      expect(match, isA<ReferenceVehicle>());
    });

    test('returns null for an unknown make/model', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(referenceVehicleCatalogProvider.future);

      final match = container.read(
        referenceVehicleByMakeModelProvider(
          make: 'FakeBrand',
          model: 'X',
          year: 2020,
        ),
      );

      expect(match, isNull);
    });

    test('returns null when the year falls outside the production window',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(referenceVehicleCatalogProvider.future);

      // Peugeot 208 II starts in 2019; 1990 is well before.
      final match = container.read(
        referenceVehicleByMakeModelProvider(
          make: 'Peugeot',
          model: '208',
          year: 1990,
        ),
      );

      expect(match, isNull);
    });

    test('returns null while catalog is still loading (no AsyncValue value)',
        () {
      // Brand-new container: no read of the catalog provider yet, so
      // `valueOrNull` is null and the helper short-circuits.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final match = container.read(
        referenceVehicleByMakeModelProvider(
          make: 'Peugeot',
          model: '208',
          year: 2020,
        ),
      );

      expect(match, isNull);
    });
  });
}
