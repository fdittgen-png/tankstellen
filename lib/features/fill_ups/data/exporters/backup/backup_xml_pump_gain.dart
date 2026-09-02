// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:xml/xml.dart';

import '../../../../../core/domain/pump_gain_entry.dart';

/// #3918 — backup XML round-trip of `VehicleProfile.pumpGainByFuel` /
/// `tankFuelKey`, split out of the writer / reader (both at the #1680
/// file-length cap). Shape, under `<Vehicle>`:
///
/// ```xml
/// <TankFuelKey>e85</TankFuelKey>
/// <PumpGainByFuel>
///   <Entry fuel="e85"><Gain>0.72</Gain><Samples>2</Samples>
///     <UpdatedAt>2026-09-01T10:00:00.000Z</UpdatedAt></Entry>
/// </PumpGainByFuel>
/// ```
///
/// Both are OMITTED when empty / null so a profile without per-fuel
/// entries serialises byte-identically to the pre-#3918 golden.
const String kPumpGainByFuelElement = 'PumpGainByFuel';
const String kTankFuelKeyElement = 'TankFuelKey';

void writePumpGainByFuel(
  XmlBuilder builder,
  Map<String, PumpGainEntry> byFuel,
  String? tankFuelKey,
) {
  if (tankFuelKey != null && tankFuelKey.isNotEmpty) {
    builder.element(kTankFuelKeyElement, nest: tankFuelKey);
  }
  if (byFuel.isEmpty) return;
  builder.element(kPumpGainByFuelElement, nest: () {
    final keys = byFuel.keys.toList()..sort();
    for (final key in keys) {
      final e = byFuel[key]!;
      builder.element('Entry', nest: () {
        builder.attribute('fuel', key);
        builder.element('Gain', nest: e.gain.toString());
        builder.element('Samples', nest: e.samples.toString());
        final at = e.updatedAt;
        if (at != null) {
          builder.element('UpdatedAt', nest: at.toUtc().toIso8601String());
        }
      });
    }
  });
}

/// Missing element → empty map (pre-#3918 backups). A malformed entry
/// (no fuel / unparsable gain) is skipped, never fatal.
Map<String, PumpGainEntry> readPumpGainByFuel(XmlElement vehicle) {
  final box = vehicle.findElements(kPumpGainByFuelElement).firstOrNull;
  if (box == null) return const {};
  final out = <String, PumpGainEntry>{};
  for (final e in box.findElements('Entry')) {
    final fuel = e.getAttribute('fuel');
    final gain = double.tryParse(
        e.findElements('Gain').firstOrNull?.innerText.trim() ?? '');
    if (fuel == null || fuel.isEmpty || gain == null) continue;
    final samples = int.tryParse(
            e.findElements('Samples').firstOrNull?.innerText.trim() ?? '') ??
        0;
    final at = DateTime.tryParse(
        e.findElements('UpdatedAt').firstOrNull?.innerText.trim() ?? '');
    out[fuel] = PumpGainEntry(gain: gain, samples: samples, updatedAt: at);
  }
  return out;
}

String? readTankFuelKey(XmlElement vehicle) {
  final text = vehicle.findElements(kTankFuelKeyElement).firstOrNull?.innerText.trim();
  return (text == null || text.isEmpty) ? null : text;
}
