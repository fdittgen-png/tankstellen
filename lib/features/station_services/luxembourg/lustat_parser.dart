// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Pure SDMX-JSON parsing for the LUSTAT *prix maxima* dataflows
/// (#3195 — split out of `LuxembourgStationService` so the JSON-shape
/// contract can be exercised with the recorded real fixtures
/// `test/fixtures/lu_lustat_{essence,diesel}_slice.json` without
/// touching Dio or any network state).
library;

import '../../../core/error/exceptions.dart';

/// One LUSTAT observation: the decreed EUR/L value plus its SDMX
/// `TIME_PERIOD` (the decree's effective date, ISO `yyyy-MM-dd`).
class LustatObservation {
  final double value;
  final String period;
  const LustatObservation({required this.value, required this.period});
}

/// Parse a LUSTAT SDMX-JSON payload (flat, `AllDimensions`) into the
/// latest observation per `MOTOR_ENERGY` id, merged into [into].
///
/// Throws [ApiException] when the payload is not the SDMX-JSON shape
/// (missing structures / dimensions / the two key dimensions).
Map<String, LustatObservation> parseLustatLatest(
  dynamic data, {
  Map<String, LustatObservation>? into,
}) {
  final out = into ?? <String, LustatObservation>{};

  final root = data is Map ? data['data'] : null;
  if (root is! Map) {
    throw const ApiException(
      message: 'LUSTAT returned unparseable body (no data envelope)',
      kind: FailureKind.parse,
    );
  }

  final structures = root['structures'];
  final dataSets = root['dataSets'];
  if (structures is! List ||
      structures.isEmpty ||
      dataSets is! List ||
      dataSets.isEmpty) {
    throw const ApiException(
      message: 'LUSTAT returned unparseable body (missing structures)',
      kind: FailureKind.parse,
    );
  }

  final structure = structures.first;
  final dims = structure is Map
      ? (structure['dimensions'] is Map
          ? (structure['dimensions'] as Map)['observation']
          : null)
      : null;
  if (dims is! List) {
    throw const ApiException(
      message: 'LUSTAT returned unparseable body (missing dimensions)',
      kind: FailureKind.parse,
    );
  }

  var motorPos = -1;
  var timePos = -1;
  for (var i = 0; i < dims.length; i++) {
    final d = dims[i];
    if (d is! Map) continue;
    if (d['id'] == 'MOTOR_ENERGY') motorPos = i;
    if (d['id'] == 'TIME_PERIOD') timePos = i;
  }
  if (motorPos < 0 || timePos < 0) {
    throw const ApiException(
      message:
          'LUSTAT returned unparseable body (no MOTOR_ENERGY/TIME_PERIOD)',
      kind: FailureKind.parse,
    );
  }

  final firstDataSet = dataSets.first;
  final observations =
      firstDataSet is Map ? firstDataSet['observations'] : null;
  if (observations is! Map) return out; // empty dataset — no decree rows

  String? dimValueId(int pos, int index) {
    final d = dims[pos];
    final values = d is Map ? d['values'] : null;
    if (values is! List || index < 0 || index >= values.length) return null;
    final v = values[index];
    return v is Map ? v['id']?.toString() : null;
  }

  for (final entry in observations.entries) {
    final indices = entry.key
        .toString()
        .split(':')
        .map((s) => int.tryParse(s))
        .toList(growable: false);
    if (indices.length != dims.length || indices.contains(null)) continue;

    final valueList = entry.value;
    final rawValue =
        valueList is List && valueList.isNotEmpty ? valueList.first : null;
    if (rawValue is! num || rawValue <= 0) continue;

    final motorId = dimValueId(motorPos, indices[motorPos]!);
    final period = dimValueId(timePos, indices[timePos]!);
    if (motorId == null || period == null) continue;

    final existing = out[motorId];
    if (existing == null || period.compareTo(existing.period) > 0) {
      out[motorId] =
          LustatObservation(value: rawValue.toDouble(), period: period);
    }
  }
  return out;
}
