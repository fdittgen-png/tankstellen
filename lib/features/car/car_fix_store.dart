// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/data/storage_repository.dart';
import '../../core/domain/fuel_type.dart';
import '../../core/logging/error_logger.dart';
import '../../core/storage/storage_keys.dart';
import '../../core/utils/geo_utils.dart' show isUsableCoord;

/// Android Auto fix + profile storage helpers behind `CarDataService`
/// (extracted in #2990 to keep `car_data_service.dart` under the #1680 file
/// budget): reading the persisted last-known fix, parsing/persisting the LIVE
/// in-car fix the native `CarLocationSource` attaches to a fetch, and the
/// active-profile radius/fuel snapshot. Everything here is pure or
/// best-effort and never throws into the headless engine.

/// Sentinel the entry point returns (in place of a JSON list) when there is
/// no usable GPS fix — the native screen keeps its snapshot / shows the
/// `car_empty_no_gps` message rather than blanking. (Lives here, next to the
/// fix readers; re-exported by `car_data_service.dart`, the channel contract.)
// i18n-ignore: protocol sentinel, not user-facing text.
const String kNoGpsMarker = 'no_gps';

/// Parse the live in-car fix the native `CarLocationSource`/`CarDataBridge`
/// attaches to a fetch (#2990): a `{lat,lng,...}` map. Returns null — i.e.
/// the persisted-fix fallback — for absent / malformed args or a fix the
/// #2872 [isUsableCoord] guard rejects. Never throws.
({double lat, double lng})? carLiveFixFromArgs(Object? args) {
  if (args is! Map) return null;
  final rawLat = args['lat'];
  final rawLng = args['lng'];
  // `is!` (not a cast) so a hostile / corrupted payload degrades to the
  // fallback instead of throwing into the headless engine.
  if (rawLat is! num || rawLng is! num) return null;
  final lat = rawLat.toDouble();
  final lng = rawLng.toDouble();
  if (!isUsableCoord(lat, lng)) return null;
  return (lat: lat, lng: lng);
}

/// Read the persisted fix the same way the nearest-widget builder does, then
/// apply the #2872 [isUsableCoord] guard so a `(0,0)` / one-axis / NaN fix is
/// rejected (returns null → the caller emits the `no_gps` marker).
({double lat, double lng})? readPersistedCarFix(StorageRepository storage) {
  final lat =
      (storage.getSetting(StorageKeys.userPositionLat) as num?)?.toDouble();
  final lng =
      (storage.getSetting(StorageKeys.userPositionLng) as num?)?.toDouble();
  if (lat == null || lng == null) return null;
  if (!isUsableCoord(lat, lng)) return null;
  return (lat: lat, lng: lng);
}

/// Persist the live in-car fix as the new last-known position (#2990) —
/// the same keys `UserPositionNotifier._persist` writes, with source `car` —
/// so the persisted fallback (and everything else that reads it, e.g. the
/// nearest widget) stays fresh while driving.
/// Best-effort: a storage fault never fails the fetch.
Future<void> persistCarFix(
  StorageRepository storage,
  ({double lat, double lng}) fix,
) async {
  try {
    await storage.putSetting(StorageKeys.userPositionLat, fix.lat);
    await storage.putSetting(StorageKeys.userPositionLng, fix.lng);
    await storage.putSetting(
      StorageKeys.userPositionTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
    // i18n-ignore: position-source tag, not user-facing text.
    await storage.putSetting(StorageKeys.userPositionSource, 'car');
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
      'where': 'persistCarFix',
    }));
  }
}

/// The `{lat,lng,source,updatedAtMs}` location payload, or `{source:no_gps}`.
Map<String, dynamic> readCarUserLocation(StorageRepository storage) {
  final fix = readPersistedCarFix(storage);
  if (fix == null) return const {'source': kNoGpsMarker};
  return <String, dynamic>{
    'lat': fix.lat,
    'lng': fix.lng,
    'source': (storage.getSetting(StorageKeys.userPositionSource) as String?) ??
        'persisted',
    'updatedAtMs': _updatedAtMs(storage),
  };
}

int? _updatedAtMs(StorageRepository storage) {
  final raw = storage.getSetting(StorageKeys.userPositionTimestamp);
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.millisecondsSinceEpoch;
    return int.tryParse(raw);
  }
  return null;
}

/// Active-profile radius + fuel, mirroring the nearest-widget builder's
/// `_activeProfile` (default 10 km / E10 when no profile is set).
CarProfile activeCarProfile(StorageRepository storage) {
  final id = storage.getActiveProfileId();
  if (id == null) return const CarProfile();
  final raw = storage.getProfile(id);
  if (raw == null) return const CarProfile();
  final radius = (raw['defaultSearchRadius'] as num?)?.toDouble() ?? 10.0;
  FuelType fuel = FuelType.e10;
  final key = raw['preferredFuelType']?.toString();
  if (key != null) {
    try {
      fuel = FuelType.fromString(key);
    // #3164 — kept: preference validation; unknown fuel key falls back.
    } catch (e, st) { // ignore: unused_catch_stack
      debugPrint('activeCarProfile: unknown preferred fuel "$key": $e');
    }
  }
  return CarProfile(radiusKm: radius, fuelType: fuel);
}

/// Active-profile snapshot for one car fetch.
class CarProfile {
  final double radiusKm;
  final FuelType fuelType;
  const CarProfile({this.radiusKm = 10.0, this.fuelType = FuelType.e10});
}
