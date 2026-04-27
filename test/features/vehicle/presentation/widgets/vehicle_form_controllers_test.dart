import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_form_controllers.dart';

void main() {
  group('VehicleFormControllers — defaults', () {
    test('text controllers start empty by default except seeded ones', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      expect(c.nameController.text, '');
      expect(c.batteryController.text, '');
      expect(c.maxChargingKwController.text, '');
      expect(c.tankController.text, '');
      expect(c.vinController.text, '');

      // #710 — preferred fuel pre-filled to e10.
      expect(c.fuelTypeController.text, 'e10');

      // Charging preferences defaults match domain defaults.
      expect(c.minSocController.text, '20');
      expect(c.maxSocController.text, '80');
    });
  });

  group('VehicleFormControllers.load', () {
    test('populates controllers from a fully-specified EV profile', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      const profile = VehicleProfile(
        id: 'ev-1',
        name: 'Model 3',
        type: VehicleType.ev,
        batteryKwh: 60.0,
        maxChargingKw: 150.0,
        supportedConnectors: {ConnectorType.ccs, ConnectorType.type2},
        chargingPreferences:
            ChargingPreferences(minSocPercent: 15, maxSocPercent: 85),
        preferredFuelType: null,
        vin: 'JTDKARFU0H3000001',
        obd2AdapterMac: 'AA:BB:CC:DD:EE:FF',
        obd2AdapterName: 'vLinker FS',
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: 1700,
      );

      final snap = c.load(profile);

      expect(c.nameController.text, 'Model 3');
      expect(c.batteryController.text, '60.0');
      expect(c.maxChargingKwController.text, '150.0');
      // Combustion fields cleared because profile has no values.
      expect(c.tankController.text, '');
      // null preferredFuelType -> empty string.
      expect(c.fuelTypeController.text, '');
      expect(c.minSocController.text, '15');
      expect(c.maxSocController.text, '85');
      expect(c.vinController.text, 'JTDKARFU0H3000001');

      // Snapshot mirrors non-controller fields.
      expect(snap.id, 'ev-1');
      expect(snap.type, VehicleType.ev);
      expect(snap.connectors, {ConnectorType.ccs, ConnectorType.type2});
      expect(snap.adapterMac, 'AA:BB:CC:DD:EE:FF');
      expect(snap.adapterName, 'vLinker FS');
      expect(snap.engineDisplacementCc, isNull);
      expect(snap.engineCylinders, isNull);
      expect(snap.curbWeightKg, 1700);
    });

    test('populates controllers from a combustion profile', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      const profile = VehicleProfile(
        id: 'ice-1',
        name: 'Peugeot 107',
        tankCapacityL: 35.0,
        preferredFuelType: 'e5',
        engineDisplacementCc: 998,
        engineCylinders: 3,
        curbWeightKg: 890,
      );

      final snap = c.load(profile);

      expect(c.nameController.text, 'Peugeot 107');
      expect(c.batteryController.text, '');
      expect(c.maxChargingKwController.text, '');
      expect(c.tankController.text, '35.0');
      expect(c.fuelTypeController.text, 'e5');
      expect(c.minSocController.text, '20');
      expect(c.maxSocController.text, '80');
      expect(c.vinController.text, '');

      expect(snap.id, 'ice-1');
      expect(snap.type, VehicleType.combustion);
      expect(snap.connectors, isEmpty);
      expect(snap.adapterMac, isNull);
      expect(snap.adapterName, isNull);
      expect(snap.engineDisplacementCc, 998);
      expect(snap.engineCylinders, 3);
      expect(snap.curbWeightKg, 890);
    });

    test('null fields on profile produce empty controller strings', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      // Bare-minimum profile — every nullable optional is null.
      const profile = VehicleProfile(id: 'bare', name: '');

      final snap = c.load(profile);

      expect(c.nameController.text, '');
      expect(c.batteryController.text, '');
      expect(c.maxChargingKwController.text, '');
      expect(c.tankController.text, '');
      expect(c.fuelTypeController.text, '');
      expect(c.vinController.text, '');
      // Domain ChargingPreferences default (20/80) populates SoC controllers.
      expect(c.minSocController.text, '20');
      expect(c.maxSocController.text, '80');

      expect(snap.id, 'bare');
      expect(snap.type, VehicleType.combustion);
      expect(snap.connectors, isEmpty);
      expect(snap.adapterMac, isNull);
      expect(snap.curbWeightKg, isNull);
    });

    test('connectors snapshot is a defensive copy', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      const profile = VehicleProfile(
        id: 'ev-2',
        name: 'Zoe',
        type: VehicleType.ev,
        supportedConnectors: {ConnectorType.type2},
      );

      final snap = c.load(profile);
      // Mutating the snapshot must not bleed back into the original profile.
      snap.connectors.add(ConnectorType.ccs);
      expect(profile.supportedConnectors, {ConnectorType.type2});
      expect(snap.connectors, {ConnectorType.type2, ConnectorType.ccs});
    });
  });

  group('VehicleFormControllers.buildProfile', () {
    test('round-trips combustion controllers into a VehicleProfile', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.nameController.text = '  Polo  '; // verify trim
      c.tankController.text = '45';
      c.fuelTypeController.text = 'e10';
      c.minSocController.text = '20';
      c.maxSocController.text = '80';
      c.vinController.text = 'WVWZZZ9NZ7Y000001';

      const existing = VehicleProfile(id: 'ice-7', name: 'old name');
      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.combustion,
        connectors: const {ConnectorType.ccs}, // ignored for combustion
        adapterMac: '11:22:33:44:55:66',
        adapterName: 'OBDLink LX',
        engineDisplacementCc: 1198,
        engineCylinders: 4,
        curbWeightKg: 1250,
      );

      expect(profile.id, 'ice-7');
      expect(profile.name, 'Polo');
      expect(profile.type, VehicleType.combustion);
      // Combustion → EV fields nulled out / connectors empty.
      expect(profile.batteryKwh, isNull);
      expect(profile.maxChargingKw, isNull);
      expect(profile.supportedConnectors, isEmpty);
      // Combustion fields preserved.
      expect(profile.tankCapacityL, 45.0);
      expect(profile.preferredFuelType, 'e10');
      expect(profile.chargingPreferences.minSocPercent, 20);
      expect(profile.chargingPreferences.maxSocPercent, 80);
      expect(profile.vin, 'WVWZZZ9NZ7Y000001');
      expect(profile.obd2AdapterMac, '11:22:33:44:55:66');
      expect(profile.obd2AdapterName, 'OBDLink LX');
      expect(profile.engineDisplacementCc, 1198);
      expect(profile.engineCylinders, 4);
      expect(profile.curbWeightKg, 1250);
    });

    test('round-trips EV controllers — combustion fields nulled out', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.nameController.text = 'Model Y';
      c.batteryController.text = '75';
      c.maxChargingKwController.text = '250';
      // Even if filled, combustion fields are dropped for VehicleType.ev.
      c.tankController.text = '50';
      c.fuelTypeController.text = 'e5';
      c.minSocController.text = '10';
      c.maxSocController.text = '90';

      const existing = VehicleProfile(id: 'ev-7', name: 'old');
      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.ev,
        connectors: const {ConnectorType.ccs, ConnectorType.type2},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      expect(profile.id, 'ev-7');
      expect(profile.name, 'Model Y');
      expect(profile.type, VehicleType.ev);
      expect(profile.batteryKwh, 75.0);
      expect(profile.maxChargingKw, 250.0);
      expect(profile.supportedConnectors,
          {ConnectorType.ccs, ConnectorType.type2});
      // EV: combustion fields are explicitly nulled in the builder.
      expect(profile.tankCapacityL, isNull);
      expect(profile.preferredFuelType, isNull);
      expect(profile.chargingPreferences.minSocPercent, 10);
      expect(profile.chargingPreferences.maxSocPercent, 90);
    });

    test('hybrid keeps both EV and combustion fields', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.nameController.text = 'Niro PHEV';
      c.batteryController.text = '11.1';
      c.maxChargingKwController.text = '7.2';
      c.tankController.text = '37';
      c.fuelTypeController.text = 'e10';
      c.minSocController.text = '20';
      c.maxSocController.text = '80';

      const existing = VehicleProfile(id: 'hyb-1', name: 'old');
      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.hybrid,
        connectors: const {ConnectorType.type2},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: 1580,
        engineCylinders: 4,
        curbWeightKg: 1500,
      );

      expect(profile.type, VehicleType.hybrid);
      expect(profile.batteryKwh, 11.1);
      expect(profile.maxChargingKw, 7.2);
      expect(profile.tankCapacityL, 37.0);
      expect(profile.preferredFuelType, 'e10');
      expect(profile.supportedConnectors, {ConnectorType.type2});
      expect(profile.engineDisplacementCc, 1580);
      expect(profile.engineCylinders, 4);
    });

    test('mints a new uuid when existing is null', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.nameController.text = 'New Car';

      final p1 = c.buildProfile(
        existing: null,
        type: VehicleType.combustion,
        connectors: const {},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );
      final p2 = c.buildProfile(
        existing: null,
        type: VehicleType.combustion,
        connectors: const {},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      expect(p1.id, isNotEmpty);
      expect(p2.id, isNotEmpty);
      expect(p1.id, isNot(p2.id), reason: 'each call generates a new uuid');
    });

    test('blank/whitespace text inputs collapse to nulls or zeros', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.nameController.text = '   ';
      c.batteryController.text = '';
      c.maxChargingKwController.text = '   ';
      c.tankController.text = '';
      c.fuelTypeController.text = '   '; // trim-empty -> null
      c.minSocController.text = ''; // -> fallback 20
      c.maxSocController.text = ''; // -> fallback 80
      c.vinController.text = '   ';

      const existing = VehicleProfile(id: 'edge-1', name: 'old');
      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.hybrid,
        connectors: const {},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      expect(profile.name, '');
      expect(profile.batteryKwh, isNull);
      expect(profile.maxChargingKw, isNull);
      expect(profile.tankCapacityL, isNull);
      expect(profile.preferredFuelType, isNull);
      expect(profile.vin, isNull);
      expect(profile.chargingPreferences.minSocPercent, 20);
      expect(profile.chargingPreferences.maxSocPercent, 80);
    });

    test('non-numeric numeric inputs parse to null (and zeros for SoC)', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.batteryController.text = 'huge';
      c.maxChargingKwController.text = 'fast';
      c.tankController.text = 'biggish';
      c.minSocController.text = 'low'; // -> fallback 20
      c.maxSocController.text = 'high'; // -> fallback 80

      const existing = VehicleProfile(id: 'edge-2', name: 'old');
      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.hybrid,
        connectors: const {},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      expect(profile.batteryKwh, isNull);
      expect(profile.maxChargingKw, isNull);
      expect(profile.tankCapacityL, isNull);
      expect(profile.chargingPreferences.minSocPercent, 20);
      expect(profile.chargingPreferences.maxSocPercent, 80);
    });

    test('comma decimals are parsed (European locale entry)', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.batteryController.text = '60,5';
      c.maxChargingKwController.text = '150,25';
      c.tankController.text = '45,5';

      const existing = VehicleProfile(id: 'edge-3', name: 'old');
      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.hybrid,
        connectors: const {},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      expect(profile.batteryKwh, 60.5);
      expect(profile.maxChargingKw, 150.25);
      expect(profile.tankCapacityL, 45.5);
    });

    test('preserves calibrationMode from existing via copyWith (#1217/#1226)',
        () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.nameController.text = 'Polo';

      const existing = VehicleProfile(
        id: 'fuzzy-2',
        name: 'old',
        calibrationMode: VehicleCalibrationMode.fuzzy,
      );
      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.combustion,
        connectors: const {},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      expect(profile.calibrationMode, VehicleCalibrationMode.fuzzy);
    });

    test('new-vehicle path defaults calibrationMode to rule', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.nameController.text = 'Polo';

      final profile = c.buildProfile(
        existing: null,
        type: VehicleType.combustion,
        connectors: const {},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      expect(profile.calibrationMode, VehicleCalibrationMode.rule);
    });

    test(
        'preserves all non-form fields verbatim via copyWith (#1226 root-cause '
        'class)', () {
      // Single fixture covering every non-form field on VehicleProfile that
      // the form does NOT manage. The earlier `buildProfile(...)` constructed
      // a fresh `VehicleProfile(...)` and silently fell back to the freezed
      // `@Default` for each — wiping these on every Save.
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.nameController.text = 'Polo'; // changing only name via the form.

      final existing = VehicleProfile(
        id: 'v1',
        name: 'old',
        calibrationMode: VehicleCalibrationMode.fuzzy,
        pairedAdapterMac: 'AA:BB:CC:DD:EE:FF',
        autoRecord: true,
        movementStartThresholdKmh: 7.5,
        disconnectSaveDelaySec: 90,
        backgroundLocationConsent: true,
        volumetricEfficiency: 0.92,
        volumetricEfficiencySamples: 120,
        referenceVehicleId: 'ref-vw-polo-2018',
        aggregatesTripCount: 17,
        aggregatesUpdatedAt: DateTime.utc(2026, 4, 1, 12),
      );

      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.combustion,
        connectors: const {},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      expect(profile.id, 'v1');
      expect(profile.name, 'Polo');
      // All non-form fields survive the round-trip.
      expect(profile.calibrationMode, VehicleCalibrationMode.fuzzy);
      expect(profile.pairedAdapterMac, 'AA:BB:CC:DD:EE:FF');
      expect(profile.autoRecord, isTrue);
      expect(profile.movementStartThresholdKmh, 7.5);
      expect(profile.disconnectSaveDelaySec, 90);
      expect(profile.backgroundLocationConsent, isTrue);
      expect(profile.volumetricEfficiency, 0.92);
      expect(profile.volumetricEfficiencySamples, 120);
      expect(profile.referenceVehicleId, 'ref-vw-polo-2018');
      expect(profile.aggregatesTripCount, 17);
      expect(profile.aggregatesUpdatedAt, DateTime.utc(2026, 4, 1, 12));
    });

    test('SoC values are clamped to 0..100', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      c.minSocController.text = '-50';
      c.maxSocController.text = '250';

      const existing = VehicleProfile(id: 'edge-4', name: 'old');
      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.ev,
        connectors: const {ConnectorType.type2},
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      expect(profile.chargingPreferences.minSocPercent, 0);
      expect(profile.chargingPreferences.maxSocPercent, 100);
    });

    test('connectors set passed in is defensively copied', () {
      final c = VehicleFormControllers();
      addTearDown(c.dispose);

      final inputConnectors = <ConnectorType>{ConnectorType.type2};

      const existing = VehicleProfile(id: 'ev-3', name: 'old');
      final profile = c.buildProfile(
        existing: existing,
        type: VehicleType.ev,
        connectors: inputConnectors,
        adapterMac: null,
        adapterName: null,
        engineDisplacementCc: null,
        engineCylinders: null,
        curbWeightKg: null,
      );

      // Mutating the original input doesn't change the profile's set.
      inputConnectors.add(ConnectorType.ccs);
      expect(profile.supportedConnectors, {ConnectorType.type2});
    });
  });

  group('VehicleFormControllers.dispose', () {
    test('does not throw when called once after construction', () {
      final c = VehicleFormControllers();
      expect(c.dispose, returnsNormally);
    });
  });

  group('VehicleFormSnapshot', () {
    test('exposes constructor-supplied fields verbatim', () {
      final snapshot = VehicleFormSnapshot(
        id: 'snap-1',
        type: VehicleType.hybrid,
        connectors: {ConnectorType.ccs},
        adapterMac: 'mac',
        adapterName: 'name',
        pairedAdapterMac: 'paired-mac',
        engineDisplacementCc: 1500,
        engineCylinders: 4,
        curbWeightKg: 1300,
      );

      expect(snapshot.id, 'snap-1');
      expect(snapshot.type, VehicleType.hybrid);
      expect(snapshot.connectors, {ConnectorType.ccs});
      expect(snapshot.adapterMac, 'mac');
      expect(snapshot.adapterName, 'name');
      expect(snapshot.pairedAdapterMac, 'paired-mac');
      expect(snapshot.engineDisplacementCc, 1500);
      expect(snapshot.engineCylinders, 4);
      expect(snapshot.curbWeightKg, 1300);
    });
  });
}
