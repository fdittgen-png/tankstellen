// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'entities/reference_vehicle.dart';
import 'entities/vin_data.dart';

/// Offline PSA VIN engine-candidate resolver (#1864).
///
/// A PSA-group VIN (Peugeot / Citroën / DS / Opel / Vauxhall) encodes
/// the make in its WMI and the model year in position 10 — both
/// decodable offline by [VinDecoder]. The **engine**, however, sits in
/// the VDS (positions 4–9), whose make→engine mapping is PSA-internal
/// and not a publicly-sourceable dataset. Guessing it would surface
/// *wrong* engine data — worse than no answer — so this resolver does
/// not pretend to decode it.
///
/// Instead it resolves a **candidate set**: every entry in the
/// reference catalog whose make matches the VIN's decoded make and
/// whose generation spans the decoded model year. The UI can present
/// these for the user to confirm — an honest "one of these" rather
/// than a fabricated exact answer.

/// PSA-group brand names, lower-cased, as they appear in both the WMI
/// table and the reference catalog.
const Set<String> _psaBrands = {
  'peugeot',
  'citroen',
  'citroën',
  'ds',
  'ds automobiles',
  'opel',
  'vauxhall',
};

/// Whether [vinData] decoded to a PSA-group make.
bool isPsaVin(VinData vinData) {
  final make = vinData.make;
  return make != null && _psaBrands.contains(make.toLowerCase());
}

/// Resolve the reference-catalog engine candidates for a PSA VIN.
///
/// Returns every [catalog] entry whose make matches [vinData]'s
/// decoded make and whose `[yearStart, yearEnd]` generation window
/// spans [vinData]'s model year. When the model year could not be
/// decoded the year filter is dropped (every make match is a
/// candidate). Returns an empty list when [vinData] is not a PSA VIN
/// or nothing matches — never a fabricated engine.
List<ReferenceVehicle> resolvePsaEngineCandidates({
  required VinData vinData,
  required List<ReferenceVehicle> catalog,
}) {
  if (!isPsaVin(vinData)) return const [];
  final make = vinData.make!.toLowerCase();
  final year = vinData.modelYear;
  return [
    for (final v in catalog)
      if (v.make.toLowerCase() == make && _yearInGeneration(v, year)) v,
  ];
}

/// Whether [year] falls within [v]'s generation window. A null [year]
/// (position 10 undecodable) passes — the candidate is not excluded on
/// a year we don't know.
bool _yearInGeneration(ReferenceVehicle v, int? year) {
  if (year == null) return true;
  if (year < v.yearStart) return false;
  final end = v.yearEnd;
  return end == null || year <= end;
}
