// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/trip_recorder.dart';

/// (De)serialise a single [TripSample] for the trip-history rolling log.
///
/// Extracted from `trip_history_repository.dart` (#2431) so the
/// repository stays under the 400-line guard once the #2431 estimated
/// fuel-rate key (`'fe'`) joined the per-sample schema.
///
/// Compact key names ('t','s','r','f','fe','th','el','ct','la','lo',
/// 'al','ha','be','ag', + #2459 'lm','bp','aL','pp','ot','am', the
/// diagnostic-capture raw inputs 'mf','mp','sf','lf', + Epic #3416
/// 'mq' measured φ / 'ep' ethanol % / 'fs' fuel-source) keep per-trip JSON
/// small — a 39-min trip × 1 Hz lands around 19 KB compressed at this
/// density. The timestamp uses millisecondsSinceEpoch so the JSON parses
/// fast and round-trips precisely. Every optional key is emitted only
/// when its field is non-null, so trips written before each key landed
/// deserialise with the field null and a car that doesn't expose a PID
/// (or a trip with the diagnostic-capture flag off) adds zero bytes.
Map<String, dynamic> sampleToJson(TripSample s) => {
      't': s.timestamp.millisecondsSinceEpoch,
      's': s.speedKmh,
      // #2692 C4-G — 'r' omitted when rpm is null (GPS-only/degraded). OBD2
      // trips always carry a value, so they round-trip byte-identical; a
      // legacy trip's stored 'r' still reads back unchanged below.
      if (s.rpm != null) 'r': s.rpm,
      if (s.fuelRateLPerHour != null) 'f': s.fuelRateLPerHour,
      // #2431 — GPS-physics *estimated* fuel rate (L/h). A distinct key
      // from 'f' so a measured value and an estimate are never confused
      // on reload; only present for OBD2/hybrid trips whose adapter+ECU
      // supported no fuel PID (every 'f' omitted whole-trip).
      if (s.estimatedFuelRateLPerHour != null)
        'fe': s.estimatedFuelRateLPerHour,
      if (s.throttlePercent != null) 'th': s.throttlePercent,
      if (s.engineLoadPercent != null) 'el': s.engineLoadPercent,
      if (s.coolantTempC != null) 'ct': s.coolantTempC,
      if (s.latitude != null) 'la': s.latitude,
      if (s.longitude != null) 'lo': s.longitude,
      if (s.altitudeM != null) 'al': s.altitudeM,
      if (s.hAccuracyM != null) 'ha': s.hAccuracyM,
      if (s.bearingDeg != null) 'be': s.bearingDeg,
      if (s.accelG != null) 'ag': s.accelG,
      // #2459 — consumed-but-previously-unstored signals. Each guarded so
      // a car without the PID adds zero bytes.
      if (s.lambda != null) 'lm': s.lambda,
      // #3427 / #3429 / #3433 — measured wideband φ, ethanol % and the
      // per-tick fuel-source provenance. Same zero-bytes-when-absent rule.
      if (s.measuredPhi != null) 'mq': s.measuredPhi,
      if (s.ethanolPercent != null) 'ep': s.ethanolPercent,
      if (s.fuelSource != null) 'fs': s.fuelSource,
      if (s.baroKpa != null) 'bp': s.baroKpa,
      if (s.absLoadPercent != null) 'aL': s.absLoadPercent,
      if (s.pedalPercent != null) 'pp': s.pedalPercent,
      if (s.oilTempC != null) 'ot': s.oilTempC,
      if (s.ambientTempC != null) 'am': s.ambientTempC,
      // #2459 — diagnostic-capture raw mixture inputs. Present only when
      // the per-trip 'diagnostic capture' flag was on AND the car exposed
      // the PID; default-off trips and legacy trips carry none.
      if (s.mafGramsPerSecond != null) 'mf': s.mafGramsPerSecond,
      if (s.mapKpa != null) 'mp': s.mapKpa,
      if (s.stft != null) 'sf': s.stft,
      if (s.ltft != null) 'lf': s.ltft,
    };

TripSample sampleFromJson(Map<String, dynamic> j) => TripSample(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (j['t'] as num).toInt(),
      ),
      speedKmh: (j['s'] as num).toDouble(),
      // #2692 C4-G — nullable read: missing 'r' → null (GPS-only). Legacy
      // trips always stored 'r', so they deserialise to the same value.
      rpm: (j['r'] as num?)?.toDouble(),
      fuelRateLPerHour: (j['f'] as num?)?.toDouble(),
      // #2431 — missing 'fe' → null so legacy trips (and trips with a
      // real fuel signal, which never carry an estimate) round-trip clean.
      estimatedFuelRateLPerHour: (j['fe'] as num?)?.toDouble(),
      throttlePercent: (j['th'] as num?)?.toDouble(),
      engineLoadPercent: (j['el'] as num?)?.toDouble(),
      coolantTempC: (j['ct'] as num?)?.toDouble(),
      latitude: (j['la'] as num?)?.toDouble(),
      longitude: (j['lo'] as num?)?.toDouble(),
      altitudeM: (j['al'] as num?)?.toDouble(),
      hAccuracyM: (j['ha'] as num?)?.toDouble(),
      bearingDeg: (j['be'] as num?)?.toDouble(),
      accelG: (j['ag'] as num?)?.toDouble(),
      // #2459 — missing key → null so legacy trips and cars without the
      // PID deserialise cleanly.
      lambda: (j['lm'] as num?)?.toDouble(),
      // #3427 / #3429 / #3433 — missing key → null (legacy trips).
      measuredPhi: (j['mq'] as num?)?.toDouble(),
      ethanolPercent: (j['ep'] as num?)?.toDouble(),
      fuelSource: j['fs'] as String?,
      baroKpa: (j['bp'] as num?)?.toDouble(),
      absLoadPercent: (j['aL'] as num?)?.toDouble(),
      pedalPercent: (j['pp'] as num?)?.toDouble(),
      oilTempC: (j['ot'] as num?)?.toDouble(),
      ambientTempC: (j['am'] as num?)?.toDouble(),
      mafGramsPerSecond: (j['mf'] as num?)?.toDouble(),
      mapKpa: (j['mp'] as num?)?.toDouble(),
      stft: (j['sf'] as num?)?.toDouble(),
      ltft: (j['lf'] as num?)?.toDouble(),
    );
