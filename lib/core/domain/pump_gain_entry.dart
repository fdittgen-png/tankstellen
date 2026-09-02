// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pump_gain_entry.freezed.dart';
part 'pump_gain_entry.g.dart';

/// One fuel grade's pump-anchored gain on a multi-fuel vehicle (#3918,
/// Epic #3914 — the per-fuel sibling of `VehicleProfile.pumpGain`).
///
/// A flex-fuel car alternating E85 / E10 needs a gain PER GRADE: the
/// ethanol AFR/density constants already differ, so the residual the
/// pump reveals differs too. The learner keys its update by the closing
/// fill's fuel key and keeps blending the scalar as the fallback for a
/// grade that has no entry yet. JSONB-stored inside the vehicle profile
/// (a field-add, TankSync-transparent — no Supabase change).
@freezed
abstract class PumpGainEntry with _$PumpGainEntry {
  const factory PumpGainEntry({
    @Default(1.0) double gain,
    @Default(0) int samples,
    DateTime? updatedAt,
  }) = _PumpGainEntry;

  factory PumpGainEntry.fromJson(Map<String, dynamic> json) =>
      _$PumpGainEntryFromJson(json);
}
