// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/trip_recorder.dart';
import '../domain/imu_event_record.dart';

/// JSON codec for the persisted [TripSummary] (#726).
///
/// Extracted from `trip_history_repository.dart` (#2912 — keeps that file
/// under the 400-line guard) alongside the existing `trip_sample_codec.dart`.
/// Pure: every key uses the compact-key + omit-when-default parsimony rule so
/// each per-trip JSON payload stays tight, and every reader defaults a missing
/// key so legacy trips round-trip unchanged.
Map<String, dynamic> tripSummaryToJson(TripSummary s) => {
      'distanceKm': s.distanceKm,
      'maxRpm': s.maxRpm,
      'highRpmSeconds': s.highRpmSeconds,
      'idleSeconds': s.idleSeconds,
      'harshBrakes': s.harshBrakes,
      'harshAccelerations': s.harshAccelerations,
      if (s.avgLPer100Km != null) 'avgLPer100Km': s.avgLPer100Km,
      if (s.fuelLitersConsumed != null)
        'fuelLitersConsumed': s.fuelLitersConsumed,
      // #3576: GPS-physics estimate figures, stamped only when the
      // measured fields are null. Compact keys 'eAvg'/'eFuel'; omitted
      // when null so measured / legacy trips round-trip byte-identical.
      if (s.estimatedAvgLPer100Km != null) 'eAvg': s.estimatedAvgLPer100Km,
      if (s.estimatedFuelLitersConsumed != null)
        'eFuel': s.estimatedFuelLitersConsumed,
      if (s.startedAt != null) 'startedAt': s.startedAt!.toIso8601String(),
      if (s.endedAt != null) 'endedAt': s.endedAt!.toIso8601String(),
      // #800: provenance of distanceKm — `'real'` for odometer-backed
      // trips, `'virtual'` for speed-integrated estimates. Older trips
      // serialised before this field landed deserialise as `'virtual'`
      // to match the recorder's historical behaviour.
      'distanceSource': s.distanceSource,
      // #1262 phase 2: cold-start surcharge bit. Compact key 'cs'
      // because every trip carries this and we'd rather not pay six
      // bytes per record. Legacy trips without the key default false.
      'cs': s.coldStartSurcharge,
      // #1263 phase 2: seconds spent below the optimal gear (gear-
      // inference coaching metric). Compact key 'sblog' (Seconds
      // Below Low-Optimal Gear). Omitted when null — most trips on
      // pre-#1263 builds, EVs, and combustion trips with insufficient
      // gear-inference data carry no value, so parsimony saves bytes.
      if (s.secondsBelowOptimalGear != null)
        'sblog': s.secondsBelowOptimalGear,
      // #1858: η_v recompute provenance. Compact key 'veUsed'. Omitted
      // when null — legacy trips and non-recalculable trips (any PID 5E
      // / MAF fuel) carry no value, so parsimony saves bytes.
      if (s.volumetricEfficiencyUsed != null)
        'veUsed': s.volumetricEfficiencyUsed,
      // #2025 — trajet kind. Omitted when gpsPlusObd2 (the historical
      // default) so legacy trips round-trip with zero bytes added.
      if (s.kind != TripKind.gpsPlusObd2) 'kind': s.kind.wireName,
      // #2029: per-event harsh-brake / harsh-accel detail with
      // timestamp + magnitude + speed. Compact key 'he'. Omitted when
      // empty so legacy trips and event-free trips round-trip with
      // zero bytes added.
      if (s.harshEvents.isNotEmpty)
        'he': s.harshEvents.map((e) => e.toJson()).toList(growable: false),
      // #2444: synthetic reconciliation trajet flag. Compact key 'virt'.
      // Omitted when false (every real trip) so legacy trips round-trip
      // with zero bytes added.
      if (s.isVirtual) 'virt': true,
      // #2760: IMU-detected aggregate event counts for dongle-less (GPS+IMU)
      // trips — THREE scalars only (never the raw ~50 Hz stream). Compact keys
      // 'iha'/'ihb'/'sc'; each omitted when 0 so OBD2 / legacy trips add 0 bytes.
      if (s.imuHardAccelCount != 0) 'iha': s.imuHardAccelCount,
      if (s.imuHardBrakeCount != 0) 'ihb': s.imuHardBrakeCount,
      if (s.sharpCornerCount != 0) 'sc': s.sharpCornerCount,
      if (s.imuActive) 'ima': true, // #2895 IMU-ran bit (prefer IMU zero)
      // #3589 — per-stretch IMU calibration records + past-cap counter.
      if (s.imuEventRecords.isNotEmpty)
        'ier': [for (final r in s.imuEventRecords) r.toJson()],
      if (s.imuEventRecordsDropped != 0) 'ierd': s.imuEventRecordsDropped,
    };

