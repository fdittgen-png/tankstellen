// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/error/guarded.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';

part 'obd2_fuel_level_snapshot_store.g.dart';

/// The last OBD2-read tank level for one vehicle (#3647).
///
/// Captured from the live source chain (PSA passive-CAN > OEM native
/// litres > PID `0x2F` percent × capacity) during a recording and
/// persisted so the tank card can show the sensor truth BETWEEN
/// drives — the tank-level-v2 model is "fill-ups anchor, the sensor
/// tracks", with no trip-consumption simulation in between.
@immutable
class Obd2FuelLevelSnapshot {
  /// Litres in the tank as the sensor chain reported them.
  final double liters;

  /// When the reading was taken. The estimator only honours a snapshot
  /// NEWER than the most recent fill-up — the fill has priority.
  final DateTime at;

  const Obd2FuelLevelSnapshot({required this.liters, required this.at});
}

/// The ONE accessor for the persisted per-vehicle OBD2 fuel-level
/// snapshot (#3592 one-accessor rule: every reader and writer of the
/// underlying settings key goes through this class).
///
/// Storage shape: one settings-box entry per vehicle under
/// [StorageKeys.obd2FuelLevelSnapshotPrefix]`<vehicleId>`, holding a
/// compact JSON `{"l": <litres>, "at": <epochMillis>}`. A malformed or
/// missing entry reads as null — the estimator then stays on the
/// fill-up anchor, which is the honest degradation.
class Obd2FuelLevelSnapshotStore {
  Obd2FuelLevelSnapshotStore(this._settings);

  final SettingsStorage _settings;

  String _keyFor(String vehicleId) =>
      '${StorageKeys.obd2FuelLevelSnapshotPrefix}$vehicleId';

  /// Latest persisted reading for [vehicleId], or null when never
  /// captured (no adapter, car without a fuel-level source) or
  /// unreadable. Never throws.
  Obd2FuelLevelSnapshot? read(String vehicleId) {
    return guard(
      () {
        final raw = _settings.getSetting(_keyFor(vehicleId));
        if (raw is! String || raw.isEmpty) return null;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return null;
        final liters = decoded['l'];
        final atMillis = decoded['at'];
        if (liters is! num || atMillis is! int) return null;
        final l = liters.toDouble();
        if (l < 0 || !l.isFinite) return null;
        return Obd2FuelLevelSnapshot(
          liters: l,
          at: DateTime.fromMillisecondsSinceEpoch(atMillis),
        );
      },
      where: 'Obd2FuelLevelSnapshotStore.read($vehicleId)',
      layer: ErrorLayer.storage,
      fallback: null,
    );
  }

  /// Persist [snapshot] as the latest reading for [vehicleId].
  /// Best-effort: a storage failure is traced, never thrown — the next
  /// reading overwrites anyway.
  Future<void> write(String vehicleId, Obd2FuelLevelSnapshot snapshot) {
    return guardAsync(
      () => _settings.putSetting(
        _keyFor(vehicleId),
        jsonEncode({
          'l': snapshot.liters,
          'at': snapshot.at.millisecondsSinceEpoch,
        }),
      ),
      where: 'Obd2FuelLevelSnapshotStore.write($vehicleId)',
      layer: ErrorLayer.storage,
      fallback: null,
    );
  }
}

/// App-wide store instance over the production storage repository.
@Riverpod(keepAlive: true)
Obd2FuelLevelSnapshotStore obd2FuelLevelSnapshotStore(Ref ref) =>
    Obd2FuelLevelSnapshotStore(ref.watch(storageRepositoryProvider));
