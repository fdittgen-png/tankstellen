// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/error/guarded.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';

/// Where a persisted odometer value came from (#3877).
enum VehicleOdometerSource {
  /// A PID reading (01A6 / 31 / manufacturer Mode 22) taken from the car.
  obd2,

  /// The last PID reading plus the GPS / OBD distance driven since it —
  /// what the recording knows at a stop that happened with the engine
  /// already off (the #3855 GPS-first tail), or minutes after the last
  /// periodic refresh.
  obd2Estimate,
}

/// The latest odometer the app has for one vehicle (#3877).
class VehicleOdometerSnapshot {
  const VehicleOdometerSnapshot({
    required this.km,
    required this.at,
    required this.source,
  });

  final double km;
  final DateTime at;
  final VehicleOdometerSource source;
}

/// The ONE accessor for the per-vehicle OBD2 odometer snapshot (#3877,
/// same one-accessor shape as the fuel-level snapshot store, #3592).
///
/// Storage: one settings-box entry per vehicle under
/// [StorageKeys.obd2OdometerSnapshotPrefix]`<vehicleId>` holding
/// `{"km": <double>, "at": <epochMillis>, "src": "obd2"|"obd2Estimate"}`.
/// Malformed or missing reads as null — the fill-up form then simply
/// leaves the odometer field empty, the honest degradation.
class VehicleOdometerSnapshotStore {
  VehicleOdometerSnapshotStore(this._settings);

  final SettingsStorage _settings;

  String _keyFor(String vehicleId) =>
      '${StorageKeys.obd2OdometerSnapshotPrefix}$vehicleId';

  /// Latest persisted odometer for [vehicleId], or null. Never throws.
  VehicleOdometerSnapshot? read(String vehicleId) {
    return guard(
      () {
        final raw = _settings.getSetting(_keyFor(vehicleId));
        if (raw is! String || raw.isEmpty) return null;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return null;
        final km = decoded['km'];
        final atMillis = decoded['at'];
        if (km is! num || atMillis is! int) return null;
        final value = km.toDouble();
        if (value < 0 || !value.isFinite) return null;
        return VehicleOdometerSnapshot(
          km: value,
          at: DateTime.fromMillisecondsSinceEpoch(atMillis),
          source: decoded['src'] == VehicleOdometerSource.obd2Estimate.name
              ? VehicleOdometerSource.obd2Estimate
              : VehicleOdometerSource.obd2,
        );
      },
      where: 'VehicleOdometerSnapshotStore.read($vehicleId)',
      layer: ErrorLayer.storage,
      fallback: null,
    );
  }

  /// Persist [snapshot] for [vehicleId]. Best-effort: a storage failure
  /// is traced, never thrown — the next reading overwrites anyway.
  Future<void> write(String vehicleId, VehicleOdometerSnapshot snapshot) {
    return guardAsync(
      () => _settings.putSetting(
        _keyFor(vehicleId),
        jsonEncode({
          'km': snapshot.km,
          'at': snapshot.at.millisecondsSinceEpoch,
          'src': snapshot.source.name,
        }),
      ),
      where: 'VehicleOdometerSnapshotStore.write($vehicleId)',
      layer: ErrorLayer.storage,
      fallback: null,
    );
  }
}

/// Plain provider so widget tests can `overrideWithValue` a store over a
/// fake settings storage.
final vehicleOdometerSnapshotStoreProvider =
    Provider<VehicleOdometerSnapshotStore>(
  (ref) => VehicleOdometerSnapshotStore(ref.watch(settingsStorageProvider)),
);