TripSummary tripSummaryFromJson(Map<String, dynamic> j) => TripSummary(
      distanceKm: (j['distanceKm'] as num).toDouble(),
      maxRpm: (j['maxRpm'] as num).toDouble(),
      highRpmSeconds: (j['highRpmSeconds'] as num).toDouble(),
      idleSeconds: (j['idleSeconds'] as num).toDouble(),
      harshBrakes: (j['harshBrakes'] as num).toInt(),
      harshAccelerations: (j['harshAccelerations'] as num).toInt(),
      avgLPer100Km: (j['avgLPer100Km'] as num?)?.toDouble(),
      fuelLitersConsumed: (j['fuelLitersConsumed'] as num?)?.toDouble(),
      estimatedAvgLPer100Km: (j['eAvg'] as num?)?.toDouble(),
      estimatedFuelLitersConsumed: (j['eFuel'] as num?)?.toDouble(),
      startedAt: j['startedAt'] == null
          ? null
          : DateTime.parse(j['startedAt'] as String),
      endedAt: j['endedAt'] == null
          ? null
          : DateTime.parse(j['endedAt'] as String),
      // Default to 'virtual' for pre-#800 trips — that's the honest
      // label for legacy recordings, which integrated speed samples
      // regardless of whether an odometer was available.
      distanceSource: (j['distanceSource'] as String?) ?? 'virtual',
      // #1262 phase 2: pre-existing trips were persisted before the
      // cold-start surcharge heuristic landed; default false rather
      // than retroactively flag them.
      coldStartSurcharge: (j['cs'] as bool?) ?? false,
      // #1263 phase 2: gear-inference coaching metric. Legacy trips
      // (and EV / no-inference trips) carry no key → null.
      secondsBelowOptimalGear: (j['sblog'] as num?)?.toDouble(),
      // #1858: η_v recompute provenance. Legacy trips and trips whose
      // fuel was not 100% speed-density carry no key → null, which
      // correctly reads as "not recalculable".
      volumetricEfficiencyUsed: (j['veUsed'] as num?)?.toDouble(),
      // #2025: trajet kind. Missing key → gpsPlusObd2 because every
      // recording before this field landed required an OBD2 connection.
      kind: TripKind.fromWireName(j['kind'] as String?),
      // #2029: per-event harsh-brake / harsh-accel detail. Missing
      // key → empty list so legacy trips fall back to the bare
      // [harshBrakes] / [harshAccelerations] integer counters.
      harshEvents: (j['he'] as List?)
              ?.map((e) =>
                  HarshEvent.fromJson((e as Map).cast<String, dynamic>()))
              .toList(growable: false) ??
          const [],
      // #2444: synthetic reconciliation trajet flag. Missing key →
      // false so every real trip and every legacy trip deserialises
      // as a normal, fully-counted trajet.
      isVirtual: (j['virt'] as bool?) ?? false,
      // #2760: IMU aggregate event counts. Missing key → 0 for OBD2 trips
      // and every legacy trip recorded before IMU fusion landed.
      imuHardAccelCount: (j['iha'] as num?)?.toInt() ?? 0,
      imuHardBrakeCount: (j['ihb'] as num?)?.toInt() ?? 0,
      sharpCornerCount: (j['sc'] as num?)?.toInt() ?? 0,
      imuActive: (j['ima'] as bool?) ?? false, // #2895 IMU-ran bit
      imuEventRecords: [
        for (final e in (j['ier'] as List?) ?? const [])
          if (e is Map<String, dynamic>) ?ImuEventRecord.fromJson(e),
      ],
      imuEventRecordsDropped: (j['ierd'] as num?)?.toInt() ?? 0,
    );
