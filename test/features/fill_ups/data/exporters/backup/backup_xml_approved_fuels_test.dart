// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4324 — `approvedFuelGrades` round-trips through the backup XML, is
// omitted when empty, and a pre-#4324 backup still restores (nothing
// declared, so the capability is derived exactly as before).
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_xml_reader.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_xml_writer.dart';

final _at = DateTime.utc(2026, 9, 16, 10);

String _backup(VehicleProfile v) => BackupXmlWriter().build(
      vehicles: [v],
      fillUps: const [],
      trips: const [],
      chargingLogs: const [],
      appVersion: '1.0.0',
      exportedAt: _at,
    );

void main() {
  test('declared grades round-trip in order', () {
    final xml = _backup(const VehicleProfile(
      id: 'v',
      name: 'Flex',
      preferredFuelType: 'e10',
      approvedFuelGrades: ['e5', 'e10', 'e98', 'e85'],
    ));
    expect(xml, contains('<ApprovedFuelGrades>'));
    expect(xml, contains('<Grade>e85</Grade>'));
    expect(const BackupXmlReader().read(xml).vehicles.single.approvedFuelGrades,
        ['e5', 'e10', 'e98', 'e85']);
  });

  test('omitted when empty, and an old backup without it restores empty',
      () {
    final xml = _backup(const VehicleProfile(id: 'v', name: 'x'));
    expect(xml, isNot(contains('ApprovedFuelGrades')));
    // The element simply does not exist in a pre-#4324 file — the same
    // document the writer produces for an undeclared profile.
    expect(const BackupXmlReader().read(xml).vehicles.single.approvedFuelGrades,
        isEmpty);
  });

  test('a blank grade entry is skipped, never fatal', () {
    final xml = _backup(const VehicleProfile(id: 'v', name: 'x')).replaceFirst(
        '<VolumetricEfficiency>',
        '<ApprovedFuelGrades><Grade> </Grade><Grade>e85</Grade>'
            '</ApprovedFuelGrades><VolumetricEfficiency>');
    final restored = const BackupXmlReader().read(xml).vehicles.single;
    expect(restored.approvedFuelGrades, ['e85']);
  });
}
