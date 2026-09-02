// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3918 — `pumpGainByFuel` / `tankFuelKey` round-trip through the backup
// XML; both are omitted when empty so the committed golden is unchanged.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_xml_reader.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_xml_writer.dart';
import 'package:xml/xml.dart';

final _at = DateTime.utc(2026, 9, 1, 10);

void main() {
  test('per-fuel entries and the tank grade round-trip', () {
    final vehicle = VehicleProfile(
      id: 'v',
      name: 'Flex',
      multiFuelCapable: true,
      tankFuelKey: 'e85',
      pumpGain: 0.8,
      pumpGainSamples: 2,
      pumpGainByFuel: {
        'e85': PumpGainEntry(gain: 0.72, samples: 2, updatedAt: _at),
        'e10': const PumpGainEntry(gain: 0.9, samples: 1),
      },
    );
    final xml = BackupXmlWriter().build(
      vehicles: [vehicle],
      fillUps: const [],
      trips: const [],
      chargingLogs: const [],
      appVersion: '1.0.0',
      exportedAt: _at,
    );
    expect(xml, contains('<TankFuelKey>e85</TankFuelKey>'));
    expect(xml, contains('<PumpGainByFuel>'));
    expect(xml, contains('<Entry fuel="e10">'));
    final restored = const BackupXmlReader().read(xml).vehicles.single;
    expect(restored.tankFuelKey, 'e85');
    expect(restored.pumpGainByFuel['e85']!.gain, 0.72);
    expect(restored.pumpGainByFuel['e85']!.samples, 2);
    expect(restored.pumpGainByFuel['e85']!.updatedAt, _at);
    expect(restored.pumpGainByFuel['e10']!.gain, 0.9);
    expect(restored.pumpGainByFuel['e10']!.updatedAt, isNull);
    expect(restored.pumpGain, 0.8);
  });

  test('omitted when empty — the pre-#3918 shape is byte-identical', () {
    final xml = BackupXmlWriter().build(
      vehicles: const [VehicleProfile(id: 'v', name: 'x')],
      fillUps: const [],
      trips: const [],
      chargingLogs: const [],
      appVersion: '1.0.0',
      exportedAt: _at,
    );
    expect(xml, isNot(contains('PumpGainByFuel')));
    expect(xml, isNot(contains('TankFuelKey')));
    final restored = const BackupXmlReader().read(xml).vehicles.single;
    expect(restored.pumpGainByFuel, isEmpty);
    expect(restored.tankFuelKey, isNull);
  });

  test('a malformed entry is skipped, never fatal', () {
    final xml = BackupXmlWriter().build(
      vehicles: const [VehicleProfile(id: 'v', name: 'x')],
      fillUps: const [],
      trips: const [],
      chargingLogs: const [],
      appVersion: '1.0.0',
      exportedAt: _at,
    );
    final doc = XmlDocument.parse(xml);
    final vehicleEl = doc.findAllElements('Vehicle').single;
    vehicleEl.children.add(XmlDocument.parse(
      '<PumpGainByFuel>'
      '<Entry><Gain>0.7</Gain></Entry>'
      '<Entry fuel="e85"><Gain>oops</Gain></Entry>'
      '<Entry fuel="e10"><Gain>0.9</Gain></Entry>'
      '</PumpGainByFuel>',
    ).rootElement.copy());
    final restored =
        const BackupXmlReader().read(doc.toXmlString()).vehicles.single;
    expect(restored.pumpGainByFuel.keys, ['e10']);
    expect(restored.pumpGainByFuel['e10']!.samples, 0);
  });
}
