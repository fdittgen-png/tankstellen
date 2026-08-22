// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import '../../../../core/export/_csv_encoder.dart';
import '../trip_history_repository.dart';

/// Pure serializers for a single-trip telemetry download (#2652).
///
/// Mirrors the "pure function, returns String, no I/O, no Riverpod"
/// shape of the GPX writer ([buildGpxXml]) and the backup XML writer:
/// the screen-level handler in `trip_detail_downloads.dart` owns the
/// file save + snackbar; these functions only turn the in-memory
/// [TripHistoryEntry] into the export payload.
///
/// Two formats:
/// - CSV — the full OBD2 + GPS sample stream, one row per [TripSample],
///   for spreadsheet / pandas analysis.
/// - JSON — `entry.toJson()`, i.e. the exact persisted, re-importable
///   per-trip wire form (reuses [sampleToJson] via the repository).

/// Machine-stable CSV column identifiers — a data contract for external
/// tools (Excel, pandas), NOT user-facing UI text, so they are NOT
/// localized. One column per [TripSample] field, in the field's
/// declaration order so the schema stays single-sourced.
// i18n-ignore: CSV column identifiers, not UI text
const List<String> tripDetailCsvHeader = <String>[
  'timestamp_iso8601',
  'speed_kmh',
  'rpm',
  'fuel_rate_l_per_h',
  'est_fuel_rate_l_per_h',
  'throttle_pct',
  'engine_load_pct',
  'coolant_temp_c',
  'latitude',
  'longitude',
  'altitude_m',
  'h_accuracy_m',
  'bearing_deg',
  'accel_g',
  'lambda',
  'baro_kpa',
  'abs_load_pct',
  'pedal_pct',
  'oil_temp_c',
  'ambient_temp_c',
  'maf_g_per_s',
  'map_kpa',
  'stft_pct',
  'ltft_pct',
];

/// Serialise [entry]'s sample stream to an RFC 4180 CSV string (CRLF
/// line endings) via [encodeCsv]. The header row is
/// [tripDetailCsvHeader]; one data row follows per [TripSample]. The
/// timestamp is rendered as an ISO-8601 UTC instant; the remaining 23
/// numeric columns map the same fields in declaration order. Absent
/// signals (PIDs the car never exposed, GPS-less samples, etc.) carry
/// `null`, which [encodeCsv] renders as an empty cell — satisfying the
/// "include the value where present" contract without bespoke gating.
String buildTripDetailCsv(TripHistoryEntry entry) {
  final rows = <List<Object?>>[tripDetailCsvHeader];
  for (final s in entry.samples) {
    rows.add(<Object?>[
      s.timestamp.toUtc().toIso8601String(),
      s.speedKmh,
      s.rpm,
      s.fuelRateLPerHour,
      s.estimatedFuelRateLPerHour,
      s.throttlePercent,
      s.engineLoadPercent,
      s.coolantTempC,
      s.latitude,
      s.longitude,
      s.altitudeM,
      s.hAccuracyM,
      s.bearingDeg,
      s.accelG,
      s.lambda,
      s.baroKpa,
      s.absLoadPercent,
      s.pedalPercent,
      s.oilTempC,
      s.ambientTempC,
      s.mafGramsPerSecond,
      s.mapKpa,
      s.stft,
      s.ltft,
    ]);
  }
  return encodeCsv(rows);
}

/// Serialise [entry] to its persisted JSON wire form via
/// [TripHistoryEntry.toJson] (which reuses [sampleToJson] for each
/// sample). This is intentionally identical to what the trip history
/// box stores, so the downloaded file is round-trippable / re-importable
/// and there is a single source of truth for the trip shape.
String buildTripDetailJson(TripHistoryEntry entry) => jsonEncode(entry.toJson());
