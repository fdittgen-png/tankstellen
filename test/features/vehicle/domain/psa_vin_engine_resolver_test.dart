import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/data/vin_decoder.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vin_data.dart';
import 'package:tankstellen/features/vehicle/domain/psa_vin_engine_resolver.dart';

/// Coverage for the offline PSA VIN engine-candidate resolver (#1864).
///
/// PSA VINs are decoded offline (`VinDecoder` with the network path
/// disabled — WMI make + position-10 model year). The resolver then
/// matches the decoded make + year against a reference catalog; it
/// never fabricates an engine.
void main() {
  final decoder = VinDecoder(allowOnlineLookup: false);

  // Structurally-valid 17-char VINs (no I/O/Q) with real PSA WMI
  // prefixes and a position-10 year code. Layout: WMI(3) · VDS(6) ·
  // year(1) · suffix(7). 'K' → 2019, 'L' → 2020, 'N' → 2022.
  const peugeotVin2019 = 'VF3AAAAAAKAAAAAAA'; // VF3 = Peugeot, France
  const citroenVin2020 = 'VF7AAAAAALAAAAAAA'; // VF7 = Citroën, France
  const opelVin2022 = 'W0LAAAAAANAAAAAAA'; // W0L = Opel, Germany

  ReferenceVehicle ref({
    required String make,
    required String model,
    required int yearStart,
    int? yearEnd,
    int displacementCc = 1200,
  }) =>
      ReferenceVehicle(
        make: make,
        model: model,
        generation: '$model ($yearStart-)',
        yearStart: yearStart,
        yearEnd: yearEnd,
        displacementCc: displacementCc,
        fuelType: 'petrol',
        transmission: 'manual',
      );

  final catalog = [
    ref(make: 'Peugeot', model: '208', yearStart: 2019), // current gen
    ref(make: 'Peugeot', model: '308', yearStart: 2013, yearEnd: 2021),
    ref(make: 'Peugeot', model: '207', yearStart: 2006, yearEnd: 2014),
    ref(make: 'Citroen', model: 'C3', yearStart: 2016),
    ref(make: 'Opel', model: 'Corsa', yearStart: 2019),
    ref(make: 'Renault', model: 'Clio', yearStart: 2019), // non-PSA
  ];

  group('isPsaVin', () {
    test('true for PSA-group makes', () async {
      expect(isPsaVin((await decoder.decode(peugeotVin2019))!), isTrue);
      expect(isPsaVin((await decoder.decode(citroenVin2020))!), isTrue);
      expect(isPsaVin((await decoder.decode(opelVin2022))!), isTrue);
    });

    test('false for a non-PSA make and for a make-less VinData', () {
      expect(
        isPsaVin(const VinData(
          vin: 'x',
          make: 'Renault',
          source: VinDataSource.wmiOffline,
        )),
        isFalse,
      );
      expect(
        isPsaVin(const VinData(vin: 'x', source: VinDataSource.invalid)),
        isFalse,
      );
    });
  });

  group('resolvePsaEngineCandidates', () {
    test('a Peugeot VIN resolves to Peugeot entries spanning the year',
        () async {
      final vinData = (await decoder.decode(peugeotVin2019))!;
      expect(vinData.make, 'Peugeot');
      expect(vinData.modelYear, 2019);

      final candidates =
          resolvePsaEngineCandidates(vinData: vinData, catalog: catalog);
      final models = candidates.map((c) => c.model).toSet();

      // 208 (2019-) and 308 (2013-2021) span 2019; 207 (2006-2014) does
      // not; nothing from another make.
      expect(models, {'208', '308'});
      expect(candidates.every((c) => c.make == 'Peugeot'), isTrue);
    });

    test('a Citroën VIN resolves only Citroën candidates', () async {
      final vinData = (await decoder.decode(citroenVin2020))!;
      final candidates =
          resolvePsaEngineCandidates(vinData: vinData, catalog: catalog);
      expect(candidates.map((c) => c.model), ['C3']);
    });

    test('an Opel VIN resolves only Opel candidates', () async {
      final vinData = (await decoder.decode(opelVin2022))!;
      final candidates =
          resolvePsaEngineCandidates(vinData: vinData, catalog: catalog);
      expect(candidates.map((c) => c.model), ['Corsa']);
    });

    test('a non-PSA VIN resolves nothing — no cross-make guessing', () {
      const renault = VinData(
        vin: 'VF1AAAAAAKAAAAAAA',
        make: 'Renault',
        modelYear: 2019,
        source: VinDataSource.wmiOffline,
      );
      expect(
        resolvePsaEngineCandidates(vinData: renault, catalog: catalog),
        isEmpty,
      );
    });

    test('the model year filters out non-overlapping generations', () {
      // A Peugeot VIN from 2010 must not match the 2019- 208.
      const old = VinData(
        vin: 'VF3AAAAAAAAAAAAAA',
        make: 'Peugeot',
        modelYear: 2010,
        source: VinDataSource.wmiOffline,
      );
      final models = resolvePsaEngineCandidates(vinData: old, catalog: catalog)
          .map((c) => c.model)
          .toSet();
      // 207 (2006-2014) spans 2010; 308 (2013-2021) and 208 (2019-)
      // do not.
      expect(models, {'207'});
    });

    test('an undecodable model year keeps every make match as a candidate',
        () {
      const noYear = VinData(
        vin: 'VF3AAAAAAAAAAAAAA',
        make: 'Peugeot',
        source: VinDataSource.wmiOffline,
      );
      final models =
          resolvePsaEngineCandidates(vinData: noYear, catalog: catalog)
              .map((c) => c.model)
              .toSet();
      expect(models, {'208', '308', '207'},
          reason: 'with no year to filter on, every Peugeot entry is a '
              'candidate the user can pick from');
    });
  });
}
