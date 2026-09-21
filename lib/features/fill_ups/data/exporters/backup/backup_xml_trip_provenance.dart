// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:xml/xml.dart';

import '../../../../../core/domain/consumption_estimate.dart';
// Barrel import: the cross-feature boundary is crossed once, at
// `trips/api.dart`, exactly as the writer and reader do it.
import '../../../../trips/api.dart';
import 'backup_xml_element_helpers.dart';

/// #4330 — backup XML round-trip of a trip figure's PROVENANCE, split
/// out of the writer / reader (both at the #1680 file-length cap).
///
/// The Hive codec has persisted `pg` / `pgk` / `dfs` (#3887/#3918/#3919)
/// and `cmv` (#4233) for a while; the backup XML never wrote any of
/// them, so a backup/restore round-trip silently downgraded every trip:
/// the pump gain its litres carry, the branch that produced them and the
/// model version they came out of were all dropped, and the restored
/// trip re-classified as whatever the remaining fields implied. Shape,
/// under `<Trip><Summary>`:
///
/// ```xml
/// <PumpGainApplied>1.08</PumpGainApplied>
/// <PumpGainFuelKey>e85</PumpGainFuelKey>
/// <DominantFuelSource>maf</DominantFuelSource>
/// <ConsumptionVersion model="1" rules="1" calibration="4"/>
/// ```
///
/// Every element is OMITTED when its field is null, so a trip without
/// provenance serialises byte-identically to the pre-#4330 golden, and a
/// pre-#4330 backup restores exactly as it does today (every read is a
/// null-tolerant lookup).
const String kConsumptionVersionElement = 'ConsumptionVersion';

void writeTripProvenance(XmlBuilder builder, TripSummary s) {
  final gain = s.pumpGainApplied;
  if (gain != null) {
    builder.element('PumpGainApplied', nest: gain.toString());
  }
  final fuelKey = s.pumpGainFuelKey;
  if (fuelKey != null && fuelKey.isNotEmpty) {
    builder.element('PumpGainFuelKey', nest: fuelKey);
  }
  final dominant = s.dominantFuelSource;
  if (dominant != null && dominant.isNotEmpty) {
    builder.element('DominantFuelSource', nest: dominant);
  }
  final version = s.consumptionVersion;
  if (version != null) {
    builder.element(kConsumptionVersionElement, nest: () {
      builder.attribute('model', version.model.toString());
      builder.attribute('rules', version.rules.toString());
      final calibration = version.calibration;
      if (calibration != null) {
        builder.attribute('calibration', calibration.toString());
      }
    });
  }
}

/// The provenance of one `<Summary>`, or nulls for a pre-#4330 backup.
///
/// A malformed version element (missing / unparsable `model` or `rules`)
/// yields a null version rather than throwing: a restore must never fail
/// on a provenance field, which is metadata about the figure and not the
/// figure itself.
({
  double? pumpGainApplied,
  String? pumpGainFuelKey,
  String? dominantFuelSource,
  ConsumptionModelVersion? consumptionVersion,
}) readTripProvenance(XmlElement summaryEl) => (
      pumpGainApplied: readDouble(summaryEl, 'PumpGainApplied'),
      pumpGainFuelKey: readText(summaryEl, 'PumpGainFuelKey'),
      dominantFuelSource: readText(summaryEl, 'DominantFuelSource'),
      consumptionVersion: _readVersion(summaryEl),
    );

ConsumptionModelVersion? _readVersion(XmlElement summaryEl) {
  final el = summaryEl.findElements(kConsumptionVersionElement).firstOrNull;
  if (el == null) return null;
  final model = int.tryParse(el.getAttribute('model')?.trim() ?? '');
  final rules = int.tryParse(el.getAttribute('rules')?.trim() ?? '');
  if (model == null || rules == null || model < 1 || rules < 1) return null;
  return ConsumptionModelVersion(
    model: model,
    rules: rules,
    calibration: int.tryParse(el.getAttribute('calibration')?.trim() ?? ''),
  );
}
